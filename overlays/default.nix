# This file defines overlays
{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  # pkgs/default.nix takes pkgs positionally, not as {pkgs = ...;}
  additions = final: _prev: import ../pkgs final;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Per-package CUDA opt-ins (cudaSupport is not enabled globally — see nixos/nvidia.nix).
    blender = prev.blender.override { cudaSupport = true; };

    # Keep AI support enabled while using the channel's package expression.
    darktable = prev.darktable.override {
      withAi = true;
    };

    # Keep wxWidgets 3.3 while avoiding compositor-blocked EGL swaps.  Patch the
    # base through callPackage so the wrapper and all of its data paths use it.
    kicad = prev.kicad.override {
      callPackage = path: args:
        let package = prev.callPackage path args;
        in if (package.pname or "") == "kicad-base" then
          package.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ../patches/kicad-nonblocking-egl.patch ];
          })
        else package;
    };

    # SDCP support for the LighTuning ETU905A80-E reader (1C7A:05A5). Without
    # SDCP, prints are never persisted to device storage and verify fails with
    # "Print was not found on the devices storage".
    #
    # Applied as a patch on top of nixpkgs' libfprint rather than by overriding
    # `src`, so we keep the 1.94.100 base. The patch is the fork's 18 commits
    # rebased onto v1.94.100:
    #   git clone https://gitlab.freedesktop.org/libfprint/libfprint.git
    #   git remote add fork https://github.com/TenSeventy7/libfprint-egismoc-sdcp
    #   git fetch fork && git checkout -b sdcp <fork-rev> && git rebase v1.94.100
    #   git diff v1.94.100 sdcp -- . ':!tests/egismoc/custom.pcapng' \
    #     > patches/libfprint-egismoc-sdcp.patch
    # Regenerate on every fork update *and* every nixpkgs libfprint bump.
    # Rebase notes: preserve upstream's response-length validation, G_N_ELEMENTS
    # cleanup, new driver tests, and USB IDs while retaining the fork's SDCP
    # enrollment/identify/verify flow.
    # https://github.com/TenSeventy7/libfprint-egismoc-sdcp
    libfprint = prev.libfprint.overrideAttrs (old: {
      # Mark the fork in the store path via pname, not version: nixpkgs derives
      # the src rev from `v${finalAttrs.version}`, so overriding version would
      # silently point fetchFromGitLab at a nonexistent tag.
      pname = "${old.pname}-egismoc-sdcp";

      patches = (old.patches or [ ]) ++ [ ../patches/libfprint-egismoc-sdcp.patch ];

      # tests/egismoc/custom.pcapng is a binary umockdev fixture the SDCP work
      # re-recorded. GNU patch can't apply git binary diffs, so it is excluded
      # from the patch above and copied in here instead.
      postPatch = (old.postPatch or "") + ''
        cp ${
          prev.fetchurl {
            url = "https://raw.githubusercontent.com/TenSeventy7/libfprint-egismoc-sdcp/4d128d4f6f0b46182572126e84df88a73ac27859/tests/egismoc/custom.pcapng";
            hash = "sha256-6Fnud2PebDBryQnN722M4EkTKxN1aeaumTRd48ZaMTw=";
          }
        } tests/egismoc/custom.pcapng

        # 1C7A:05A5 is listed as known-unsupported in upstream's generated hwdb.
        # Move it to egismoc now that this patch implements the device; the
        # udev-hwdb install-check compares both generated sources exactly.
        substituteInPlace libfprint/fprint-list-udev-hwdb.c \
          --replace-fail "  { .vid = 0x1c7a, .pid = 0x05a5 }," ""
        substituteInPlace data/autosuspend.hwdb \
          --replace-fail $'usb:v1C7Ap05A5*\n' ""
        substituteInPlace data/autosuspend.hwdb \
          --replace-fail "usb:v1C7Ap05A1*" $'usb:v1C7Ap05A1*\nusb:v1C7Ap05A5*'
      '';
    });

    # Ghidra has no declarative knob for HiDPI scaling: support/launch.properties
    # (which pins VMARGS_LINUX=-Dsun.java2d.uiScale=1) lives read-only in the store.
    # ghidraRun appends $GHIDRA_JAVA_OPTIONS to the java command line *after* the
    # launch.properties args, and for -D the last one wins, so the env var is enough.
    #
    # Wrapped rather than overrideAttrs'd on purpose: ghidra is a multi-hour gradle
    # build, and touching its derivation would throw away the binary cache hit.
    #
    # uiScale scales the whole UI (fonts + icons + widgets). For fonts only, swap in
    # -Dfont.size.override=<absolute px>, which is a size not a multiplier.
    # NOTE: must NOT be named `ghidra`. ghidra's own derivation resolves
    # `ghidra-extensions` (and through it its gradle mitmCache) out of the *final*
    # package set, so overriding `pkgs.ghidra` feeds this wrapper's name back into
    # the inner build, renaming ghidra-deps -> ghidra-<wrapper>-deps and turning a
    # cache hit into a multi-hour gradle build from source.
    ghidra-scaled = prev.symlinkJoin {
      name = "ghidra-scaled-${prev.ghidra.version}";
      paths = [ prev.ghidra ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm $out/bin/ghidra
        makeWrapper ${prev.ghidra}/bin/ghidra $out/bin/ghidra \
          --set-default GHIDRA_JAVA_OPTIONS "-Dsun.java2d.uiScale=2"
      '';
      inherit (prev.ghidra) meta;
    };

    btop = prev.btop.overrideAttrs (old: {
      passthru = (old.passthru or { }) // {
        # `withoutGpu` is a new package variant of btop.
        withoutGpu = prev.btop.overrideAttrs (
          final: prev: {
            cmakeFlags = prev.cmakeFlags ++ [ "-DBTOP_GPU=OFF" ];
          }
        );
      };
    });

  };

  # Fix dolphin's empty "Open with" list outside KDE by refreshing ksycoca before launch.
  # Do NOT pass a menu file: kservice >= 6.28 dropped $out/etc/xdg/menus/applications.menu,
  # and handing kbuildsycoca6 a nonexistent menu makes it emit a sycoca with zero service
  # groups — exactly the empty application list. With no argument it discovers the menu
  # itself and the app tree is populated.
  dolphinFix = final: prev: {
    kdePackages = prev.kdePackages.overrideScope (
      kfinal: kprev: {
        dolphin = prev.symlinkJoin {
          name = "dolphin-wrapped";
          paths = [ kprev.dolphin ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            rm $out/bin/dolphin
            makeWrapper ${kprev.dolphin}/bin/dolphin $out/bin/dolphin \
              --run "${kprev.kservice}/bin/kbuildsycoca6 --noincremental >/dev/null 2>&1 || true"
          '';
        };
      }
    );
  };

  # Keep Hyprland's pinned packages and the standalone GUI-utils dependency graph.
  hyprland =
    final: _prev:
    let
      upstream = inputs.hyprland.packages.${final.stdenv.hostPlatform.system};
      guiutils =
        inputs.hyprland.inputs.hyprland-guiutils.packages.${final.stdenv.hostPlatform.system}.default;
    in
    {
      hyprland = upstream.hyprland.override { hyprland-guiutils = guiutils; };
      hyprland-guiutils = guiutils;
      xdg-desktop-portal-hyprland = upstream.xdg-desktop-portal-hyprland;
    };
}

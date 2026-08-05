# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  # pkgs/default.nix takes pkgs positionally, not as {pkgs = ...;}
  additions = final: _prev: import ../pkgs final;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Per-package CUDA opt-ins (cudaSupport is not enabled globally — see nixos/nvidia.nix).
    blender = prev.blender.override { cudaSupport = true; };

    # darktable 5.6.0 with AI features (nixpkgs#534312), not yet in our nixpkgs
    # channel. callPackage the pinned expression against `final` so only
    # darktable rebuilds — all deps (incl. onnxruntime for withAi) resolve from
    # our existing nixpkgs pin, keeping cache hits and disk use down.
    # Drop this once nixos-unstable ships darktable >= 5.6.
    darktable = final.callPackage "${inputs.nixpkgs-darktable}/pkgs/by-name/da/darktable/package.nix" {
      withAi = true;
    };

    # openldap test017-syncreplication-refresh is flaky; upstream issue:
    # https://github.com/NixOS/nixpkgs/issues/514113
    # Retry dropping this when Hydra shows green for openldap on the pinned nixpkgs commit:
    # https://hydra.nixos.org/job/nixpkgs/trunk/openldap.x86_64-linux
    openldap = prev.openldap.overrideAttrs (old: {
      doCheck = false;
    });

    # nixpkgs pins app2unit 1.4.2, whose app2unit.1.scd has nested inline
    # formatting that scdoc >= 1.11.5 rejects:
    #   Error at 70:17: Cannot nest inline formatting (began with _ at 69:43)
    # Upstream fixed the manpage in 1.4.3 ("docs: fix manpage syntax for newer
    # scdoc, fixes #18"). Bump to 1.4.4; drop once nixpkgs catches up.
    app2unit = prev.app2unit.overrideAttrs (_old: {
      version = "1.4.4";
      src = prev.fetchFromGitHub {
        owner = "Vladimir-csp";
        repo = "app2unit";
        tag = "v1.4.4";
        hash = "sha256-TIY+/9ekGub+10uyqXy5aYU+2NLysMtaQnD1PIjBCFA=";
      };
    });

    # SDCP support for the LighTuning ETU905A80-E reader (1C7A:05A5). Without
    # SDCP, prints are never persisted to device storage and verify fails with
    # "Print was not found on the devices storage".
    #
    # Applied as a patch on top of nixpkgs' libfprint rather than by overriding
    # `src`, so we keep the 1.94.10 base and all of nixpkgs' backported USB-ID
    # patches. The patch is the fork's 18 commits rebased onto v1.94.10:
    #   git clone https://gitlab.freedesktop.org/libfprint/libfprint.git
    #   git remote add fork https://github.com/TenSeventy7/libfprint-egismoc-sdcp
    #   git fetch fork && git checkout -b sdcp <fork-rev> && git rebase v1.94.10
    #   git diff v1.94.10 sdcp -- . ':!tests/egismoc/custom.pcapng' \
    #     > patches/libfprint-egismoc-sdcp.patch
    # Regenerate on every fork update *and* every nixpkgs libfprint bump.
    # Rebase notes: two fork commits (1c7a:0584 support) are already in 1.94.10
    # and drop out; the only conflict is egismoc_id_table, resolved as the union
    # (fork's MAX_ENROLL_STAGES_15 on 0583, upstream's 0584/0588 kept).
    # https://github.com/TenSeventy7/libfprint-egismoc-sdcp
    libfprint = prev.libfprint.overrideAttrs (old: {
      # Mark the fork in the store path via pname, not version: nixpkgs derives
      # the src rev from `v${finalAttrs.version}`, so overriding version would
      # silently point fetchFromGitLab at a nonexistent tag.
      pname = "${old.pname}-egismoc-sdcp";

      patches = (old.patches or []) ++ [ ../patches/libfprint-egismoc-sdcp.patch ];

      # tests/egismoc/custom.pcapng is a binary umockdev fixture the SDCP work
      # re-recorded. GNU patch can't apply git binary diffs, so it is excluded
      # from the patch above and copied in here instead.
      postPatch = (old.postPatch or "") + ''
        cp ${prev.fetchurl {
          url = "https://raw.githubusercontent.com/TenSeventy7/libfprint-egismoc-sdcp/4d128d4f6f0b46182572126e84df88a73ac27859/tests/egismoc/custom.pcapng";
          hash = "sha256-6Fnud2PebDBryQnN722M4EkTKxN1aeaumTRd48ZaMTw=";
        }} tests/egismoc/custom.pcapng

        # The fork adds 1C7A:05A5 to the egismoc driver without regenerating
        # data/autosuspend.hwdb, which the udev-hwdb install-check diffs exactly.
        substituteInPlace data/autosuspend.hwdb \
          --replace-fail "usb:v1C7Ap05A1*" $'usb:v1C7Ap05A1*\nusb:v1C7Ap05A5*'
      '';
    });

    # nixpkgs ships openfreebuds; override only the source to track an open PR
    # adding HUAWEI FreeBuds Pro 5 support, not yet merged upstream.
    # https://github.com/Sherzod-Norkulov/OpenFreebuds/tree/pr/freebuds-pro-5
    # ^ above got deleted, now using: https://github.com/melianmiko/OpenFreebuds/pull/116
    openfreebuds = prev.openfreebuds.overrideAttrs (_old: {
      version = "0.17.3-unstable-2026-05-31";
      src = prev.fetchFromGitHub {
        owner = "JehuAlv";
        repo = "OpenFreebuds";
        rev = "9bc5e90d198dc2c261c75e4be2ce3fe5a9f31244";
        hash = "sha256-jzg/pgaHbf8J7GM711ZX4VhcygpkXLyWK0J3oOqIB0s=";
      };
    });

    btop = prev.btop.overrideAttrs (old: {
      passthru = (old.passthru or {}) // {
        # `withoutGpu` is a new package variant of btop.
        withoutGpu = prev.btop.overrideAttrs (final: prev: {
          cmakeFlags = prev.cmakeFlags ++ [ "-DBTOP_GPU=OFF" ];
        });
      };
    });

    linuxSamsung = prev.linuxPackagesFor (prev.linuxPackages_latest.kernel.override {
      structuredExtraConfig = with prev.lib.kernel; {
        SAMSUNG_GALAXYBOOK = module;

        # following are dependencies of SAMSUNG_GALAXYBOOK
        # ACPI = yes;
        # ACPI_BATTERY = yes;
        # INPUT = yes;
        # LEDS_CLASS = yes;
        # SERIO_I8042 = yes;
      };

      ignoreConfigErrors = true;
    });

    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (python-final: python-prev: {
        pyqtgraph = python-prev.pyqtgraph.overridePythonAttrs (_: {
          doCheck = false;
        });

        # tests/test_qthreadexec.py stale-reference tests depend on CPython GC
        # timing and fail on python 3.14 ("Stale reference to executor result
        # not collected within timeout"). Skip just those two — doCheck = false
        # would also drop nativeCheckInputs, breaking pythonImportsCheck
        # ("No Qt implementations found").
        qasync = python-prev.qasync.overridePythonAttrs (old: {
          disabledTests = (old.disabledTests or []) ++ [
            "test_no_stale_reference_as_argument"
            "test_no_stale_reference_as_result"
          ];
        });

        # Workaround for bug #437058
        i3ipc = python-prev.i3ipc.overridePythonAttrs (oldAttrs: {
          doCheck = false;
          checkPhase = ''
            echo "Skipping pytest in Nix build"
          '';
          installCheckPhase = ''
            echo "Skipping install checks in Nix build"
          '';
        });

        psycopg = python-prev.psycopg.overridePythonAttrs (oldAttrs: {
          doCheck = false;

          propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or [])
            ++ [ python-prev.psycopg-pool ];

          pythonImportsCheck = [
            "psycopg"
            "psycopg_pool"
          ];
        });

        pytest-postgresql = python-prev.pytest-postgresql.overridePythonAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];
  };

  # Fix dolphin's empty "Open with" list outside KDE by refreshing ksycoca before launch.
  # Do NOT pass a menu file: kservice >= 6.28 dropped $out/etc/xdg/menus/applications.menu,
  # and handing kbuildsycoca6 a nonexistent menu makes it emit a sycoca with zero service
  # groups — exactly the empty application list. With no argument it discovers the menu
  # itself and the app tree is populated.
  dolphinFix = final: prev: {
    kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
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
    });
  };

  # hyprexpo-plus — fork of hyprexpo after it was dropped from hyprland-plugins.
  # Upstream renamed the repo sandwichfarm/hyprexpo-plus -> sandwichfarm/hyprexpo
  # and tracks Hyprland releases in its VERSION file, so bump this together with
  # the hyprland flake input. pluginName must match the CMake target
  # (add_library(hyprexpo ...)) because home-manager loads
  # ${plugin}/lib/lib${pname}.so.
  hyprexpoPlus = final: prev: {
    hyprexpo-plus =
      let
        hyprlandPkg = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
      in
      prev.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hyprexpo";
        version = "0.56.1-unstable-2026-08-03";
        src = prev.fetchFromGitHub {
          owner = "sandwichfarm";
          repo = "hyprexpo";
          rev = "53f391fa14db776bb65c39361a344d18528539ae";
          hash = "sha256-p9lPjSDkcZf+FKrvnQliDmutt++zB/DdrQXyALN/6s0=";
        };
        hyprland = hyprlandPkg;
        # same set upstream's default.nix uses (cmake, pkg-config, scanners)
        inherit (hyprlandPkg) nativeBuildInputs;
        meta = with prev.lib; {
          homepage = "https://github.com/sandwichfarm/hyprexpo";
          description = "Enhanced Hyprland workspaces overview plugin (fork of hyprexpo)";
          license = licenses.bsd3;
          platforms = platforms.linux;
        };
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}

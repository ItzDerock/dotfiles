# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Per-package CUDA opt-ins (cudaSupport is not enabled globally — see nixos/nvidia.nix).
    blender = prev.blender.override { cudaSupport = true; };

    # openldap test017-syncreplication-refresh is flaky; upstream issue:
    # https://github.com/NixOS/nixpkgs/issues/514113
    # Retry dropping this when Hydra shows green for openldap on the pinned nixpkgs commit:
    # https://hydra.nixos.org/job/nixpkgs/trunk/openldap.x86_64-linux
    openldap = prev.openldap.overrideAttrs (old: {
      doCheck = false;
    });

    app2unit = prev.app2unit.overrideAttrs (oldAttrs: rec {
      version = "1.0.2";
      src = oldAttrs.src.override {
        inherit version;
        sha256 = "as";
      };
    });

    # Fork with SDCP support for the LighTuning ETU905A80-E reader.
    # Without SDCP, prints are never persisted to device storage and verify
    # fails with "Print was not found on the devices storage".
    # https://github.com/TenSeventy7/libfprint-egismoc-sdcp
    libfprint = prev.libfprint.overrideAttrs (_old: {
      version = "1.94.9-egismoc-sdcp-unstable-2025-07-29";
      src = prev.fetchFromGitHub {
        owner = "TenSeventy7";
        repo = "libfprint-egismoc-sdcp";
        rev = "4d128d4f6f0b46182572126e84df88a73ac27859";
        hash = "sha256-ij+g5iuWJqMNTDvqTTYWB9BD3Zi+1PzG075rcFULC4w=";
      };
      # Fork is based on a pre-1.94.10 tree that has no tests/test-runner.sh.
      # It also added device id 1C7A:05A5 to the egismoc driver without
      # regenerating data/autosuspend.hwdb, so the udev-hwdb install-check
      # would fail; sync the hwdb here.
      postPatch = ''
        patchShebangs \
          tests/unittest_inspector.py \
          tests/virtual-image.py \
          tests/umockdev-test.py \
          tests/test-generated-hwdb.sh

        substituteInPlace data/autosuspend.hwdb \
          --replace-fail "usb:v1C7Ap05A1*" $'usb:v1C7Ap05A1*\nusb:v1C7Ap05A5*'
      '';
    });

    # nixpkgs ships openfreebuds; override only the source to track an open PR
    # adding HUAWEI FreeBuds Pro 5 support, not yet merged upstream.
    # https://github.com/Sherzod-Norkulov/OpenFreebuds/tree/pr/freebuds-pro-5
    openfreebuds = prev.openfreebuds.overrideAttrs (_old: {
      version = "0.17.3-unstable-2026-05-31";
      src = prev.fetchFromGitHub {
        owner = "Sherzod-Norkulov";
        repo = "OpenFreebuds";
        rev = "56e5f21b83e5b36c9d63c4189f9abcafe7664e00";
        hash = "sha256-FMH+mvHenXXAvYWeolDECGC8WO0Tlsfh8r2+lB3ZrB8=";
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

  # Fix dolphin "Open with" menu outside KDE — upstream overlay used libsForQt5.kservice which was removed
  dolphinFix = final: prev: {
    kdePackages = prev.kdePackages.overrideScope (kfinal: kprev: {
      dolphin = prev.symlinkJoin {
        name = "dolphin-wrapped";
        paths = [ kprev.dolphin ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          rm $out/bin/dolphin
          makeWrapper ${kprev.dolphin}/bin/dolphin $out/bin/dolphin \
            --set XDG_CONFIG_DIRS "${prev.kdePackages.kservice}/etc/xdg:$XDG_CONFIG_DIRS" \
            --run "${kprev.kservice}/bin/kbuildsycoca6 --noincremental ${prev.kdePackages.kservice}/etc/xdg/menus/applications.menu"
        '';
      };
    });
  };

  # hyprexpo-plus — fork of hyprexpo after it was dropped from hyprland-plugins
  hyprexpoPlus = final: prev: {
    hyprexpo-plus =
      let
        hyprlandPkg = inputs.hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
      in
      prev.hyprlandPlugins.mkHyprlandPlugin {
        pluginName = "hyprexpo-plus";
        version = "0-unstable-2025-05-14";
        src = prev.fetchFromGitHub {
          owner = "sandwichfarm";
          repo = "hyprexpo-plus";
          rev = "60a7f3541ff0cf03313368b61d53aecda783b70b";
          hash = "sha256-KmwRoizMS83b6+RPWANBqIDSkBiZ0Lr/lUPBz3Q2o/o=";
        };
        hyprland = hyprlandPkg;
        nativeBuildInputs = [ prev.cmake ];
        meta = with prev.lib; {
          homepage = "https://github.com/sandwichfarm/hyprexpo-plus";
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

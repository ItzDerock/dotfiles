# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # openldap build error
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

    btop = prev.btop.overrideAttrs (old: {
      passthru = (old.passthru or {}) // {
        # `withoutGpu` is a new package variant of btop.
        withoutGpu = prev.btop.overrideAttrs (final: prev: {
          cmakeFlags = prev.cmakeFlags ++ [ "-DBTOP_GPU=OFF" ];
        });
      };
    });

    openssh = prev.openssh.overrideAttrs (old: {
      # Disable "bad permission" checking in openssh
      # Home-manager issue #322
      patches = (old.patches or []) ++ [../assets/openssh/no-check-permission.patch];
      doCheck = false;
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

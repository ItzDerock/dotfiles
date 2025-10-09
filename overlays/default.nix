# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
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
          cmakeFlags = prev.cmakeFlags ++ [ "-DGPU_SUPPORT=OFF" ];
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
      })
    ];
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

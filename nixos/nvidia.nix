{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.nvidia;
in {
  options.rockcfg.nvidia = {
    enable = mkEnableOption "Enables NVIDIA";
    primary = mkEnableOption "Set as primary GPU";
  };

  config = mkIf cfg.enable { 
    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;

      extraPackages = with pkgs; [nvidia-vaapi-driver];
    };

    environment.sessionVariables = mkIf cfg.primary {
      LIBVA_DRIVER_NAME = "nvidia";
    };

    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
          # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # package = config.boot.kernelPackages.nvidiaPackages.beta; # nvidia is never stable lol 
      package = config.boot.kernelPackages.nvidiaPackages.beta.overrideAttrs {
        version = "550.54.14";
        # the new driver
        src = pkgs.fetchurl
          {
            url = "https://download.nvidia.com/XFree86/Linux-x86_64/550.40.07/NVIDIA-Linux-x86_64-550.40.07.run";
            sha256 = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
          };

        # src = pkgs.fetchurl
        #     {
        #       url = "https://us.download.nvidia.com/XFree86/Linux-x86_64/550.54.14/NVIDIA-Linux-x86_64-550.54.14.run";
        #       sha256 = "sha256-jEl/8c/HwxD7h1FJvDD6pP0m0iN7LLps0uiweAFXz+M=";
        #     };
      };

      prime = mkIf (!cfg.primary) {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };
  };
}


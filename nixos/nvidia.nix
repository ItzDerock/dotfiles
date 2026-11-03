{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.nvidia;
in
{
  options.rockcfg.nvidia = {
    enable = mkEnableOption "Enables NVIDIA";
    primary = mkEnableOption "Set as primary GPU";
  };

  config = mkIf cfg.enable {
    programs.gamemode.enable = true;

    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs;
        [ nvidia-vaapi-driver libva vulkan-loader vulkan-tools vulkan-validation-layers ];

      extraPackages32 = with pkgs.pkgsi686Linux;
        [ libva vulkan-loader vulkan-tools vulkan-validation-layers ];
    };

    # cuda
    # Note: cudaSupport is NOT enabled globally — that flips it on for every
    # package with the option (onnxruntime, opencv, ffmpeg, ...) and pulls them
    # off cache.nixos.org. Opt in per-package via overlays/default.nix instead.
    environment.systemPackages = with pkgs; [
      cudaPackages.cudatoolkit
      nv-codec-headers
      libva
    ];

    environment.sessionVariables = mkIf cfg.primary {
      LIBVA_DRIVER_NAME = "nvidia";
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = true; #!cfg.primary;
      dynamicBoost.enable = !cfg.primary;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = !cfg.primary;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of
      # supported GPUs is at:
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = true;
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      # Stable has a use-after-free bug .-.
      package =
        let
          driver = config.boot.kernelPackages.nvidiaPackages.latest;
        in
        driver // {
          # NVIDIA 615 probes PCI sysfs from a kthread; Linux 7.3 gives it a nullfs root.
          # Patch only the open module, preserving the cached kernel.
          # https://github.com/CachyOS/kernel-patches/pull/191
          open = driver.open.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/CachyOS/kernel-patches/89bb22dec944d4d5b31332f2affbc740665cf0d9/7.3/misc/nvidia/0004-Open-sysfs-config-from-the-userspace-root-on-7.3.patch";
                hash = "sha256-pruuHakb6tcDDteKFh3t0tyNONSV74evJGc2Qu8dfKk=";
              })
            ];
          });
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

    # boot.extraModprobeConfig = ''
    #   options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_DynamicPowerManagement=0x02
    # '';
  };
}

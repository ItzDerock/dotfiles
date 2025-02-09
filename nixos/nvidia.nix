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

    hardware.opengl = {
      enable = true;
      # driSupport = true;
      # driSupport32Bit = true;

      extraPackages = with pkgs;
        [ nvidia-vaapi-driver libva vulkan-loader vulkan-tools vulkan-validation-layers ];

      extraPackages32 = with pkgs.pkgsi686Linux;
        [ libva vulkan-loader vulkan-tools vulkan-validation-layers ];
    };

    # cuda
    nixpkgs.config.cudaSupport = true;
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
      open = false;
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.beta.overrideAttrs (old: rec {
        patches = (old.patches or []) ++ [
          (builtins.toFile "remove-date.patch" ''
            --- a/kernel/nvidia-drm/nvidia-drm-drv.c
            +++ b/kernel/nvidia-drm/nvidia-drm-drv.c
            @@ -88,6 +88,7 @@
             
             #include <linux/pci.h>
             #include <linux/workqueue.h>
            +#include <linux/version.h>
             
             /*
              * Commit fcd70cd36b9b ("drm: Split out drm_probe_helper.h")
            @@ -1915,7 +1916,9 @@ static struct drm_driver nv_drm_driver = {
                 .name                   = "nvidia-drm",
             
                 .desc                   = "NVIDIA DRM driver",
            +#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 14, 0)
                 .date                   = "20160202",
            +#endif
             
             #if defined(NV_DRM_DRIVER_HAS_DEVICE_LIST)
                 .device_list            = LIST_HEAD_INIT(nv_drm_driver.device_list),
          '')
        ];
      });

      # package = config.boot.kernelPackages.nvidiaPackages.beta.overrideAttrs ({
      #   version,
      #   postPatch ? "",
      #   ...
      # }: {
      #   postPatch = ''
      #     ls -lah
      #     find . -type f -iname "*nvidia-drm*"
      #     sed '1733d' $src/NVIDIA-Linux-x86_64-570.86.16/nvidia-drm/nvidia-drm-drv.c
      #   '';
      # });

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


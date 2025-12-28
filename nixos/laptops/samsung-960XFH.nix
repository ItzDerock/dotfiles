{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.laptop;
in {
  options.rockcfg.laptop = {
    samsung_960XFH = mkEnableOption "Enables specific fixes for Samsung Galaxybook3 Ultra 960XFH (IPU6 Camera)";
  };

  config = mkIf cfg.samsung_960XFH {  
    # Raptor lake, so ipu6ep
    hardware.ipu6 = {
      enable = true;
      platform = "ipu6ep"; 
    };

    # Standard v4l2-relayd defaults to using Intel's proprietary 'icamerasrc'.
    # On the OV02C10 sensor (Samsung Galaxy Book3), that driver is unstable at 
    # 1080p and creates "zombie" device nodes.
    #
    # We override the input pipeline to use 'libcamerasrc' instead, which fixes:
    #   a. Stability: libcamera successfully captures 1080p where icamerasrc hangs.
    #   b. Buffering: We add queues to prevent the stream from crashing on frame drops.
    #   c. Color: The default Software ISP is heavily desaturated and pink-shifted.
    #   d. Compatibility: We force YUY2 output so browsers/Discord accept the feed.
    
    services.v4l2-relayd = {
      instances = {
        ipu6 = {
          enable = true;
          cardLabel = "Intel MIPI Camera";
          extraPackages = [ pkgs.libcamera ];

          # INPUT PIPELINE EXPLANATION:
          # 1. libcamerasrc: 
          #    Captures the raw stream (typically 1080p XRGB/NV12).
          #    We avoid hardcoding caps here to let it negotiate the best raw format.
          #
          # 2. queue: 
          #    Decouples the camera sensor from the processing pipeline. 
          #
          # 3. videoconvert: 
          #    Converts the raw XRGB/NV12 data into a format 'videobalance' can handle.
          #
          # 4. videobalance: 
          #    Manually corrects the "Raw" look of the uncalibrated sensor:
          #    - saturation=2.0:  Fixes massive Green/Blue channel crosstalk (desaturation).
          #    - contrast=1.15:   Crushes sensor noise in shadows and pops highlights.
          #    - brightness=0.03: Slight lift for indoor lighting conditions.
          #    - hue=-0.04:       Rotates "Pink/Magenta" skin tones back to Natural Orange.
          #
          # 5. video/x-raw,format=YUY2: 
          #    Forces the final output to YUY2. This is critical because v4l2-relayd 
          #    expects the input format to match the declared 'format' option below.
          input = {
            pipeline = lib.mkForce "libcamerasrc ! queue ! videoconvert ! videobalance saturation=2.0 contrast=1.15 brightness=0.03 hue=-0.04 ! video/x-raw,format=YUY2";
            width = lib.mkForce 1920; 
            height = lib.mkForce 1080;
            framerate = lib.mkForce 30;
          };

          output = {
            format = "YUY2";
          };
        };
      };
    };
  };
}

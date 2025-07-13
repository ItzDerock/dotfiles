{ ... }:
let
  MAIN_DISPLAY = "DP-2";
in 
{
  # programs.waybar.settings.mainBar = {
  #   output = MAIN_DISPLAY; 
  # };

  wayland.windowManager.hyprland.settings = {
    # monitors
    # monitor = [
    #   "HDMI-A-1,1920x1080@60,-1920x0,1" # random cheapass 1080p
    #   "DP-1,3440x1440@180,0x0,1" # asus ultrawide
    #   "DP-2,3840x2160@60,3440x0,1" # 4k 
    # ];

    env = [
      # disable VRR, should fix flickering
      "__GL_VRR_ALLOWED,0"

      # HDR
      "DXVK_HDR,1" 
    ];
  };
}

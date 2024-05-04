{ ... }:
let
  MAIN_DISPLAY = "DP-2";
in 
{
  programs.waybar.settings.mainBar = {
    output = MAIN_DISPLAY; 
  };

  wayland.windowManager.hyprland.settings = {
    # monitors
    monitor = [
      "HDMI-A-1,1920x1080@60,-1920x0,1" # random cheapass 1080p
      "DP-2,3440x1440@180,0x0,1" # asus ultrawide
      "DP-1,3840x2160@60,3440x0,1" # 4k 
    ];
  
    # make main always wksp 1
    # workspace = [
    #   "1,monitor:${MAIN_DISPLAY},default:true,persistent:true"
    #   "name:screen-2,monitor:HDMI-A-1,default:true,persistent:true"
    #   "name:screen-3,monitor:DP-1,default:true,persistent:true"
    # ];

    # bind = [
    #   "$mod_ALT,1,workspace,1"
    #   "$mod_ALT,2,workspace,name:screen-2"
    #   "$mod_ALT,3,workspace,name:screen-3"
    # ];
  };


}

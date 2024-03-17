{ ... }:
{
  programs.waybar.settings.mainBar = {
    output = "DP-3"; 
  };

  wayland.windowManager.hyprland.settings = {
    # monitors
    monitor = [
      "HDMI-A-1,1920x1080@60,-1920x0,1" # random cheapass 1080p
      "DP-3,3440x1440@180,0x0,1" # asus ultrawide
      "DP-1,3840x2160@60,3440x0,1" # 4k 
    ];
  
    # make DP-3 always wksp 1
    workspace = [
      "1,monitor:DP-3,default:true,persistent:true"
    ];
  };


}

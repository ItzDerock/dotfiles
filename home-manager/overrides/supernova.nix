{ ... }:
let
  MAIN_DISPLAY = "DP-2";
in 
{
  # programs.waybar.settings.mainBar = {
  #   output = MAIN_DISPLAY; 
  # };

  home.sessionVariables = {
    __GL_VRR_ALLOWED = "0";
    DXVK_HDR = "1";
  };
}

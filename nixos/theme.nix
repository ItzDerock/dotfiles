{ pkgs, ... }:
{
  stylix = {
    enable = true;
    image = ../assets/wallpapers/Makima-Landscape.jpg;
    autoEnable = true;
    polarity = "dark";
  };
  
  home-manager.sharedModules = [{
    stylix.enable = true;
  }];
}

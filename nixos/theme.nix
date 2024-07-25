{ pkgs, ... }:
{
  stylix = {
    enable = true;
    image = ../assets/wallpapers/dresdenpainting.jpg;
    autoEnable = true;
    polarity = "dark";
  };
  
  home-manager.sharedModules = [{
    stylix.enable = true;
  }];
}

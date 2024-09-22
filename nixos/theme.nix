{ pkgs, ... }:
{
  stylix = {
    enable = true;
    image = ../assets/wallpapers/river-valley-lush-cliffs.jpg;
    autoEnable = true;
    polarity = "dark";
  };
  
  home-manager.sharedModules = [{
    stylix.enable = true;
  }];
}

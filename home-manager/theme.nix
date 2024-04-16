{ pkgs, ... }:
let
  wallpaper-script = pkgs.writeScriptBin "wallpaper" (builtins.readFile ../assets/scripts/wallpaper.sh); 
in
{
  home.packages = [
    wallpaper-script
    pkgs.nsxiv
    pkgs.file
  ];

  home.file.".config/sxiv/exec/image-info" = {
    executable = true;
    source = ../assets/scripts/image-info.sh;
  };

  programs.pywal.enable = true; 
}

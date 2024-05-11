{ pkgs, ... }:
let
  wallpaper-script = pkgs.writeScriptBin "wallpaper" (builtins.readFile ../assets/scripts/wallpaper.sh);
  wpaudiochanger = pkgs.writeScriptBin "wpaudiochanger" (builtins.readFile ../assets/scripts/wpaudiochange.py);
in
{
  home.packages = with pkgs; [
    wallpaper-script
    wpaudiochanger
    nsxiv
    file
    wallust # pywal was archived
  ];

  home.file.".config/sxiv/exec/image-info" = {
    executable = true;
    source = ../assets/scripts/image-info.sh;
  };

  home.file.".config/wallust/templates" = {
    recursive = true;
    source = ../assets/wallust/templates;
  };

  home.file.".config/wallust/wallust.toml" = {
    recursive = true;
    source = ../assets/wallust.toml;
  };
}

{ config, pkgs, inputs, ... }:
{
  # waybar wttr
  home.packages = with pkgs; [ 
     wttrbar
  ];

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = builtins.fromJSON (builtins.readFile ../assets/waybar/config);
    };
    style = builtins.readFile ../assets/waybar/style.css;
  };

  # home.file.".config/waybar/config".source = ../assets/waybar/config;
  # home.file.".config/waybar/style.css".source = ../assets/waybar/style.css;
}

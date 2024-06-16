# Common wayland applications

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.wayland;
in {
  options.rockcfg.wayland = {
    enable = mkEnableOption "Enables wayland-specific config";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ 
      pkgs.wofi
      pkgs.wofi-emoji
      pkgs.wl-clipboard
      pkgs.qt6.qtwayland
    ];
  };
}

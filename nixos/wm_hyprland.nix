{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.wm.hyprland;
in {
  options.wm.hyprland = {
    enable = mkEnableOption "Enables Hyprland";
  };

  config = mkIf cfg.enable {
    # Hyprland
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    rockcfg = {
      wayland.enable = true;
    };
  };
}

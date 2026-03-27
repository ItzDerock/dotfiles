{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
let
  cfg = config.wm.hyprland;
  pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
in
{
  options.wm.hyprland = {
    enable = mkEnableOption "Enables Hyprland";
  };

  config = mkIf cfg.enable {
    # Hyprland
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      xwayland.enable = true;
      portalPackage = inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
    };

    hardware.graphics = {
      package = mkForce pkgs-hypr.mesa;
      package32 = mkForce pkgs-hypr.pkgsi686Linux.mesa;
      enable32Bit = true;
      enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];

      config = {
        hyprland = {
          default = [
            "hyprland"
            "kde"
          ];

          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        };
      };
    };

    rockcfg = {
      wayland.enable = true;
    };

    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };
}

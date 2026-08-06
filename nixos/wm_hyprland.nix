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

    # Outside a Plasma session nothing installs an XDG application menu, and
    # XDG_MENU_PREFIX is unset — so kbuildsycoca6 finds no root menu and every
    # KDE app list built from KServiceGroup comes up empty. Most visibly,
    # Dolphin's "Open with" dialog shows zero programs. Reusing Plasma's menu
    # as the unprefixed applications.menu populates the tree; plasma-workspace
    # is already in the system closure via xdg-desktop-portal-kde, so this
    # costs nothing. Verify with:
    #   kbuildsycoca6 --noincremental && \
    #     strings -a -eb $(ls -t ~/.cache/ksycoca6* | head -1) | grep -c '\.directory'
    # 1 means the menu was not found; ~44 means the tree built.
    environment.etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

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

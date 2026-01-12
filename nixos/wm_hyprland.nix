{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.wm.hyprland;
  pkgs-hypr = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
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
      portalPackage = inputs.hyprland.packages."${pkgs.system}".xdg-desktop-portal-hyprland;
    };

    security.pam.services.hyprland.kwallet.enable = true;

    # pin mesa version
    # nixpkgs.overlays = [
    #   (final: prev: {
    #     mesa = pkgs-hypr.mesa;
    #   })
    # ];

    hardware.graphics = {
      package = mkForce pkgs-hypr.mesa;
      package32 = mkForce pkgs-hypr.pkgsi686Linux.mesa;
      enable32Bit = true;
      enable = true;
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

    # fix hyprland sleep stuff 
    # systemd.services.hyprland-suspend = {
    #   description = "https://github.com/MysticBytes786/hyprland-suspend-fix";
    #   path = [ pkgs.toybox ];

    #   wantedBy = [
    #     "systemd-suspend.service"
    #     "systemd-hibernate.service"
    #   ];

    #   before = [
    #     "systemd-suspend.service"
    #     "systemd-hibernate.service"
    #     "nvidia-suspend.service"
    #     "nvidia-hibernate.service"
    #   ];

    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.toybox}/bin/pkill -STOP Hyprland";
    #   };
    # };

    # systemd.services.hyprland-resume = {
    #   description = "https://github.com/MysticBytes786/hyprland-suspend-fix";
    #   path = [ pkgs.toybox ];

    #   wantedBy = [
    #     "systemd-suspend.service"
    #     "systemd-hibernate.service"
    #   ];

    #   after = [
    #     "systemd-suspend.service"
    #     "systemd-hibernate.service"
    #     "nvidia-resume.service"
    #   ];

    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.toybox}/bin/pkill -CONT Hyprland";
    #   };
    # };

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };
}

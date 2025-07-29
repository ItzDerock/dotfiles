{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.wm.hyprland;
  pkgs-hyprland = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system};
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

    # pin mesa version
    hardware.graphics = {
      package = pkgs-hyprland.mesa;
      enable32Bit = true;
      package32 = pkgs-hyprland.pkgsi686Linux.mesa;
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

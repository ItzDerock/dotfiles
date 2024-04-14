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

    # fix hyprland sleep stuff 
    systemd.services.hyprland-suspend = {
      description = "https://github.com/MysticBytes786/hyprland-suspend-fix";
      path = [ pkgs.toybox ];

      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];

      before = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
        "nvidia-suspend.service"
        "nvidia-hibernate.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.toybox}/bin/pkill -STOP Hyprland";
      };
    };

    systemd.services.hyprland-resume = {
      description = "https://github.com/MysticBytes786/hyprland-suspend-fix";
      path = [ pkgs.toybox ];

      wantedBy = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
      ];

      after = [
        "systemd-suspend.service"
        "systemd-hibernate.service"
        "nvidia-resume.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.toybox}/bin/pkill -CONT Hyprland";
      };
    };

  };
}

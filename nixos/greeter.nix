{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.greeter;
in
{
  options.rockcfg.greeter = {
    enable = mkEnableOption "Enables greeter";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --asterisks --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
          user = "greeter";
        };
      };
    };

    systemd.services.greetd.serviceConfig = {
      StandardError = "journal";
    };

    security.pam.services.lemurs.kwallet.enable = true;
  };
}

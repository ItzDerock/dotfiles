{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.dm.lemurs;
in
{
  options.dm.lemurs = {
    enable = mkEnableOption "Enables Lemurs DisplayManager";
  };

  config = mkIf cfg.enable {
    # programs.lemurs.enable = true;
    environment.systemPackages = [ pkgs.lemurs ];

    systemd.services.lemurs = {
      description = "Lemurs";
      path = [pkgs.lemurs];
      aliases = ["display-manager.service"];

      after = [
        "systemd-user-sessions.service"
        "plymouth-quit-wait.service"
        "getty@tty2.service"
      ];

      serviceConfig = {
        ExecStart = "${pkgs.lemurs}/bin/lemurs";
        StandardInput = "tty";
        TTYPath = "/dev/tty2";
        TTYReset = "yes";
        TTYVHangup = "yes";
        Type = "idle";
      };
    };

    services.xserver.displayManager.job = {
      execCmd = "exec /run/current-system/sw/bin/lemurs";
    };

    security.pam.services = {
      lemurs.text = ''
        #%PAM-1.0
        auth        include    login
        account     include    login
        session     include    login
        password    include    login
      '';
    };


  };
}

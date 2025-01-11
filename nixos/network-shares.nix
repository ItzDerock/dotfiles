{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.network-shares;
in {
  options.rockcfg.network-shares =  {
    enable = mkEnableOption "Network Shares";
  };

  config = mkIf cfg.enable {
    fileSystems."/mnt/home-nas" = {
      device = "derock@cockpit.bat-major.ts.net:/mnt/main/derock";
      fsType = "sshfs";
      options = [
        # Lazy mount
        "x-systemd.automount"
        "noauto"

        # Disconnect on idle (10 mins)
        "x-systemd.idle-timeout=600"
      ];
    };
  };
}

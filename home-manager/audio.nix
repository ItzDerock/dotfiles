{ pkgs, ... }: {
  systemd.user.services.mpris-proxy = {
    Unit = {
      Description = "Mpris proxy";
    };

    Install = {
      WantedBy = [ "default.target" ];
      After = [ "network.target" "sound.target" ];
    };

    Service = {
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
  };
}

# printing

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.docker;
in {
  options.rockcfg.docker =  {
    enable = mkEnableOption "Docker";
    nvidia = mkEnableOption "NVIDIA containers";
  };

  config = mkIf cfg.enable {
    users.extraGroups.docker.members = [ "derock" ];
    virtualisation.docker = {
      enable = true;
      liveRestore = false;
      enableOnBoot = false; # dont wait for boot
    };
    systemd.sockets.docker.enable = true; # on demand
    hardware.nvidia-container-toolkit.enable = cfg.nvidia;
  };
}

# printing 

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.docker;
in {
  options.rockcfg.docker =  {
    enable = mkEnableOption "Docker";
  };

  config = mkIf cfg.enable {
    # nmcli con import type wireguard file <file>
    virtualisation.docker.enable = true;
    users.extraGroups.docker.members = [ "derock" ]; 
    virtualisation.docker.liveRestore = false;
  };
}

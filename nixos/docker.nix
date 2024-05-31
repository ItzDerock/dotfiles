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
    virtualisation.docker.enable = true;
    users.extraGroups.docker.members = [ "derock" ]; 
    virtualisation.docker.liveRestore = false;
    virtualisation.docker.enableNvidia = cfg.nvidia;
  };
}

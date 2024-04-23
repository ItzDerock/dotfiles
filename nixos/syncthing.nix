# printing 

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.syncthing;
in {
  options.rockcfg.syncthing =  {
    enable = mkEnableOption "Syncthing";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = "derock";
      dataDir = "/home/derock/Documents/";
      configDir = "/home/derock/.config/syncthing";
    };
  };
}

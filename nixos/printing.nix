# printing 

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.printing;
in {
  options.rockcfg.printing = {
    enable = mkEnableOption "Printing services";
  };

  config = mkIf cfg.enable {
    services.printing.enable = true;

    # autodiscovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # additional drivers
    services.printing.drivers = with pkgs; [
      gutenprintBin
      hplipWithPlugin
    ];
  };
}

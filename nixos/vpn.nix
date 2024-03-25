# printing 

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.vpn;
in {
  options.rockcfg.vpn.wireguard =  {
    enable = mkEnableOption "Wireguard";
  };

  config = mkIf cfg.wireguard.enable {
    # nmcli con import type wireguard file <file>
    networking.firewall.checkReversePath = false;
  };
}

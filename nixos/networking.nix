{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.networking;
in {
  options.rockcfg.networking = {
    enable = mkEnableOption "1password";
  };

  config = mkIf cfg.enable { 
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openvpn
        networkmanager-openconnect
      ];
    };
  };
}

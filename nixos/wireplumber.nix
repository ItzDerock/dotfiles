# laptop specific configuration

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.wireplumber;
in {
  options.rockcfg.wireplumber = {
    enable = mkEnableOption "wireplumber stuff";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pavucontrol ncpamixer pamixer
    ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    }; 
  };
}

{ lib, pkgs, config, outputs, ... }: 
with lib;
let
  cfg = config.rockcfg.hardware.razer;
in 
{
  options.rockcfg.hardware.razer = {
    enable = mkEnableOption "Razer hardware";
  };

  config = mkIf cfg.enable {
    hardware.openrazer.enable = true;
    users.users.derock.extraGroups = [ "openrazer" ];
    environment.systemPackages = with pkgs; [
      openrazer-daemon 
      polychromatic
    ];
  };
}

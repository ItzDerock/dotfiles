# laptop specific configuration

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.instantreplay;
in {
  options.rockcfg.instantreplay = {
    enable = mkEnableOption "Enables 'instant replay' feature";
  };

  config = mkIf cfg.enable {
    # programs.lemurs.enable = true;
    environment.systemPackages = with pkgs; [ 
      gpu-screen-recorder
      gpu-screen-recorder-gtk
    ]; 
  };
}

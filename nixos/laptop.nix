# laptop specific configuration

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.laptop;
in {
  options.rockcfg.laptop = {
    enable = mkEnableOption "Enables Laptop related packages";
  };

  config = mkIf cfg.enable {
    # programs.lemurs.enable = true;
    environment.systemPackages = with pkgs; [ 
      brightnessctl
    ];
  };
}

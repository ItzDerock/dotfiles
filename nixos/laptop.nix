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
    environment.systemPackages = with pkgs; [ 
      brightnessctl
    ];

    hardware.graphics = {
      extraPackages = with pkgs; [ intel-media-driver ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}

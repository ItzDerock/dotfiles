# laptop specific configuration

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.laptop;
in {
  options.rockcfg.laptop = {
    enable = mkEnableOption "Enables Laptop related packages";
    soundFix = mkEnableOption "samsung galaxy book sound fixes";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ 
      brightnessctl
    ] ++ (if cfg.soundFix then [
      sof-firmware
      alsa-tools
    ] else []);

    # boot.extraModprobeConfig = mkIf cfg.soundFix ''
    #   options snd slots=snd_soc_skl_hda_dsp
    # '';

    boot.blacklistedKernelModules = mkIf cfg.soundFix [
      "snd_hda_intel"
    ];

    hardware.firmware = mkIf cfg.soundFix [
      pkgs.sof-firmware
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

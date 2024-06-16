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
    # programs.lemurs.enable = true;
    environment.systemPackages = with pkgs; [ 
      brightnessctl
    ] ++ (if cfg.soundFix then [
      sof-firmware
      alsa-tools
    ] else []);

    # boot.extraModprobeConfig = mkIf cfg.soundFix ''
    #   options snd slots=snd_soc_skl_hda_dsp
    # '';

    # boot.blacklistedKernelModules = mkIf cfg.soundFix [
    #   "snd-hda-intel"
    # ];

    hardware.firmware = mkIf cfg.soundFix [
      pkgs.sof-firmware
    ];

    hardware.opengl = {
      extraPackages = with pkgs; [ intel-media-driver ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}

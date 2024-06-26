# laptop specific configuration

{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.wireplumber;
in
{
  options.rockcfg.wireplumber = {
    enable = mkEnableOption "wireplumber stuff";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pavucontrol
      ncpamixer
      pamixer
    ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # fix latency and crackling
    services.pipewire.extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 32;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 32;
      };
    };

    # bluetooth audio
    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          # Experiment = true;
        };
      };
    };
    hardware.bluetooth.powerOnBoot = true;
    services.blueman.enable = true;

    # bluetooth
    services.pipewire.wireplumber.extraConfig = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      };
    };
  };
}

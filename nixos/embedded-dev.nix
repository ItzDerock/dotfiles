{ lib, pkgs, config, outputs, ... }: 
with lib;
let
  cfg = config.rockcfg.embedded-dev;
in 
{
  options.rockcfg.embedded-dev = {
    enable = mkEnableOption "Embedded development tools/udev rules";
  };

  config = mkIf cfg.enable {
    services.udev.packages = [
      pkgs.platformio-core.udev
      outputs.packages.${pkgs.system}.probe-rs-rules
      pkgs.tio # serial tty
    ];
  };
}

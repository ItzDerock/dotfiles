{ lib, pkgs, ... }:
with lib; let
  cfg = config.rockcfg.winapps;

  generateKeyValueFile = configAttrs:
    lib.strings.concatStringsSep "\n" (
      lib.attrsets.mapAttrsToList
        (name: value: "${name}=${value}")
        configAttrs
    );
in
{
  options.rockcfg.winapps = {
    enable = mkEnableOption "winapps-org/winapps";
  };

  config = mkIf cfg.enable {
    xdg.configFile."winapps/winapps.conf".text = (
      generateKeyValueFile {
        RDP_USER = "derock";
        RDP_PASS =
      }
    );
  };
}

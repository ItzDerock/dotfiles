{ config, lib, pkgs, inputs, ... }:
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
    rdp_password = mkOption {
      type = types.str;
      default = "insecure";
      description = "Password for the RDP connection to the Windows VM.";
    };
  };

  config = mkIf cfg.enable {
    # Hard to make non world-readable files delaratively
    # Files in nix store are world-readable
    # and there's no "mode = 600" option available.
    # xdg.configFile."winapps/winapps.conf" = {
    #   text = (
    #     generateKeyValueFile {
    #       RDP_USER = "derock";
    #       RDP_PASS = cfg.rdp_password;
    #       AUTOPAUSE = "on";
    #       RDP_IP = "127.0.0.1";
    #     }
    #   );
    # };

    home.packages = [
      inputs.winapps.packages."${pkgs.system}".winapps
      inputs.winapps.packages."${pkgs.system}".winapps-launcher
    ];
  };
}

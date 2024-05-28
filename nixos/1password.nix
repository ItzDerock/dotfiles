{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.onepass;
in {
  options.rockcfg.onepass = {
    enable = mkEnableOption "1password";
  };

  config = mkIf cfg.enable { 
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = ["derock"];
    };

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivaldi-bin
          floorp
          brave
        '';
        mode = "0755";
      };
    };
  }; 
}

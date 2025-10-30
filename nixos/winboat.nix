{ lib, config, inputs, pkgs, ... }:
with lib;
let
  cfg = config.rockcfg.winboat;
in {
  options.rockcfg.winboat = {
    enable = mkEnableOption "winboat";
    username = mkOption {
      type = types.str;
      description = "user account username";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      libvirtd.enable = true; 
      spiceUSBRedirection.enable = true;
    };

    users.users.${cfg.username}.extraGroups = [ "libvirtd" ];
    environment.systemPackages = [
      inputs.winboat.packages.${pkgs.system}.winboat
      pkgs.freerdp
    ];
  };
}

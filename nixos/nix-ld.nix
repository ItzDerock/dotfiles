{ lib, pkgs, config, outputs, ... }: 
with lib;
let
  cfg = config.rockcfg.nix-ld;
in 
{
  options.rockcfg.nix-ld = {
    enable = mkOption {
      type = types.bool;
      example = false;
      default = true;
      description = "Nix-ld";
    };
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        zlib
        nss
        openssl
        curl
        expat
      ];
    };
  }; 
}

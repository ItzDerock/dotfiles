{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.onepass;
in {
  options.rockcfg.onepass = {
    enable = mkEnableOption "1password";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs._1password-gui
      pkgs._1password
    ];

    programs.ssh = { 
      enable = true;
      extraConfig = ''
        Host *
          IdentitiesOnly=yes
          IdentityAgent ~/.1password/agent.sock
      '';
    };

    programs.git = {
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGHd1AMf74rYtfstIfuq3XWnEImeVa1JgUJCmroNw/P";
        signByDefault = true;
      };

      extraConfig = {
        gpg."ssh".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        gpg.format = "ssh";
        init.defaultBranch = "main";
      };
    };
  }; 
}

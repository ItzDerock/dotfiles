{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rockcfg.git;
in {
  options.rockcfg.git = {
    enable = mkEnableOption "Git and GitHub CLI";
  };

  config = mkIf cfg.enable { 
    programs.gh.enable = true;
    programs.gh.extensions = with pkgs; [
      gh-dash
    ];

    programs.git = {
      enable = true;
      userName = "Derock";
      userEmail = "derock@derock.dev";
      lfs.enable = true;
    };   
  }; 
}

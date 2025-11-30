{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.rockcfg.theme;
in {
  options.rockcfg.theme = {
    enable = mkOption {
      default = true;
      example = false;
      description = "Enable global theming";
      type = lib.types.bool;
    };

    # https://github.com/tinted-theming/schemes
    theme16 = mkOption {
      default = "gruber";
      example = "github";
      description = "base16-scheme to use";
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      polarity = "dark";

      base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.theme16}.yaml";
      
      # Check "Modules >" at
      # https://nix-community.github.io/stylix/
      autoEnable = false;
      targets = {
        console.enable = true;
      };
    };
    
    home-manager.sharedModules = [{
      stylix = {
        enable = true;
       
        targets = {
          btop.enable = true;
          foot.enable = true;
          gtk.enable = true;
          neovim.enable = true;
          obsidian.enable = true;
          starship.enable = true;
          tmux.enable = true;
          kde.enable = true;
        };
      };
    }];

    # grub theme
    boot.loader.grub = {
      minegrub-theme = {
        enable = true;
        splash = "I use NixOS btw";
        background = "background_options/1.8  - [Classic Minecraft].png";
        boot-options-count = 4;
      };
    };
  };
}

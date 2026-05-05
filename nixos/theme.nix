{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.rockcfg.theme;
in
{
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

    home-manager.sharedModules = [
      ({ config, ... }: {
        stylix = {
          enable = true;

          targets = {
            btop.enable = true;
            foot.enable = true;
            neovim.enable = true;
            obsidian.enable = true;
            starship.enable = true;
            tmux.enable = true;

            gtk.enable = true;

            # configured by caelestia
            qt.enable = false;
            kde.enable = false;
          };
        };

        # stylix's gtk target writes gtk.css as a regular file; without force,
        # activation fails when a stale .bak from a previous run is present.
        home.file."${config.xdg.configHome}/gtk-3.0/gtk.css".force = lib.mkForce true;
        home.file."${config.xdg.configHome}/gtk-4.0/gtk.css".force = lib.mkForce true;
      })
    ];
  };
}

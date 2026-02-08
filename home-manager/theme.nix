{ lib, pkgs, config, inputs, ... }:
let
  wallpaper-script = pkgs.writeScriptBin "wallpaper" (builtins.readFile ../assets/scripts/wallpaper.sh);
  wpaudiochanger = pkgs.writeScriptBin "wpaudiochanger" (builtins.readFile ../assets/scripts/wpaudiochange.py);
  caelestia = inputs.caelestia.packages.${pkgs.system}.default;
in
{
  home.packages = with pkgs; [
    wallpaper-script
    wpaudiochanger
    nsxiv
    file
    wallust # pywal was archived
    
    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    ayu-theme-gtk
    (catppuccin-kvantum.override {
      accent = "lavender";
      variant = "mocha";
    })
  ];

  home.file = {
    ".config/sxiv/exec/image-info" = {
      executable = true;
      source = ../assets/scripts/image-info.sh;
    };

    ".config/wallust/templates" = {
      recursive = true;
      source = ../assets/wallust/templates;
    };

    ".config/wallust/wallust.toml" = {
      recursive = true;
      source = ../assets/wallust.toml;
    };

    ".config/caelestia/shell.json".text = builtins.toJSON {
      paths.wallpaperDir = "/home/derock/NixOS/assets/wallpapers/";
      bar = {
        clock.showIcon = false;
        scrollActions = {
          brightness = false;
          workspaces = false;
          volume = false;
        };

        status.showAudio = true;
        showOnHover = false;
        
        popouts = {
          activeWindow = false;
        };
      };

      launcher = {
        vimKeybinds = true;
        useFuzzy.apps = true;
      };

      services = {
        useFahrenheit = false;
      };

      general = {
        idle = {
          timeouts = [];
        };
      };
    };

    "Pictures/Wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink ../assets/wallpapers;
  };

  systemd.user.sessionVariables = {
    QT_STYLE_OVERRIDE = lib.mkForce "kvantum";
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct"; 
  };

  
  home.sessionVariables = {
    QT_STYLE_OVERRIDE = lib.mkForce "kvantum";
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct"; 
  };

  
  # footerm
  home.file."${config.xdg.configHome}/foot/foot.ini" = {
    text = ''
      font=JetBrainsMono Nerd Font:size=16

      [colors]
      alpha=0.87
    '';
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}

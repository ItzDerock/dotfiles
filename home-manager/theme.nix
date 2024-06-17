{ pkgs, ... }:
let
  wallpaper-script = pkgs.writeScriptBin "wallpaper" (builtins.readFile ../assets/scripts/wallpaper.sh);
  wpaudiochanger = pkgs.writeScriptBin "wpaudiochanger" (builtins.readFile ../assets/scripts/wpaudiochange.py);
in
{
  home.packages = with pkgs; [
    wallpaper-script
    wpaudiochanger
    nsxiv
    file
    wallust # pywal was archived

    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
    ayu-theme-gtk
    (catppuccin-kvantum.override {
      accent = "Lavender";
      variant = "Mocha";
    })
  ];

  home.file.".config/sxiv/exec/image-info" = {
    executable = true;
    source = ../assets/scripts/image-info.sh;
  };

  home.file.".config/wallust/templates" = {
    recursive = true;
    source = ../assets/wallust/templates;
  };

  home.file.".config/wallust/wallust.toml" = {
    recursive = true;
    source = ../assets/wallust.toml;
  };

  qt = {
    enable = true;
    style.name = "kvantum";
    platformTheme = "qtct";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig".source = (pkgs.formats.ini { }).generate "kvantum.kvconfig" {
    General.theme = "Catppuccin-Mocha-Lavender";
  }; 

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Standard-Lavender-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "lavender" ];
        size = "standard";
        variant = "mocha";
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "lavender";
      };
    };
    cursorTheme = {
      name = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "Catppuccin-Mocha-Dark-Cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
    size = 16;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Catppuccin-Mocha-Standard-Lavender-Dark";
      color-scheme = "prefer-dark";
    };

    # For Gnome shell
    "org/gnome/shell/extensions/user-theme" = {
      name = "Catppuccin-Mocha-Standard-Lavender-Dark";
    };
  };
}

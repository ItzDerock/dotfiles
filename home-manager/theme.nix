{ pkgs, config, inputs, ... }:
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
      paths = {
        wallpaperDir = "/home/derock/NixOS/assets/wallpapers/";
      };
    };

    "Pictures/Wallpapers".source =
      config.lib.file.mkOutOfStoreSymlink ../assets/wallpapers;
  };


  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";

    # style.name = "kvantum";
    # platformTheme = "qtct";
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

    # cursorTheme = {
    #   name = "Catppuccin-Mocha-Dark-Cursors";
    #   package = pkgs.catppuccin-cursors.mochaDark;
    # };

    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
    };
  }; 
}

{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  wallpaper-script = pkgs.writeScriptBin "wallpaper" (
    builtins.readFile ../assets/scripts/wallpaper.sh
  );
  wpaudiochanger = pkgs.writeScriptBin "wpaudiochanger" (
    builtins.readFile ../assets/scripts/wpaudiochange.py
  );

  # https://github.com/hyprwm/hyprqt6engine/blob/0021cc218fc23862a5688b7b217adba09d44ef1c/common/common.cpp#L26C1-L29C7
  # .config support requries additional libs
  hyprqt6 = inputs.hyprqt6engine.packages.${pkgs.system}.default.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      pkgs.kdePackages.kconfig
      pkgs.kdePackages.kcolorscheme
    ];
  });
in
{
  home.packages = with pkgs; [
    wallpaper-script
    wpaudiochanger
    nsxiv
    file
    wallust # pywal was archived

    hyprqt6
    kdePackages.breeze

    ayu-theme-gtk
    (catppuccin-kvantum.override {
      accent = "lavender";
      variant = "mocha";
    })
  ];

  home.file = {
    ".config/hypr/hyprqt6engine.conf" = {
      text = ''
        theme {
          color_scheme = /home/derock/.config/qt6ct/colors/caelestia.colors
          icon_theme = Papirus-Dark
          style = Breeze
        }
      '';
    };

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

        actions = [
          {
            name = "Remove Image Background";
            icon = "ink_eraser";
            description = "Remove the background from the image in the clipboard.";
            command = [
              "bash"
              "-c"
              "quick-rmbg"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Picture-in-picture";
            icon = "picture_in_picture_alt";
            description = "Pins the current window to float on all desktops.";
            command = [
              "hyprctl"
              "dispatch"
              "pin"
            ];
            enabled = true;
            dangerous = false;
          }

          # DEFAULT Caelestia ones
          {
            name = "Calculator";
            icon = "calculate";
            description = "Do simple math equations (powered by Qalc)";
            command = [
              "autocomplete"
              "calc"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Scheme";
            icon = "palette";
            description = "Change the current colour scheme";
            command = [
              "autocomplete"
              "scheme"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Wallpaper";
            icon = "image";
            description = "Change the current wallpaper";
            command = [
              "autocomplete"
              "wallpaper"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Variant";
            icon = "colors";
            description = "Change the current scheme variant";
            command = [
              "autocomplete"
              "variant"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Transparency";
            icon = "opacity";
            description = "Change shell transparency";
            command = [
              "autocomplete"
              "transparency"
            ];
            enabled = false;
            dangerous = false;
          }
          {
            name = "Random";
            icon = "casino";
            description = "Switch to a random wallpaper";
            command = [
              "caelestia"
              "wallpaper"
              "-r"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Light";
            icon = "light_mode";
            description = "Change the scheme to light mode";
            command = [
              "setMode"
              "light"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Dark";
            icon = "dark_mode";
            description = "Change the scheme to dark mode";
            command = [
              "setMode"
              "dark"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Shutdown";
            icon = "power_settings_new";
            description = "Shutdown the system";
            command = [
              "systemctl"
              "poweroff"
            ];
            enabled = true;
            dangerous = true;
          }
          {
            name = "Reboot";
            icon = "cached";
            description = "Reboot the system";
            command = [
              "systemctl"
              "reboot"
            ];
            enabled = true;
            dangerous = true;
          }
          {
            name = "Logout";
            icon = "exit_to_app";
            description = "Log out of the current session";
            command = [
              "loginctl"
              "terminate-user"
              ""
            ];
            enabled = true;
            dangerous = true;
          }
          {
            name = "Lock";
            icon = "lock";
            description = "Lock the current session";
            command = [
              "loginctl"
              "lock-session"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Sleep";
            icon = "bedtime";
            description = "Suspend then hibernate";
            command = [
              "systemctl"
              "suspend-then-hibernate"
            ];
            enabled = true;
            dangerous = false;
          }
          {
            name = "Settings";
            icon = "settings";
            description = "Configure the shell";
            command = [
              "caelestia"
              "shell"
              "controlCenter"
              "open"
            ];
            enabled = true;
            dangerous = false;
          }

        ];
      };

      border = {
        thickness = 1;
      };

      services = {
        useFahrenheit = false;
        useFahrenheitPerformance = false;
        gpuType = "generic";
      };

      general = {
        idle = {
          timeouts = [ ];
        };
      };
    };

    "Pictures/Wallpapers".source = config.lib.file.mkOutOfStoreSymlink ../assets/wallpapers;
  };

  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "hyprqt6engine";
    QT_PLUGIN_PATH = lib.mkForce "${hyprqt6}/lib/qt-6:\${QT_PLUGIN_PATH}";
  };

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "hyprqt6engine";
    QT_PLUGIN_PATH = lib.mkForce "${hyprqt6}/lib/qt-6:\${QT_PLUGIN_PATH}";
  };

  # footerm
  home.file."${config.xdg.configHome}/foot/foot.ini" = {
    text = ''
      font=JetBrainsMono Nerd Font:size=16

      [colors-dark]
      alpha=0.7
      background=000000
    '';
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}

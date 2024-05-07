{ inputs, pkgs, config, outputs, ... }:
let 
  cursorTheme = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
in
{
  imports = [
    inputs.hyprlock.homeManagerModules.hyprlock
  ];

  programs.bash.profileExtra = ''
    [ "$(tty)" = "/dev/tty1" ] && ! pgrep Hyprland >/dev/null && exec Hyprland &> /dev/null
  '';

  home.packages = with pkgs; [ 
    swww 
    foot 
    (grimblast.override {
      hyprpicker = inputs.hyprpicker.packages.${pkgs.system}.hyprpicker;
    }) 
    playerctl 

    swaynotificationcenter 
    gnome3.adwaita-icon-theme
    libnotify

    # theme
    libsForQt5.breeze-qt5 
    libsForQt5.qtstyleplugin-kvantum 
    hyprcursor # cursor
    cursorTheme

    cliphist # clipboard
    inputs.hyprpicker.packages.${pkgs.system}.hyprpicker # color picker + freeze screen
    annotator # editor
    kooha # video recorder

    # launcher
    kickoff
    outputs.packages.${pkgs.system}.kickoff-dot-desktop
  ];

  programs.hyprlock.enable = true;

  programs.waybar = {
    enable = true;
  };

  # footerm
  home.file."${config.xdg.configHome}/foot/foot.ini" = {
    text = ''
      font=JetBrainsMono Nerd Font:size=18

      [colors]
      alpha=0.8
    '';
  };

  # qt theme
  qt.platformTheme = "qtct";
  qt.style.name = "kvantum";

  # cursor
  home.file.".local/share/icons/rose-pine-hyprcursor".source = "${cursorTheme}/share/icons/rose-pine-hyprcursor/";

  wayland.windowManager.hyprland = { 
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    
    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
      inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    ];

    # package = null; # use system hyprland
    settings = {
      "$mod" = "SUPER";

      env = [
        "XCURSOR_SIZE,18"
        "GDK_SCALE,1"
        "QT_SCALE_FACTOR,1.2"
        "QT_SCREEN_SCALE_FACTORS,1;1"
        "GTK_THEME,Adwaita:dark"
        "BROWSER,firefox"
        "SUDO_EDITOR,/usr/bin/nvim"
        "WLR_NO_HARDWARE_CURSORS,1"

        # enable wayland for stuff
        "NIXOS_OZONE_WL,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "GDK_BACKEND,wayland"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"

        # Disable QT window decoration
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1" 
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "QT_STYLE_OVERRIDE=kvantum"

        # cursor
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        "HYPRCURSOR_SIZE,34"

        # iGPU for hyprland unless dGPU is needed
        # "WLR_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1"
        # "__EGL_VENDOR_LIBRARY_FILENAMES,/usr/share/glvnd/egl_vendor.d/50_mesa.json"
        # "__GLX_VENDOR_LIBRARY_NAME,mesa"
        # "WLR_RENDERER,vulkan"
        # "LIBVA_DRIVER_NAME,iHD"
      ];

      "exec-once" = [
        "waybar"
        "swww init"

        "wl-paste -p --watch wl-copy -pc" # disable middle mouse paste
        "playerctld" # music daemon
        "swaync" # notifs
        "wl-paste --watch cliphist store" # clipboard

        "1password --silent" # 1p daemon
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind = 
        [
          # Basic controls
          "$mod, P, togglefloating,"
          "$mod, F, fullscreen,1"
          "$mod_SHIFT, F, fullscreen,2"
          "$mod, E, fullscreen,0"
    
          "$mod, I, exec, firefox" # browser
          "$mod, T, exec, foot" # terminal
          "$mod, C, killactive" # close window

          "$mod, period, exec, wofi-emoji" # emoji picker

          # screenshot
          "$mod_SHIFT, S, exec, grimblast --freeze copy area"
          ",Print,exec, grimblast --freeze copy screen && notify-send Screen copied"
          "$mod_SHIFT,Print,exec, grimblast --freeze save area - | com.github.phase1geo.annotator -i"

          # screen record
          "SHIFT, Print, exec, quick-record &> ~/.cache/quick-record.log"

          # pick color
          "$mod_SHIFT, C, exec, hyprpicker -f hex -a"
          "$mod_ALT, C, exec, hyprpicker -f hex -a -r"

          # "Alt Tab"
          "ALT, Tab, cyclenext"
          "ALT, Tab, bringactivetotop"

          # run dialog
          "$mod, SPACE, exec, kickoff-dot-desktop | kickoff --from-stdin" # wofi -S drun -I
          "$mod, R, exec, kickoff" # wofi -S run

          # clipboard
          "$mod, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"
          "$mod_SHIFT, D, exec, cliphist list | wofi -dmenu | cliphist delete"

          # hycov
          "ALT, SPACE, overview:toggle"

          # notification center
          "$mod, N, exec, swaync-client -t"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList (
              x: let
                ws = let
                  c = (x + 1) / 10;
                in
                  builtins.toString (x + 1 - (c * 10));
              in [
                "$mod, ${ws}, split-workspace, ${toString (x + 1)}"
                "$mod SHIFT, ${ws}, split-movetoworkspace, ${toString (x + 1)}"
                "$mod ALT, ${ws}, split-movetoworkspacesilent, ${toString (x + 1)}"
              ]
            )
            10)
        );

      # e = repeat, l = ignore inhibitors
      bindel = [
        # Volume
        ",XF86AudioRaiseVolume, exec, pamixer -i 5"
        ",XF86AudioLowerVolume, exec, pamixer -d 5"

        # Brightness
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+ &> ~/.cache/brightness.log"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%- &> ~/.cache/brightness.log"

        # Media controls
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioStop, exec, playerctl stop"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"

        # muilti monitor stuff
        # "$mod, H, split-changemonitor prev"
        # "$mod, L, split-changemonitor next"
      ];

      windowrulev2 = [
        "opacity 0.85 override 0.85 override,class:(code-url-handler)"
      ];

      input = {
        touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
          scroll_factor = 0.2;
        };

        sensitivity = 0.6;
        accel_profile = "flat";
      };

      misc = {
        disable_hyprland_logo = true;
        enable_swallow = true;
        swallow_regex = "^(kitty|foot*)$";
        force_default_wallpaper = 0;
      };
    };
  };
}

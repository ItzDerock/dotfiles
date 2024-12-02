{ inputs, pkgs, config, outputs, ... }:
let
  cursorTheme = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
in
{
  programs.bash.profileExtra = '' [ "$(tty)" = "/dev/tty1" ] && ! pgrep Hyprland >/dev/null && exec Hyprland &> /dev/null
  '';

  home.packages = with pkgs; [
    swww
    foot
    (grimblast.override {
      hyprpicker = inputs.hyprpicker.packages.${pkgs.system}.hyprpicker;
    })
    playerctl

    swaynotificationcenter
    adwaita-icon-theme
    libnotify

    # theme
    hyprcursor # cursor
    cursorTheme
    rose-pine-cursor

    cliphist # clipboard
    inputs.hyprpicker.packages.${pkgs.system}.hyprpicker # color picker + freeze screen
    annotator # editor
    kooha # video recorder

    # launcher
    kickoff
    outputs.packages.${pkgs.system}.kickoff-dot-desktop
  ];

  # programs.hyprlock.enable = true;

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

  # cursor
  home.file.".local/share/icons/rose-pine-hyprcursor".source = "${cursorTheme}/share/icons/rose-pine-hyprcursor/";

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;

    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
      # all of these fail to build...
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
      # inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    ];

    # package = null; # use system hyprland
    settings = {
      "$mod" = "SUPER";

      env = [
        "XCURSOR_SIZE,34"
        "XCURSOR_THEME,rose-pine-cursor"
        "GDK_SCALE,1"
        "QT_SCALE_FACTOR,1.2"
        "QT_SCREEN_SCALE_FACTORS,1;1"
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

        # cursor
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        "HYPRCURSOR_SIZE,34"
      ];

      general = {
       	border_size = 0;
       	gaps_in = 1;
       	gaps_out = 0;
      };

      animations.enabled = false;

      "exec-once" = [
        "waybar"
        "swww init"

        # "wl-paste -p --watch wl-copy -pc" # disable middle mouse paste
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

          # L/R between desktops
          "$mod_SHIFT, W, workspace, e-1"
          "$mod_SHIFT, E, workspace, e+1"

          # Pin a window (shows on all wkspcs)
          "$mod_SHIFT, P, pin"

          # Change the split mode (dwindle)
          "$mod, J, togglesplit"
          "$mod_SHIFT, J, swapsplit"

          # run dialog
          "$mod, SPACE, exec, kickoff-dot-desktop | kickoff --from-stdin" # wofi -S drun -I
          "$mod_SHIFT, SPACE, exec, wofi -S drun -I"
          "$mod, R, exec, kickoff" # wofi -S run
          "$mod_ALT, SPACE, exec, 1password --quick-access"

          # clipboard
          "$mod, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"
          "$mod_SHIFT, D, exec, cliphist list | wofi -dmenu | cliphist delete"

          # "ALT, SPACE, overview:toggle"
          "$mod, TAB, hyprexpo:expo, toggle"

          # notification center
          "$mod, N, exec, swaync-client -t"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
          builtins.concatLists (builtins.genList
            (
              x:
              let
                ws =
                  let
                    c = (x + 1) / 10;
                  in
                  builtins.toString (x + 1 - (c * 10));
              in
              [
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
        "float, class:(xdg-desktop-portal-gtk)"
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
        middle_click_paste = false;
        vfr = true;
      };

      dwindle = {
        smart_split = true;
      };
    };

    extraConfig = ''
      # window resize
      bind = $mod, S, submap, resize

      submap = resize
      binde = , H, resizeactive, -10 0
      binde = , L, resizeactive, 10 0
      binde = , J, resizeactive, 0 -10
      binde = , K, resizeactive, 0 10
      bind = , catchall, submap, reset
      submap = reset

      # dwindle stuff
      bind = $mod, A, submap, dwindle

      submap = dwindle 
      binde = , H, layoutmsg, preselect l
      binde = , H, submap, reset
      binde = , J, layoutmsg, preselect d
      binde = , J, submap, reset
      binde = , K, layoutmsg, preselect u
      binde = , K, submap, reset
      binde = , L, layoutmsg, preselect r
      binde = , L, submap, reset
      bind = , catchall, submap, reset
      submap = reset


      # QWER through windows (similar to HJKL, but one handed)
      bind = $mod, W, submap, cycle

      submap = cycle
      binde = , Q, movefocus, l
      binde = , W, movefocus, d
      binde = , E, movefocus, u
      binde = , R, movefocus, r
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}

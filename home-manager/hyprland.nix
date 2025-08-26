{ inputs, pkgs, config, outputs, ... }:
let
  cursorTheme = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
  caelestia = inputs.caelestia.packages.${pkgs.system}.default;
  caelestia-cli = inputs.caelestia.inputs.caelestia-cli.packages.${pkgs.system}.default;
in
{
  # programs.bash.profileExtra = ''
  #   [ "$(tty)" = "/dev/tty1" ] && ! pgrep Hyprland >/dev/null && exec Hyprland &> /dev/null
  # '';

  home.packages = with pkgs; [
    # shell
    caelestia-cli
    (caelestia.override {
      withCli = true;
    })

    swww
    foot
    (grimblast.override {
      hyprpicker = inputs.hyprpicker.packages.${pkgs.system}.hyprpicker;
    })
    playerctl

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

    # display window
    nwg-displays
  ];

  services.network-manager-applet.enable = true;

  home.sessionVariables = {
    GDK_SCALE = "1";
    QT_SCALE_FACTOR = "1";
    QT_SCREEN_SCALE_FACTORS = "1;1";
    BROWSER = "microsoft-edge";
    SUDO_EDITOR = "${pkgs.neovim}";
    EDITOR = "${pkgs.neovim}";
    WLR_NO_HARDWARE_CURSORS = "1";

    # enable wayland for stuff
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";

    # Disable QT window decoration
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # cursor
    HYPRCURSOR_THEME = "rose-pine-hyprcursor";
    HYPRCURSOR_SIZE = "18";
    XCURSOR_SIZE = "18";
    XCURSOR_THEME = "rose-pine-cursor";
  };

  # programs.hyprlock.enable = true;

  programs.waybar = {
    enable = true;
  };

  # footerm
  home.file."${config.xdg.configHome}/foot/foot.ini" = {
    text = ''
      font=JetBrainsMono Nerd Font:size=16

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
      # Separate workspaces per monitor
      inputs.hyprsplit.packages.${pkgs.system}.hyprsplit

      # WIN + TAB, show all workspaces
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo

      # i3 stuff like sub-workspaces
      inputs.hy3.packages.${pkgs.system}.hy3

      # workspace overview
      # inputs.Hyprspace.packages.${pkgs.system}.Hyprspace
    ];

    # package = null; # use system hyprland
    settings = {
      "$mod" = "SUPER";

      # plugins = [
      #   "${inputs.hy3.packages.${pkgs.system}.hy3}/lib/libhy3.so"
      # ];

      general = {
        layout = "hy3";
       	border_size = 0;
       	gaps_in = 1;
       	gaps_out = 0;
      };

      animations.enabled = false;

      source = [
        "~/.config/hypr/monitors.conf"
      ];

      "exec-once" = [
        "caelestia-shell"

        # "wl-paste -p --watch wl-copy -pc" # disable middle mouse paste
        "playerctld" # music daemon
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

          # session management
          "Ctrl+Alt, Delete, global, caelestia:session"

          # screenshot
          # "$mod_SHIFT, S, exec, grimblast --freeze copy area"
          # ",Print,exec, grimblast --freeze copy screen && notify-send Screen copied"
          # "$mod_SHIFT,Print,exec, grimblast --freeze save area - | com.github.phase1geo.annotator -i"
          ", Print, exec, caelestia screenshot"  # Full screen capture > clipboard
          "$mod_SHIFT, S, exec, caelestia screenshot -fr"  # Capture region (freeze)
          "$mod_Shift_Alt, S, exec, caelestia screenshot region"  # Capture region
          "$mod_SHIFT, Print, exec, caelestia record -rs"  # Record screen with sound
          "SHIFT, Print, exec, caelestia record -r"  # Record region

          # Lock
          "$mod, L, exec, loginctl lock-session"

          # screen record
          # "SHIFT, Print, exec, quick-record &> ~/.cache/quick-record.log"

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

          # Change the split mode (dwidnle,hy3)
          "$mod, D, togglesplit"

          # Move a window up/down/left/right,
          # only moving to neighboring group, without moving into subgroups
          "$mod_SHIFT, h, hy3:movewindow, l, once"
          "$mod_SHIFT, h, hy3:movewindow, l, once"
          "$mod_SHIFT, j, hy3:movewindow, d, once"
          "$mod_SHIFT, k, hy3:movewindow, u, once"
          "$mod_SHIFT, l, hy3:movewindow, r, once"
          "$mod_SHIFT, left, hy3:movewindow, l, once"
          "$mod_SHIFT, down, hy3:movewindow, d, once"
          "$mod_SHIFT, up, hy3:movewindow, u, once"
          "$mod_SHIFT, right, hy3:movewindow, r, once"

          # Only moves between visibile nodes, not hidden
          "$mod_CONTROL_SHIFT, h, hy3:movewindow, l, once, visible"
          "$mod_CONTROL_SHIFT, j, hy3:movewindow, d, once, visible"
          "$mod_CONTROL_SHIFT, k, hy3:movewindow, u, once, visible"
          "$mod_CONTROL_SHIFT, l, hy3:movewindow, r, once, visible"
          "$mod_CONTROL_SHIFT, left, hy3:movewindow, l, once, visible"
          "$mod_CONTROL_SHIFT, down, hy3:movewindow, d, once, visible"
          "$mod_CONTROL_SHIFT, up, hy3:movewindow, u, once, visible"
          "$mod_CONTROL_SHIFT, right, hy3:movewindow, r, once, visible"

          # move focus
          "$mod, h, hy3:movefocus, l"
          "$mod, j, hy3:movefocus, d"
          "$mod, k, hy3:movefocus, u"
          "$mod, l, hy3:movefocus, r"
          "$mod, left, hy3:movefocus, l"
          "$mod, down, hy3:movefocus, d"
          "$mod, up, hy3:movefocus, u"
          "$mod, right, hy3:movefocus, r"

          # Move focus on only visible, without warping mouse
          "$mod_CONTROL, h, hy3:movefocus, l, visible, nowarp"
          "$mod_CONTROL, j, hy3:movefocus, d, visible, nowarp"
          "$mod_CONTROL, k, hy3:movefocus, u, visible, nowarp"
          "$mod_CONTROL, l, hy3:movefocus, r, visible, nowarp"
          "$mod_CONTROL, left, hy3:movefocus, l, visible, nowarp"
          "$mod_CONTROL, down, hy3:movefocus, d, visible, nowarp"
          "$mod_CONTROL, up, hy3:movefocus, u, visible, nowarp"
          "$mod_CONTROL, right, hy3:movefocus, r, visible, nowarp"

          # run dialog
          # "$mod, SPACE, exec, kickoff-dot-desktop | kickoff --from-stdin" # wofi -S drun -I
          "$mod, SPACE, global, caelestia:launcher"
          "$mod_SHIFT, SPACE, exec, wofi -S drun -I"
          "$mod, R, exec, kickoff" # wofi -S run
          "$mod_ALT, SPACE, exec, 1password --quick-access"

          # clipboard
          "$mod, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"
          "$mod_SHIFT, D, exec, cliphist list | wofi -dmenu | cliphist delete"

          "$mod, TAB, hyprexpo:expo, toggle"

          # Pulls all windows from unplugged monitors into current wksp (hyprsplit)
          "$mod, G, split:grabroguewindows"

          # hy3
          # Make a split
          "$mod, S, hy3:makegroup, v"

          # toggle window swallowing
          "$mod_CONTROL_SHIFT, s, toggleswallow"
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
                "$mod, ${ws}, split:workspace, ${toString (x + 1)}"
                "$mod SHIFT, ${ws}, split:movetoworkspace, ${toString (x + 1)}"
                "$mod ALT, ${ws}, split:movetoworkspacesilent, ${toString (x + 1)}"
                "$mod $mod_CONTROL, ${ws}, hy3:focustab, index, ${toString (x + 1)}"
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
        # ",XF86MonBrightnessUp, exec, brightnessctl set 5%+ &> ~/.cache/brightness.log"
        # ",XF86MonBrightnessDown, exec, brightnessctl set 5%- &> ~/.cache/brightness.log"
        ",XF86MonBrightnessUp, global, caelestia:brightnessUp"
        ",XF86MonBrightnessDown, global, caelestia:brightnessDown"

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

      experimental = {
        xx_color_management_v4 = true;
      };

      debug = {
        disable_logs = true;
      };

      xwayland = {
        # X doesnt support fractional scaling
        # so force back to 0 scaling else blurry text
        force_zero_scaling = true;
      };

      # Plugin Configuration
      plugin = {
        hyprexpo = {
          skip_empty = true;
        };
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
      binde = , Q, hy3:movefocus, l
      binde = , W, hy3:movefocus, d
      binde = , E, hy3:movefocus, u
      binde = , R, hy3:movefocus, r
      bind = , catchall, submap, reset
      submap = reset
    '';
  };
}

{
  inputs,
  pkgs,
  config,
  outputs,
  ...
}:
let
  cursorTheme = inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
  caelestia = inputs.caelestia.packages.${pkgs.system}.default;
  caelestia-cli = inputs.caelestia.inputs.caelestia-cli.packages.${pkgs.system}.default;
  clamshell = pkgs.writeScriptBin "clamshell" (builtins.readFile ../assets/scripts/clamshell.sh);
in
{
  # programs.bash.profileExtra = ''
  #   [ "$(tty)" = "/dev/tty1" ] && ! pgrep Hyprland >/dev/null && exec Hyprland &> /dev/null
  # '';

  systemd.user.sessionVariables = config.home.sessionVariables;

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
    hyprcursor # cursor cursorTheme
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
    BROWSER = "zen";
    SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
    EDITOR = "${pkgs.neovim}/bin/nvim";
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

  programs.waybar = {
    enable = true;
  };

  # cursor
  home.file.".local/share/icons/rose-pine-hyprcursor".source =
    "${cursorTheme}/share/icons/rose-pine-hyprcursor/";

  wayland.windowManager.hyprland = {
    enable = true;

    # use Hyprland package from the NixOS module (nixos/wm_hyprland.nix)
    package = null;
    portalPackage = null;

    # make dbus activation inherit all variables
    systemd.variables = [ "--all" ];

    plugins = [
      # Separate workspaces per monitor
      inputs.hyprsplit.packages.${pkgs.system}.hyprsplit

      # WIN + TAB, show all workspaces
      inputs.hyprland-plugins.packages.${pkgs.system}.hyprexpo
    ];

    # package = null; # use system hyprland
    settings = {
      "$mod" = "SUPER";

      general = {
        layout = "scrolling";
        border_size = 0;
        gaps_in = 1;
        gaps_out = 0;

        "col.active_border" = "rgb(101415) rgb(101415)";
        "col.inactive_border" = "rgb(101415) rgb(101415)";
      };

      animations = {
        enabled = true;

        # Stolen from https://github.com/vyrx-dev/dotfiles/blob/main/.config/hypr/animations.conf
        bezier = [
          "water, 0.22, 0.9, 0.36, 1.0"
          "flow, 0.25, 0.1, 0.25, 1.0"
          "ripple, 0.33, 0.0, 0.2, 1.0"
          "stream, 0.4, 0.0, 0.4, 1.0"
          "cascade, 0.19, 1.0, 0.22, 1.0"
          "md3_standard, 0.2, 0, 0, 1"
          "md3_accel, 0.3, 0, 0.8, 0.15"
          "overshot, 0.05, 0.9, 0.1, 1.05"
        ];

        animation = [
          "windows,    1, 3.0, water"
          "windowsIn,  1, 2.5, cascade,slide"
          "windowsOut, 1, 2.4, stream,slide"
          "windowsMove,1, 1.6, flow"
          "fade,       1, 2.4, water"
          "fadeIn,     1, 2.0, cascade"
          "fadeOut,    1, 1.8, ripple"
          "fadeDim,    1, 2.0, water"
          "fadeSwitch, 1, 1.4, flow"
          "layersIn,       1, 1.5, overshot, popin 80%"
          "layersOut,      1, 1.3, md3_accel, popin 90%"
          "layers,         1, 1.5, md3_standard"
          "workspaces, 1, 1.5, flow"
          "specialWorkspace, 1, 2.5, water"
          "border,     1, 2.9, water"
          "borderangle,1, 3.5, flow"
        ];
      };

      source = [
        "~/.config/hypr/monitors.conf"
      ];

      "exec-once" = [
        # "caelestia-shell"

        # "wl-paste -p --watch wl-copy -pc" # disable middle mouse paste
        "playerctld" # music daemon
        "wl-paste --watch cliphist store" # clipboard

        "1password --silent" # 1p daemon
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind = [
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
        ", Print, exec, caelestia screenshot" # Full screen capture > clipboard
        "Ctrl, Print, exec, caelestia screenshot -fr"
        "$mod_SHIFT, S, exec, screenshot" # Capture region (freeze)
        "$mod_Shift_Alt, S, exec, caelestia screenshot region" # Capture region
        "$mod_SHIFT, Print, exec, caelestia record -rs" # Record screen with sound
        "SHIFT, Print, exec, caelestia record -r" # Record region

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

        "ALT_SHIFT, Tab, cyclenext, prev"
        "ALT_SHIFT, Tab, bringactivetotop"

        # L/R between desktops
        "$mod_SHIFT, W, layoutmsg, move -col"
        "$mod_SHIFT, E, layoutmsg, move +col"

        # Pin a window (shows on all wkspcs)
        "$mod_SHIFT, P, pin"

        # Change the split mode (dwidnle,hy3)
        "$mod, D, togglesplit"

        # focus window
        "$mod, Z, layoutmsg, focus"

        # Move a window left/right,
        "$mod_SHIFT, h, layoutmsg, swapcol l once"
        "$mod_SHIFT, l, layoutmsg, swapcol r once"

        # move focus
        "$mod_CONTROL, h, layoutmsg, move -col"
        "$mod_CONTROL, l, layoutmsg, move +col"

        # run dialog
        "$mod, SPACE, global, caelestia:launcher"
        "$mod_SHIFT, SPACE, exec, wofi -S drun -I"
        "$mod, R, exec, kickoff" # wofi -S run
        "$mod_ALT, SPACE, exec, 1password --quick-access"

        # clipboard
        "$mod, V, exec, cliphist list | wofi -dmenu | cliphist decode | wl-copy"
        "$mod_SHIFT, D, exec, cliphist list | wofi -dmenu | cliphist delete"

        "$mod, TAB, hyprexpo:expo, toggle"

        # Pulls all windows from unplugged monitors into current wksp (hyprsplit)
        # "$mod, G, split:grabroguewindows"

        "$mod, G, layoutmsg, promote"

        # toggle window swallowing
        "$mod_CONTROL_SHIFT, s, toggleswallow"
      ]
      ++ (
        # workspaces
        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
        builtins.concatLists (
          builtins.genList (
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
              # "$mod $mod_CONTROL, ${ws}, hy3:focustab, index, ${toString (x + 1)}"
            ]
          ) 10
        )
      );

      # e = repeat, l = ignore inhibitors
      bindel = [
        # Volume
        ",XF86AudioRaiseVolume, exec, pamixer -i 5"
        ",XF86AudioLowerVolume, exec, pamixer -d 5"

        # Brightness
        # ",XF86MonBrightnessUp, exec, brightnessctl set 5%+ &> ~/.cache/brightness.log"
        # ",XF86MonBrightnessDown, exec, brightnessctl set 5%- &> ~/.cache/brightness.log"

        # Media controls
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioStop, exec, playerctl stop"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"

        # muilti monitor stuff
        # "$mod, H, split-changemonitor prev"
        # "$mod, L, split-changemonitor next"
      ];

      bindl = [
        ",switch:on:Lid Switch,exec,${clamshell}/bin/clamshell close"
        ",switch:off:Lid Switch,exec,${clamshell}/bin/clamshell open"
        ",XF86MonBrightnessUp, global, caelestia:brightnessUp"
        ",XF86MonBrightnessDown, global, caelestia:brightnessDown"
      ];

      windowrule = [
        # Actions for windows tagged 'floating-window'
        # (Combined float, center, and size into one rule as permitted by new syntax)
        "float on, center on, size 800 600, match:tag floating-window"

        # Apply tag based on class
        "tag +floating-window, match:class (blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)"

        # Apply tag based on class AND title
        "tag +floating-window, match:class (xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus), match:title ^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)"
        "tag +floating-window, match:class (org.kde.dolphin), match:initial_title ^(Moving — Dolphin)"

        # Standalone float rule
        "float on, match:class (xdg-desktop-portal-gtk)"

        # Transparency
        "opacity 0.9 override 0.9 override, match:class (code|org.gnome.Nautilus|org.kde.dolphin)"

        # KiCad footprint chooser window size
        "match:title ^(Footprint Chooser.*), match:class kicad, match:float true, size 1411 854, center on"
      ];

      input = {
        touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
          scroll_factor = 0.5;
        };

        sensitivity = 0;
        accel_profile = "flat";
      };

      device = [
        {
          name = "img4100:00-4d49:4150-touchpad";
          sensitivity = 0;
        }
      ];

      misc = {
        on_focus_under_fullscreen = 1;
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

      debug = {
        disable_logs = true;
      };

      xwayland = {
        # X doesnt support fractional scaling
        # so force back to 0 scaling else blurry text
        force_zero_scaling = true;
      };

      gesture = [
        "3, horizontal, workspace"
      ];

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
    '';
  };

  # caelestia shell systemd unit
  systemd.user.services.caelestia = {
    Unit = {
      Description = "Caelestia Shell Hyprland";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${caelestia}/bin/caelestia-shell";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}

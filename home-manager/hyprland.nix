{ inputs, pkgs, config, ... }:
{
  home.packages = with pkgs; [ swww foot grimblast playerctl dunst ];
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

  wayland.windowManager.hyprland = { 
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    # package = null; # use system hyprland
    settings = {
      "$mod" = "SUPER";

      monitor = [
        # todo: configurable
        "eDP-1,highrr,auto,1"
      ];

      env = [
        "XCURSOR_SIZE,18"
        "GDK_SCALE,1"
        "QT_SCALE_FACTOR,1.2"
        "QT_SCREEN_SCALE_FACTORS,1;1"
        "GTK_THEME,Adwaita:dark"
        "BROWSER,firefox"
        "SUDO_EDITOR,/usr/bin/nvim"
        "QT_QPA_PLATFORMTHEME,qt6ct"
        "WLR_NO_HARDWARE_CURSORS,1"

        # iGPU for hyprland unless dGPU is needed
        # "WLR_DRM_DEVICES,/dev/dri/card0:/dev/dri/card1"
        # "__EGL_VENDOR_LIBRARY_FILENAMES,/usr/share/glvnd/egl_vendor.d/50_mesa.json"
        # "__GLX_VENDOR_LIBRARY_NAME,mesa"
        # "WLR_RENDERER,vulkan"
        # "LIBVA_DRIVER_NAME,iHD"
      ];

      "exec-once" = [
        "waybar"
        # TODO: not absolute path here
        "swww init && swww img ~/NixOS/assets/wallpapers/default.jpg"

        "wl-paste -p --watch wl-copy -pc" # disable middle mouse paste
        "playerctld" # music daemon
        "dunst" # notifs
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

          # screenshot
          "$mod_SHIFT, S, exec, grimblast copy area"
          ",Print,exec, grimblast copy screen"

          # "Alt Tab"
          "ALT, Tab, cyclenext"
          "ALT, Tab, bringactivetotop"

          # Volume
          ",XF86AudioRaiseVolume, exec, pamixer -i 5"
          ",XF86AudioLowerVolume, exec, pamixer -d 5"

          # Media controls
          ",XF86AudioPlay, exec, playerctl play-pause"
          ",XF86AudioStop, exec, playerctl stop"
          ",XF86AudioNext, exec, playerctl next"
          ",XF86AudioPrev, exec, playerctl previous"

          # Brightness
          ",XF86MonBrightnessUp, exec, brightnessctl set 5%+ &> ~/.cache/brightness.log"
          ",XF86MonBrightnessDown, exec, brighnessctl set 5%- &> ~/.cache/brightness.log"

          # run dialog
          "$mod, SPACE, exec, wofi -S drun -I"
          "$mod, R, exec, wofi -S run"
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
                "$mod, ${ws}, workspace, ${toString (x + 1)}"
                "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
              ]
            )
            10)
        );

      input = {
        touchpad = {
          natural_scroll = false;
          disable_while_typing = false;
          scroll_factor = 0.2;
        };

        sensitivity = 0.6;
        accel_profile = "flat";
      };
    };
  };
}

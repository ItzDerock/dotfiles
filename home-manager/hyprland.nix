{ inputs, pkgs, ... }:
{
  home.packages = [ pkgs.swww ];
  programs.kitty.enable = true;
  programs.waybar = {
    enable = true;
  };

  wayland.windowManager.hyprland = { 
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
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
        "BROWSER,vivaldi-stable"
        "SUDO_EDITOR,/usr/bin/nvim"
        "QT_QPA_PLATFORMTHEME,qt6ct"

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

          "$mod, SPACE, exec, wofi -S drun -I"
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

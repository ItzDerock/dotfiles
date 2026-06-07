{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rockcfg.sunshine;
in {
  options.rockcfg.sunshine = {
    enable = mkEnableOption "Sunshine game streaming server";
  };

  config = mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      autoStart = false;
      openFirewall = true;
      capSysAdmin = true;
      settings = {
        output_name = "2";
      };
      applications = {
        env.PATH = "$(PATH):$(HOME)/.local/bin";
        apps = [
          {
            name = "Steam (iPad)";
            detached = [ "${pkgs.steam}/bin/steam steam://open/bigpicture" ];

    prep-cmd = [
      {
        do   = "${pkgs.hyprland}/bin/hyprctl output create headless HEADLESS-2";
        undo = "${pkgs.hyprland}/bin/hyprctl output remove HEADLESS-2";
      }
      {
        # set the headless output to the client's resolution (was `keyword monitor`)
        do   = ''${pkgs.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "HEADLESS-2", mode = "''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}", position = "auto-right", scale = 1 })' '';
        undo = ''${pkgs.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "HEADLESS-2", mode = "1920x1080@60", position = "auto-right", scale = 1 })' '';
      }
      {
        # bind workspace 10 to the headless output (was `keyword workspace ...`)
        do   = ''${pkgs.hyprland}/bin/hyprctl eval 'hl.workspace_rule({ workspace = "10", monitor = "HEADLESS-2" })' '';
        undo = "";
      }
      {
        # focus it (was the broken `dispatch workspace 10`)
        do   = ''${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.exec_raw('workspace 10')"'';
        undo = ''${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.exec_raw('workspace 1')"'';
      }
    ];

            "exclude-global-prep-cmd" = "false";
            "auto-detach" = "true";
          }
        ];
      };
    };
  };
}

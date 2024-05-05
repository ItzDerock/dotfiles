{ config, pkgs, inputs, ... }:
{
  # waybar wttr
  home.packages = with pkgs; [ 
    ((import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    }).wttrbar)
  ];

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
  "layer" = "top";
  "position" = "bottom";
  "mod" = "dock";
  "height" = 31;
  "exclusive" = true;
  "passthrough" = true;
  "gtk-layer-shell" = true;
  "reload_style_on_change" = true;
  "modules-left" = [ "custom/padd" "custom/l_end" "custom/power" "custom/cliphist" "custom/wbar" "custom/theme" "custom/wallchange" "custom/r_end" "custom/l_end" "wlr/taskbar" "custom/spotify" "custom/r_end" "" "custom/padd" ];
  "modules-center" = [ "custom/padd" "custom/l_end" "idle_inhibitor" "clock" "custom/r_end" "custom/padd" ];
  "modules-right" = [ "custom/padd" "custom/l_end" "tray" "battery" "custom/r_end" "custom/l_end" "backlight" "network" "pulseaudio" "pulseaudio#microphone" "custom/notifications" "custom/keybindhint" "custom/r_end" "custom/padd" ];
  "custom_power" = {
    "format" = "{}";
    "rotate" = 0;
    "exec" = "echo ; echo  logout";
    "on-click" = "logoutlaunch.sh 2";
    "on-click-right" = "logoutlaunch.sh 1";
    "interval" = 86400;
    "tooltip" = true;
  };
  "custom_cliphist" = {
    "format" = "{}";
    "rotate" = 0;
    "exec" = "echo ; echo 󰅇 clipboard history";
    "on-click" = "sleep 0.1 && cliphist.sh c";
    "on-click-right" = "sleep 0.1 && cliphist.sh d";
    "on-click-middle" = "sleep 0.1 && cliphist.sh w";
    "interval" = 86400;
    "tooltip" = true;
  };
 
  "custom_wbar" = {
    "format" = "{}";
    "rotate" = 0;
    "exec" = "echo ; echo  switch bar";
    "on-click" = "wbarconfgen.sh n";
    "on-click-right" = "wbarconfgen.sh p";
    "on-click-middle" = "sleep 0.1 && quickapps.sh kitty firefox spotify code dolphin";
    "interval" = 86400;
    "tooltip" = true;
  };
  "custom_theme" = {
  "format" = "{}";
  "rotate" = 0;
  "exec" = "echo ; echo 󰟡 switch theme";
  "on-click" = "themeswitch.sh -n";
  "on-click-right" = "themeswitch.sh -p";
  "on-click-middle" = "sleep 0.1 && themeselect.sh";
  "interval" = 86400;
  "tooltip" = true;
};
  "custom_wallchange" = {
  "format" = "{}";
  "rotate" = 0;
  "exec" = "echo ; echo 󰆊 switch wallpaper";
  "on-click" = "swwwallpaper.sh -n";
  "on-click-right" = "swwwallpaper.sh -p";
  "on-click-middle" = "sleep 0.1 && swwwallselect.sh";
  "interval" = 86400;
  "tooltip" = true;
};
  "wlr_taskbar" = {
  "format" = "{icon}";
  "rotate" = 0;
  "icon-size" = 18;
  "icon-theme" = "Tela-circle-dracula";
  "spacing" = 0;
  "tooltip-format" = "{title}";
  "on-click" = "activate";
  "on-click-middle" = "close";
  "ignore-list" = [ "Alacritty" ];
  "app_ids-mapping" = {
  "firefoxdeveloperedition" = "firefox-developer-edition";
};
};
  "custom_spotify" = {
  "exec" = "mediaplayer.py --player spotify";
  "format" = " {}";
  "rotate" = 0;
  "return-type" = "json";
  "on-click" = "playerctl play-pause --player spotify";
  "on-click-right" = "playerctl next --player spotify";
  "on-click-middle" = "playerctl previous --player spotify";
  "on-scroll-up" = "volumecontrol.sh -p spotify i";
  "on-scroll-down" = "volumecontrol.sh -p spotify d";
  "max-length" = 25;
  "escape" = true;
  "tooltip" = true;
};
  "idle_inhibitor" = {
  "format" = "{icon}";
  "rotate" = 0;
  "format-icons" = {
  "activated" = "󰥔";
  "deactivated" = "";
};
};
  "clock" = {
  "format" = "{:%I:%M %p}";
  "rotate" = 0;
  "format-alt" = "{:%R 󰃭 %d·%m·%y}";
  "tooltip-format" = "<tt>{calendar}</tt>";
  "calendar" = {
  "mode" = "month";
  "mode-mon-col" = 3;
  "on-scroll" = 1;
  "on-click-right" = "mode";
  "format" = {
  "months" = "<span color='#ffead3'><b>{}</b></span>";
  "weekdays" = "<span color='#ffcc66'><b>{}</b></span>";
  "today" = "<span color='#ff6699'><b>{}</b></span>";
};
};
  "actions" = {
  "on-click-right" = "mode";
  "on-click-forward" = "tz_up";
  "on-click-backward" = "tz_down";
  "on-scroll-up" = "shift_up";
  "on-scroll-down" = "shift_down";
};
};
  "tray" = {
  "icon-size" = 18;
  "rotate" = 0;
  "spacing" = 5;
};
  "battery" = {
  "states" = {
  "good" = 95;
  "warning" = 30;
  "critical" = 20;
};
  "format" = "{icon} {capacity}%";
  "rotate" = 0;
  "format-charging" = " {capacity}%";
  "format-plugged" = " {capacity}%";
  "format-alt" = "{time} {icon}";
  "format-icons" = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
};
  "backlight" = {
  "device" = "intel_backlight";
  "rotate" = 0;
  "format" = "{icon} {percent}%";
  "format-icons" = [ "" "" "" "" "" "" "" "" "" ];
  "on-scroll-up" = "brightnessctl set 1%+";
  "on-scroll-down" = "brightnessctl set 1%-";
  "min-length" = 6;
};
  "network" = {
  "tooltip" = true;
  "format-wifi" = " ";
  "rotate" = 0;
  "format-ethernet" = "󰈀 ";
  "tooltip-format" = "Network: <big><b>{essid}</b></big>
Signal strength: <b>{signaldBm}dBm ({signalStrength}%)</b>
Frequency: <b>{frequency}MHz</b>
Interface: <b>{ifname}</b>
IP: <b>{ipaddr}/{cidr}</b>
Gateway: <b>{gwaddr}</b>
Netmask: <b>{netmask}</b>";
  "format-linked" = "󰈀 {ifname} (No IP)";
  "format-disconnected" = "󰖪 ";
  "tooltip-format-disconnected" = "Disconnected";
  "format-alt" = "<span foreground='#99ffdd'> {bandwidthDownBytes}</span> <span foreground='#ffcc66'> {bandwidthUpBytes}</span>";
  "interval" = 2;
};
  "pulseaudio" = {
  "format" = "{icon} {volume}";
  "rotate" = 0;
  "format-muted" = "婢";
  "on-click" = "pavucontrol -t 3";
  "on-click-middle" = "volumecontrol.sh -o m";
  "on-scroll-up" = "volumecontrol.sh -o i";
  "on-scroll-down" = "volumecontrol.sh -o d";
  "tooltip-format" = "{icon} {desc} ";
  "scroll-step" = 5;
  "format-icons" = {
  "headphone" = "";
  "hands-free" = "";
  "headset" = "";
  "phone" = "";
  "portable" = "";
  "car" = "";
  "default" = [ "" "" "" ];
};
};
  "pulseaudio#microphone" = {
  "format" = "{format_source}";
  "rotate" = 0;
  "format-source" = "";
  "format-source-muted" = "";
  "on-click" = "pavucontrol -t 4";
  "on-click-middle" = "volumecontrol.sh -i m";
  "on-scroll-up" = "volumecontrol.sh -i i";
  "on-scroll-down" = "volumecontrol.sh -i d";
  "tooltip-format" = "{format_source} {source_desc} ";
  "scroll-step" = 5;
};
  "custom_notifications" = {
  "tooltip" = true;
  "format" = "{icon} {}";
  "rotate" = 0;
  "format-icons" = {
  "email-notification" = "<span foreground='white'><sup></sup></span>";
  "chat-notification" = "󱋊<span foreground='white'><sup></sup></span>";
  "warning-notification" = "󱨪<span foreground='yellow'><sup></sup></span>";
  "error-notification" = "󱨪<span foreground='red'><sup></sup></span>";
  "network-notification" = "󱂇<span foreground='white'><sup></sup></span>";
  "battery-notification" = "󰁺<span foreground='white'><sup></sup></span>";
  "update-notification" = "󰚰<span foreground='white'><sup></sup></span>";
  "music-notification" = "󰝚<span foreground='white'><sup></sup></span>";
  "volume-notification" = "󰕿<span foreground='white'><sup></sup></span>";
  "notification" = "<span foreground='white'><sup></sup></span>";
  "none" = "";
};
  "return-type" = "json";
  "exec-if" = "which dunstctl";
  "exec" = "notifications.py";
  "on-click" = "sleep 0.1 && dunstctl history-pop";
  "on-click-middle" = "dunstctl history-clear";
  "on-click-right" = "dunstctl close-all";
  "interval" = 1;
  "escape" = true;
};
  "custom_keybindhint" = {
  "format" = " ";
  "rotate" = 0;
  "on-click" = "keybinds_hint.sh";
};
  "custom_l_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_r_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_sl_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_sr_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_rl_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_rr_end" = {
  "format" = " ";
  "interval" = "once";
  "tooltip" = false;
};
  "custom_padd" = {
  "format" = "  ";
  "interval" = "once";
  "tooltip" = false;
};
}
;
    };

    style = ''
      @define-color bar-bg rgba(0, 0, 0, 0);

      @define-color main-bg #11111b;
      @define-color main-fg #cdd6f4;

      @define-color wb-act-bg #a6adc8;
      @define-color wb-act-fg #313244;

      @define-color wb-hvr-bg #f5c2e7;
      @define-color wb-hvr-fg #313244;

        * {
            border: none;
            border-radius: 0px;
            font-family: "JetBrainsMono Nerd Font";
            font-weight: bold;
            font-size: 10px;
            min-height: 10px;
        }


        window#waybar {
            background: @bar-bg;
        }

        tooltip {
            background: @main-bg;
            color: @main-fg;
            border-radius: 7px;
            border-width: 0px;
        }

        #workspaces button {
            box-shadow: none;
          text-shadow: none;
            padding: 0px;
            border-radius: 9px;
            margin-top: 3px;
            margin-bottom: 3px;
            margin-left: 0px;
            padding-left: 3px;
            padding-right: 3px;
            margin-right: 0px;
            color: @main-fg;
            animation: ws_normal 20s ease-in-out 1;
        }

        #workspaces button.active {
            background: @wb-act-bg;
            color: @wb-act-fg;
            margin-left: 3px;
            padding-left: 12px;
            padding-right: 12px;
            margin-right: 3px;
            animation: ws_active 20s ease-in-out 1;
            transition: all 0.4s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #workspaces button:hover {
            background: @wb-hvr-bg;
            color: @wb-hvr-fg;
            animation: ws_hover 20s ease-in-out 1;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #taskbar button {
            box-shadow: none;
          text-shadow: none;
            padding: 0px;
            border-radius: 9px;
            margin-top: 3px;
            margin-bottom: 3px;
            margin-left: 0px;
            padding-left: 3px;
            padding-right: 3px;
            margin-right: 0px;
            color: @wb-color;
            animation: tb_normal 20s ease-in-out 1;
        }

        #taskbar button.active {
            background: @wb-act-bg;
            color: @wb-act-color;
            margin-left: 3px;
            padding-left: 12px;
            padding-right: 12px;
            margin-right: 3px;
            animation: tb_active 20s ease-in-out 1;
            transition: all 0.4s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #taskbar button:hover {
            background: @wb-hvr-bg;
            color: @wb-hvr-color;
            animation: tb_hover 20s ease-in-out 1;
            transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
        }

        #tray menu * {
            min-height: 16px
        }

        #tray menu separator {
            min-height: 10px
        }

        #backlight,
        #battery,
        #bluetooth,
        #custom-cliphist,
        #clock,
        #custom-cpuinfo,
        #cpu,
        #custom-gpuinfo,
        #idle_inhibitor,
        #custom-keybindhint,
        #language,
        #memory,
        #mpris,
        #network,
        #custom-notifications,
        #custom-power,
        #pulseaudio,
        #custom-spotify,
        #taskbar,
        #custom-theme,
        #tray,
        #custom-updates,
        #custom-wallchange,
        #custom-wbar,
        #window,
        #workspaces,
        #custom-l_end,
        #custom-r_end,
        #custom-sl_end,
        #custom-sr_end,
        #custom-rl_end,
        #custom-rr_end {
            color: @main-fg;
            background: @main-bg;
            opacity: 1;
            margin: 4px 0px 4px 0px;
            padding-left: 4px;
            padding-right: 4px;
        }

        #workspaces,
        #taskbar {
            padding: 0px;
        }

        #custom-r_end {
            border-radius: 0px 21px 21px 0px;
            margin-right: 9px;
            padding-right: 3px;
        }

        #custom-l_end {
            border-radius: 21px 0px 0px 21px;
            margin-left: 9px;
            padding-left: 3px;
        }

        #custom-sr_end {
            border-radius: 0px;
            margin-right: 9px;
            padding-right: 3px;
        }

        #custom-sl_end {
            border-radius: 0px;
            margin-left: 9px;
            padding-left: 3px;
        }

        #custom-rr_end {
            border-radius: 0px 7px 7px 0px;
            margin-right: 9px;
            padding-right: 3px;
        }

        #custom-rl_end {
            border-radius: 7px 0px 0px 7px;
            margin-left: 9px;
            padding-left: 3px;
        }
    '';
  };
}

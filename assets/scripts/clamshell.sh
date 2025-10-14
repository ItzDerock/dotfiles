#!/usr/bin/env bash

# disables laptop monitor in clamshell mode (lid closed)
# depends on jq and hyprctl

# --- CONFIGURATION ---
INTERNAL_MONITOR="eDP-1"
MONITOR_CONFIG_FILE="$HOME/.config/hypr/monitors.conf"
# --- END CONFIGURATION ---

# Find the line for the internal monitor in the config file and extract the settings
# e.g., extracts "eDP-1,2880x1800@120.0,0x0,1.2,bitdepth,10" from "monitor=eDP-1,..."
INTERNAL_MONITOR_ON_STATE=$(grep "^monitor=${INTERNAL_MONITOR}," "$MONITOR_CONFIG_FILE" | cut -d '=' -f 2-)

if [ -z "$INTERNAL_MONITOR_ON_STATE" ]; then
    echo "Could not find config for '$INTERNAL_MONITOR' in '$MONITOR_CONFIG_FILE'. Exiting."
    exit 1
fi

EXTERNAL_MONITORS=$(hyprctl monitors -j \
  | jq --arg INTERNAL_MONITOR "$INTERNAL_MONITOR" '[.[] | select(.name != $INTERNAL_MONITOR)] | length')

# If an external monitor is connected, apply clamshell logic
if [ "$EXTERNAL_MONITORS" -gt 0 ]; then
    if [ "$1" = "close" ]; then
        hyprctl keyword monitor "$INTERNAL_MONITOR, disable"
    elif [ "$1" = "open" ]; then
        hyprctl keyword monitor "$INTERNAL_MONITOR_ON_STATE"
    fi
fi

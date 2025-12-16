#!/bin/bash
# Toggle screensaver on/off - adapted from Omarchy for GNOME/Debian

STATE_FILE="$HOME/.local/state/terminal-screensaver/screensaver-off"

if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
    notify-send "Screensaver" "Screensaver enabled"
else
    mkdir -p "$(dirname "$STATE_FILE")"
    touch "$STATE_FILE"
    notify-send "Screensaver" "Screensaver disabled"
fi

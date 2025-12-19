#!/bin/bash
# Toggle screensaver on/off - adapted from Omarchy for GNOME/Debian

STATE_FILE="$HOME/.local/state/terminal-screensaver/screensaver-off"

notify() {
    if command -v notify-send &>/dev/null; then
        notify-send "Screensaver" "$1"
    else
        echo "$1"
    fi
}

if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
    notify "Screensaver enabled"
else
    mkdir -p "$(dirname "$STATE_FILE")"
    touch "$STATE_FILE"
    notify "Screensaver disabled"
fi

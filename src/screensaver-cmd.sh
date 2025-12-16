#!/bin/bash
# Main screensaver logic - adapted from Omarchy for GNOME/Debian

SCREENSAVER_DIR="$HOME/.local/share/terminal-screensaver"
TTE_BIN="$HOME/.local/bin/tte"

# Load configuration
source "$SCREENSAVER_DIR/screensaver.conf"

is_session_locked() {
    # Check if GNOME session is locked
    locked=$(gdbus call --session \
        --dest org.gnome.ScreenSaver \
        --object-path /org/gnome/ScreenSaver \
        --method org.gnome.ScreenSaver.GetActive 2>/dev/null | \
        grep -o 'true' || true)

    [[ -n "$locked" ]]
}

exit_screensaver() {
    log "Screensaver exiting (reason: $EXIT_REASON)"
    pkill -x tte 2>/dev/null
    printf '\033[?25h'  # show cursor
    pkill -f "class.*terminal.screensaver" 2>/dev/null
    exit 0
}

trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

# Set background to black and hide cursor
printf '\033]11;rgb:00/00/00\007'
printf '\033[?25l'

while true; do
    "$TTE_BIN" -i "$TERMINAL_SCREENSAVER_ASCII_FILE" \
        --frame-rate "$TERMINAL_SCREENSAVER_FRAME_RATE" \
        --canvas-width 0 \
        --canvas-height 0 \
        --reuse-canvas \
        --anchor-canvas c \
        --anchor-text c \
        --random-effect \
        --exclude-effects "$TERMINAL_SCREENSAVER_EXCLUDE_EFFECTS" \
        --no-eol \
        --no-restore-cursor &

    TTE_PID=$!

    while kill -0 $TTE_PID 2>/dev/null; do
        # Exit on keypress
        if read -n 1 -t 1; then
            EXIT_REASON="keypress"
            exit_screensaver
        fi
        # Exit if session gets locked
        if is_session_locked; then
            EXIT_REASON="session_locked"
            exit_screensaver
        fi
    done
done

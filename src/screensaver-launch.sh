#!/bin/bash
# Screensaver launcher for GNOME/Debian - adapted from Omarchy

SCREENSAVER_DIR="$HOME/.local/share/terminal-screensaver"
TTE_BIN="$HOME/.local/bin/tte"
STATE_FILE="$HOME/.local/state/terminal-screensaver/screensaver-off"

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: terminal-screensaver [OPTION]"
    echo ""
    echo "Terminal screensaver with ASCII art animations."
    echo ""
    echo "Options:"
    echo "  -f, --force   Launch even if screensaver is disabled"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Configuration: ~/.config/terminal-screensaver/screensaver.conf"
    echo "Logs:          ~/.local/state/terminal-screensaver/screensaver.log"
    echo ""
    echo "Related commands:"
    echo "  terminal-screensaver-toggle    Enable/disable screensaver"
    echo "  terminal-screensaver-uninstall Uninstall screensaver"
    exit 0
fi

# Load configuration
source "$SCREENSAVER_DIR/screensaver.conf"

# Exit if tte is not installed
if [[ ! -x "$TTE_BIN" ]]; then
    log "ERROR: tte not found at $TTE_BIN"
    echo "Screensaver: tte not found. Run install.sh first." >&2
    exit 1
fi

# Exit if screensaver is already running (check for terminal with our class)
if pgrep -f "class.*terminal.screensaver" >/dev/null; then
    exit 0
fi

# Check if screensaver is disabled (unless forced)
if [[ -f "$STATE_FILE" ]] && [[ "$1" != "-f" ]] && [[ "$1" != "--force" ]]; then
    exit 1
fi

log "Launching screensaver with terminal: $TERMINAL_SCREENSAVER_TERMINAL"

# Launch screensaver based on configured terminal
case "$TERMINAL_SCREENSAVER_TERMINAL" in
    alacritty)
        alacritty \
            --class terminal.screensaver \
            --title "Terminal Screensaver" \
            -o "font.size=$TERMINAL_SCREENSAVER_FONT_SIZE" \
            -o "window.padding.x=0" \
            -o "window.padding.y=0" \
            -o 'window.decorations="None"' \
            -o 'colors.primary.background="#000000"' \
            -o 'window.startup_mode="Fullscreen"' \
            -e "$SCREENSAVER_DIR/screensaver-cmd.sh" &
        ;;
    gnome-terminal)
        gnome-terminal \
            --class=terminal.screensaver \
            --title="Terminal Screensaver" \
            --full-screen \
            --hide-menubar \
            -- "$SCREENSAVER_DIR/screensaver-cmd.sh" &
        ;;
    ptyxis)
        ptyxis \
            --class=terminal.screensaver \
            --title="Terminal Screensaver" \
            -- "$SCREENSAVER_DIR/screensaver-cmd.sh" &
        ;;
esac

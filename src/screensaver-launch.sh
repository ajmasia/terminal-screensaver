#!/bin/bash
# Screensaver launcher for GNOME/Debian - adapted from Omarchy

SCREENSAVER_DIR="$HOME/.local/share/terminal-screensaver"
TTE_BIN="$HOME/.local/bin/tte"
STATE_FILE="$HOME/.local/state/terminal-screensaver/screensaver-off"

# Show version
if [[ "$1" == "-v" || "$1" == "--version" ]]; then
    version=$(cat "$SCREENSAVER_DIR/VERSION" 2>/dev/null || echo "unknown")
    echo "terminal-screensaver $version"
    exit 0
fi

# Show help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: terminal-screensaver [OPTION]"
    echo ""
    echo "Terminal screensaver with ASCII art animations."
    echo ""
    echo "Options:"
    echo "  -f, --force   Launch even if screensaver is disabled"
    echo "  -h, --help    Show this help message"
    echo "  -v, --version Show version"
    echo ""
    echo "Configuration: ~/.config/terminal-screensaver/screensaver.conf"
    echo "Logs:          ~/.local/state/terminal-screensaver/screensaver.log"
    echo ""
    echo "Related commands:"
    echo "  terminal-screensaver-toggle    Enable/disable screensaver"
    echo "  terminal-screensaver-update    Update to latest version"
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

# Exit if screensaver is already running
if pgrep -f "screensaver-multimonitor.py" >/dev/null; then
    exit 0
fi

# Check if screensaver is disabled (unless forced)
if [[ -f "$STATE_FILE" ]] && [[ "$1" != "-f" ]] && [[ "$1" != "--force" ]]; then
    exit 1
fi

log "Launching screensaver"

# Launch GTK4/VTE screensaver (auto-detects monitors)
python3 "$SCREENSAVER_DIR/screensaver-multimonitor.py" &

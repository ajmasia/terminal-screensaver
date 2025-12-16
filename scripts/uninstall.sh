#!/bin/bash
# Terminal screensaver uninstaller
set -e

INSTALL_DIR="$HOME/.local/share/terminal-screensaver"
CONFIG_DIR="$HOME/.config/terminal-screensaver"
STATE_DIR="$HOME/.local/state/terminal-screensaver"

show_help() {
    echo "Terminal Screensaver Uninstaller"
    echo ""
    echo "Usage: terminal-screensaver-uninstall [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -a, --all      Remove everything including config and logs"
    echo ""
    echo "Without options, config is preserved for reinstallation."
}

check_installation() {
    local installed=false

    # Check for any installed components
    [[ -d "$INSTALL_DIR" ]] && installed=true
    [[ -L ~/.local/bin/terminal-screensaver ]] && installed=true
    [[ -f ~/.config/autostart/terminal-screensaver-monitor.desktop ]] && installed=true

    if [[ "$installed" == "false" ]]; then
        echo "Terminal Screensaver is not installed."
        echo ""
        echo "Nothing to uninstall."
        exit 0
    fi
}

REMOVE_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            REMOVE_ALL=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if there's anything to uninstall
check_installation

echo "=== Uninstalling Terminal Screensaver ==="

# Stop idle monitor if running
echo "[1/5] Stopping running processes..."
pkill -f "idle-monitor.sh" 2>/dev/null || true
# Kill screensaver window (by window class, not by script name to avoid killing ourselves)
pkill -f "class.*terminal\.screensaver" 2>/dev/null || true

# Remove autostart
echo "[2/5] Removing autostart entry..."
rm -f ~/.config/autostart/terminal-screensaver-monitor.desktop

# Remove symlinks
echo "[3/5] Removing symlinks..."
rm -f ~/.local/bin/terminal-screensaver
rm -f ~/.local/bin/terminal-screensaver-toggle
rm -f ~/.local/bin/terminal-screensaver-uninstall
rm -f ~/.local/bin/tte

# Remove application files
echo "[4/5] Removing application files..."
rm -rf "$INSTALL_DIR"

# Remove config and state if requested
echo "[5/5] Cleaning up..."
if [[ "$REMOVE_ALL" == "true" ]]; then
    rm -rf "$CONFIG_DIR"
    rm -rf "$STATE_DIR"
    echo "  Removed config and logs"
else
    echo "  Config preserved at: $CONFIG_DIR"
    echo "  Logs preserved at: $STATE_DIR"
fi

echo ""
echo "=== Uninstallation complete ==="

if [[ "$REMOVE_ALL" != "true" ]]; then
    echo ""
    echo "To remove config and logs too, run:"
    echo "  rm -rf $CONFIG_DIR $STATE_DIR"
fi

echo ""
echo "System packages (python3, jq, curl, alacritty) were not removed."

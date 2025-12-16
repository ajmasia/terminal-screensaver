#!/bin/bash
# Slimbook EVO screensaver installer for Debian 13 + GNOME
set -e

echo "=== Installing Slimbook EVO Screensaver for Debian 13 + GNOME ==="

# Check system dependencies
echo "[1/5] Checking system dependencies..."
MISSING_PKGS=""

# Check Python 3.8+ is available
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
    if [[ $PYTHON_MAJOR -lt 3 ]] || [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -lt 8 ]]; then
        echo "  Error: Python 3.8+ required, found $PYTHON_VERSION"
        exit 1
    fi
    echo "  Python $PYTHON_VERSION found"
else
    MISSING_PKGS="$MISSING_PKGS python3-pip python3-venv"
fi
command -v jq &>/dev/null || MISSING_PKGS="$MISSING_PKGS jq"

# Check for at least one supported terminal
if ! command -v alacritty &>/dev/null && ! command -v gnome-terminal &>/dev/null && ! command -v ptyxis &>/dev/null; then
    echo "  Error: No supported terminal found (alacritty, gnome-terminal, ptyxis)"
    exit 1
fi

if [[ -n "$MISSING_PKGS" ]]; then
    echo "  Installing missing packages:$MISSING_PKGS"
    sudo apt update
    sudo apt install -y $MISSING_PKGS
else
    echo "  All dependencies installed"
fi

# Create virtual environment and install tte
echo "[2/5] Installing Terminal Text Effects (tte)..."
mkdir -p ~/.local/share/slimbook-screensaver
python3 -m venv ~/.local/share/slimbook-screensaver/venv
~/.local/share/slimbook-screensaver/venv/bin/pip install terminaltexteffects

# Create symlink for tte
mkdir -p ~/.local/bin
ln -sf ~/.local/share/slimbook-screensaver/venv/bin/tte ~/.local/bin/tte

# Copy screensaver files
echo "[3/5] Installing screensaver scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/slimbook-screensaver"

cp "$SCRIPT_DIR/screensaver.txt" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-cmd.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-launch.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-toggle.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver.conf" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/uninstall.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/screensaver-cmd.sh"
chmod +x "$INSTALL_DIR/screensaver-launch.sh"
chmod +x "$INSTALL_DIR/screensaver-toggle.sh"
chmod +x "$INSTALL_DIR/screensaver.conf"
chmod +x "$INSTALL_DIR/uninstall.sh"

# Create symlinks in ~/.local/bin
ln -sf "$INSTALL_DIR/screensaver-launch.sh" ~/.local/bin/slimbook-screensaver
ln -sf "$INSTALL_DIR/screensaver-toggle.sh" ~/.local/bin/slimbook-screensaver-toggle
ln -sf "$INSTALL_DIR/uninstall.sh" ~/.local/bin/slimbook-screensaver-uninstall

# Create default config if it doesn't exist
echo "[4/5] Creating configuration..."
CONFIG_DIR="$HOME/.config/slimbook-screensaver"
CONFIG_FILE="$CONFIG_DIR/screensaver.conf"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'CONFIG_EOF'
# Slimbook Screensaver Configuration
# Edit this file to customize your screensaver

# Terminal to use: alacritty (default), gnome-terminal, ptyxis
SLIMBOOK_SCREENSAVER_TERMINAL=alacritty

# Path to ASCII art file
# SLIMBOOK_SCREENSAVER_ASCII_FILE=$HOME/.local/share/slimbook-screensaver/screensaver.txt

# Idle timeout in seconds before screensaver activates (default: 120 = 2 min)
# SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT=120

# Animation frame rate (default: 60)
# SLIMBOOK_SCREENSAVER_FRAME_RATE=60

# Effects to exclude, comma-separated (default: dev_worm)
# SLIMBOOK_SCREENSAVER_EXCLUDE_EFFECTS=dev_worm

# Font size (default: 16)
# SLIMBOOK_SCREENSAVER_FONT_SIZE=16
CONFIG_EOF
    echo "  Created default config at $CONFIG_FILE"
else
    echo "  Config already exists at $CONFIG_FILE (preserved)"
fi

# Configure GNOME idle integration
echo "[5/5] Configuring GNOME integration..."

# Create dbus-monitor script to detect idle state
cat > "$INSTALL_DIR/idle-monitor.sh" << 'IDLE_EOF'
#!/bin/bash
# Idle monitor for GNOME - launches screensaver after inactivity

SCREENSAVER_DIR="$HOME/.local/share/slimbook-screensaver"

# Load configuration
source "$SCREENSAVER_DIR/screensaver.conf"

is_session_locked() {
    gdbus call --session \
        --dest org.gnome.ScreenSaver \
        --object-path /org/gnome/ScreenSaver \
        --method org.gnome.ScreenSaver.GetActive 2>/dev/null | \
        grep -q 'true'
}

log "Idle monitor started (timeout: ${SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT}s)"

while true; do
    # Skip if session is locked
    if ! is_session_locked; then
        # Get idle time in milliseconds from GNOME Mutter
        idle_ms=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
            /org/gnome/Mutter/IdleMonitor/Core \
            org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
            grep uint64 | awk '{print $2}')

        idle_sec=$((idle_ms / 1000))

        if [[ $idle_sec -ge $SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT ]]; then
            # Only launch if not already running
            if ! pgrep -f "class.*slimbook.screensaver" >/dev/null; then
                "$SCREENSAVER_DIR/screensaver-launch.sh"
            fi
        fi
    fi

    sleep 5
done
IDLE_EOF

chmod +x "$INSTALL_DIR/idle-monitor.sh"

# Create autostart entry for GNOME
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/slimbook-screensaver-monitor.desktop << EOF
[Desktop Entry]
Type=Application
Name=Slimbook Screensaver Monitor
Comment=Launches screensaver after idle timeout
Exec=$INSTALL_DIR/idle-monitor.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Check if ~/.local/bin is in PATH and add if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "Adding ~/.local/bin to PATH..."

    # Add to .bashrc if it exists and doesn't already have it
    if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo "  Added to ~/.bashrc"
    fi

    # Add to .profile if it exists and doesn't already have it
    if [[ -f "$HOME/.profile" ]] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile"; then
        echo 'PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
        echo "  Added to ~/.profile"
    fi

    # Export for current session
    export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Configuration: ~/.config/slimbook-screensaver/screensaver.conf"
echo "Logs:          ~/.local/state/slimbook-screensaver/screensaver.log"
echo ""
echo "Available commands:"
echo "  slimbook-screensaver           - Launch screensaver manually"
echo "  slimbook-screensaver-toggle    - Enable/disable screensaver"
echo "  slimbook-screensaver-uninstall - Uninstall screensaver"
echo ""
echo "Supported terminals: alacritty (default), gnome-terminal, ptyxis"
echo ""
echo "The screensaver will automatically activate after idle timeout."
echo ""
echo "Restart your session or run manually:"
echo "  $INSTALL_DIR/idle-monitor.sh &"

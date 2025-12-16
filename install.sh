#!/bin/bash
# Slimbook EVO screensaver installer for Debian 13 + GNOME
set -e

echo "=== Installing Slimbook EVO Screensaver for Debian 13 + GNOME ==="

# Install system dependencies
echo "[1/5] Installing system dependencies..."
sudo apt update
sudo apt install -y \
    python3-pip \
    python3-venv \
    jq \
    libnotify-bin \
    alacritty

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

chmod +x "$INSTALL_DIR/screensaver-cmd.sh"
chmod +x "$INSTALL_DIR/screensaver-launch.sh"
chmod +x "$INSTALL_DIR/screensaver-toggle.sh"
chmod +x "$INSTALL_DIR/screensaver.conf"

# Create symlinks in ~/.local/bin
ln -sf "$INSTALL_DIR/screensaver-launch.sh" ~/.local/bin/slimbook-screensaver
ln -sf "$INSTALL_DIR/screensaver-toggle.sh" ~/.local/bin/slimbook-screensaver-toggle

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

while true; do
    # Get idle time in milliseconds from GNOME Mutter
    idle_ms=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
        /org/gnome/Mutter/IdleMonitor/Core \
        org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
        grep uint64 | awk '{print $2}')

    idle_sec=$((idle_ms / 1000))

    if [[ $idle_sec -ge $SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT ]]; then
        # Only launch if not already running
        if ! pgrep -f "slimbook.screensaver" >/dev/null; then
            "$SCREENSAVER_DIR/screensaver-launch.sh"
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

echo ""
echo "=== Installation complete ==="
echo ""
echo "Configuration file: ~/.config/slimbook-screensaver/config"
echo ""
echo "Available commands:"
echo "  slimbook-screensaver        - Launch screensaver manually"
echo "  slimbook-screensaver-toggle - Enable/disable screensaver"
echo ""
echo "Supported terminals: alacritty (default), gnome-terminal, ptyxis"
echo ""
echo "The screensaver will automatically activate after idle timeout."
echo "Edit the config file to customize behavior."
echo ""
echo "Restart your session or run manually:"
echo "  $INSTALL_DIR/idle-monitor.sh &"

#!/bin/bash
# Slimbook EVO screensaver installer for Debian 13 + GNOME
set -e

echo "=== Installing Slimbook EVO Screensaver for Debian 13 + GNOME ==="

# Install system dependencies
echo "[1/4] Installing system dependencies..."
sudo apt update
sudo apt install -y \
    python3-pip \
    python3-venv \
    jq \
    libnotify-bin \
    kitty

# Create virtual environment and install tte
echo "[2/4] Installing Terminal Text Effects (tte)..."
mkdir -p ~/.local/share/slimbook-screensaver
python3 -m venv ~/.local/share/slimbook-screensaver/venv
~/.local/share/slimbook-screensaver/venv/bin/pip install terminaltexteffects

# Create symlink for tte
mkdir -p ~/.local/bin
ln -sf ~/.local/share/slimbook-screensaver/venv/bin/tte ~/.local/bin/tte

# Copy screensaver files
echo "[3/4] Installing screensaver scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/slimbook-screensaver"

cp "$SCRIPT_DIR/screensaver.txt" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-cmd.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-launch.sh" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/screensaver-toggle.sh" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/screensaver-cmd.sh"
chmod +x "$INSTALL_DIR/screensaver-launch.sh"
chmod +x "$INSTALL_DIR/screensaver-toggle.sh"

# Create symlinks in ~/.local/bin
ln -sf "$INSTALL_DIR/screensaver-launch.sh" ~/.local/bin/slimbook-screensaver
ln -sf "$INSTALL_DIR/screensaver-toggle.sh" ~/.local/bin/slimbook-screensaver-toggle

# Configure GNOME idle integration
echo "[4/4] Configuring GNOME integration..."

# Create dbus-monitor script to detect idle state
cat > "$INSTALL_DIR/idle-monitor.sh" << 'IDLE_EOF'
#!/bin/bash
# Idle monitor for GNOME - launches screensaver after inactivity

IDLE_TIMEOUT=150  # seconds (2.5 min)
SCREENSAVER_DIR="$HOME/.local/share/slimbook-screensaver"

while true; do
    # Get idle time in milliseconds from GNOME Mutter
    idle_ms=$(dbus-send --print-reply --dest=org.gnome.Mutter.IdleMonitor \
        /org/gnome/Mutter/IdleMonitor/Core \
        org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | \
        grep uint64 | awk '{print $2}')

    idle_sec=$((idle_ms / 1000))

    if [[ $idle_sec -ge $IDLE_TIMEOUT ]]; then
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
echo "Available commands:"
echo "  slimbook-screensaver        - Launch screensaver manually"
echo "  slimbook-screensaver-toggle - Enable/disable screensaver"
echo ""
echo "The screensaver will automatically activate after 2.5 min of inactivity."
echo "To change the timeout, edit IDLE_TIMEOUT in:"
echo "  $INSTALL_DIR/idle-monitor.sh"
echo ""
echo "Restart your session or run manually:"
echo "  $INSTALL_DIR/idle-monitor.sh &"

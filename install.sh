#!/bin/bash
# Slimbook EVO screensaver installer
# Supports both local (cloned repo) and remote (download release) installation
set -e

REPO_URL="https://github.com/ajmasia/slimbook-screensaver"
INSTALL_DIR="$HOME/.local/share/slimbook-screensaver"
CONFIG_DIR="$HOME/.config/slimbook-screensaver"

# Files to install to INSTALL_DIR
INSTALL_FILES=(
    "screensaver-cmd.sh"
    "screensaver-launch.sh"
    "screensaver-toggle.sh"
    "screensaver.conf"
    "uninstall.sh"
    "VERSION"
)

# Files to install to CONFIG_DIR
CONFIG_FILES=(
    "screensaver.txt"
)

show_help() {
    echo "Slimbook EVO Screensaver Installer"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --local    Force local installation (from cloned repo)"
    echo "  -r, --remote   Force remote installation (download release)"
    echo ""
    echo "Without options, the installer auto-detects the source:"
    echo "  - If run from cloned repo: installs from local files"
    echo "  - If run standalone: downloads latest release"
}

detect_source() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check if we're in the repo with all required files
    local all_files_exist=true
    for file in "${INSTALL_FILES[@]}" "${CONFIG_FILES[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            all_files_exist=false
            break
        fi
    done

    if [[ "$all_files_exist" == "true" ]]; then
        echo "local"
    else
        echo "remote"
    fi
}

download_release() {
    echo "  Fetching latest release..."

    # Get latest release tag
    local latest_tag
    latest_tag=$(curl -fsSL "https://api.github.com/repos/ajmasia/slimbook-screensaver/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)

    if [[ -z "$latest_tag" ]]; then
        echo "  Error: Could not fetch latest release"
        exit 1
    fi

    echo "  Latest version: $latest_tag"

    # Create temp directory
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Download tarball
    local tarball_url="${REPO_URL}/archive/refs/tags/${latest_tag}.tar.gz"
    echo "  Downloading $tarball_url..."
    curl -fsSL "$tarball_url" -o "$TEMP_DIR/release.tar.gz"

    # Extract
    tar -xzf "$TEMP_DIR/release.tar.gz" -C "$TEMP_DIR"

    # Find extracted directory (format: slimbook-screensaver-X.X.X or slimbook-screensaver-vX.X.X)
    SOURCE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "slimbook-screensaver-*" | head -1)

    if [[ -z "$SOURCE_DIR" ]]; then
        echo "  Error: Could not find extracted files"
        exit 1
    fi
}

check_dependencies() {
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
    command -v curl &>/dev/null || MISSING_PKGS="$MISSING_PKGS curl"

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
}

install_tte() {
    echo "[2/5] Installing Terminal Text Effects (tte)..."
    mkdir -p "$INSTALL_DIR"
    python3 -m venv "$INSTALL_DIR/venv"
    "$INSTALL_DIR/venv/bin/pip" install --quiet terminaltexteffects

    # Create symlink for tte
    mkdir -p ~/.local/bin
    ln -sf "$INSTALL_DIR/venv/bin/tte" ~/.local/bin/tte
}

install_files() {
    echo "[3/5] Installing screensaver scripts..."

    for file in "${INSTALL_FILES[@]}"; do
        cp "$SOURCE_DIR/$file" "$INSTALL_DIR/"
    done

    chmod +x "$INSTALL_DIR/screensaver-cmd.sh"
    chmod +x "$INSTALL_DIR/screensaver-launch.sh"
    chmod +x "$INSTALL_DIR/screensaver-toggle.sh"
    chmod +x "$INSTALL_DIR/uninstall.sh"

    # Create symlinks in ~/.local/bin
    ln -sf "$INSTALL_DIR/screensaver-launch.sh" ~/.local/bin/slimbook-screensaver
    ln -sf "$INSTALL_DIR/screensaver-toggle.sh" ~/.local/bin/slimbook-screensaver-toggle
    ln -sf "$INSTALL_DIR/uninstall.sh" ~/.local/bin/slimbook-screensaver-uninstall
}

create_config() {
    echo "[4/5] Creating configuration..."
    mkdir -p "$CONFIG_DIR"

    # Copy ASCII art to config dir if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/screensaver.txt" ]]; then
        cp "$SOURCE_DIR/screensaver.txt" "$CONFIG_DIR/"
        echo "  Copied screensaver.txt to $CONFIG_DIR/"
    else
        echo "  ASCII art already exists at $CONFIG_DIR/screensaver.txt (preserved)"
    fi

    if [[ ! -f "$CONFIG_DIR/screensaver.conf" ]]; then
        cat > "$CONFIG_DIR/screensaver.conf" << 'CONFIG_EOF'
# Slimbook Screensaver Configuration
# Edit this file to customize your screensaver

# Terminal to use: alacritty (default), gnome-terminal, ptyxis
SLIMBOOK_SCREENSAVER_TERMINAL=alacritty

# Path to ASCII art file (default: ~/.config/slimbook-screensaver/screensaver.txt)
# SLIMBOOK_SCREENSAVER_ASCII_FILE=$HOME/.config/slimbook-screensaver/screensaver.txt

# Idle timeout in seconds before screensaver activates (default: 120 = 2 min)
# SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT=120

# Animation frame rate (default: 60)
# SLIMBOOK_SCREENSAVER_FRAME_RATE=60

# Effects to exclude, comma-separated (default: dev_worm)
# SLIMBOOK_SCREENSAVER_EXCLUDE_EFFECTS=dev_worm

# Font size (default: 16)
# SLIMBOOK_SCREENSAVER_FONT_SIZE=16
CONFIG_EOF
        echo "  Created default config at $CONFIG_DIR/screensaver.conf"
    else
        echo "  Config already exists at $CONFIG_DIR/screensaver.conf (preserved)"
    fi
}

configure_gnome() {
    echo "[5/5] Configuring GNOME integration..."

    # Create idle monitor script
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
}

setup_path() {
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo ""
        echo "Adding ~/.local/bin to PATH..."

        if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo "  Added to ~/.bashrc"
        fi

        if [[ -f "$HOME/.profile" ]] && ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.profile"; then
            echo 'PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
            echo "  Added to ~/.profile"
        fi

        export PATH="$HOME/.local/bin:$PATH"
    fi
}

show_complete() {
    local version
    version=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")

    echo ""
    echo "=== Installation complete (v$version) ==="
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
}

# Parse arguments
INSTALL_MODE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -l|--local)
            INSTALL_MODE="local"
            shift
            ;;
        -r|--remote)
            INSTALL_MODE="remote"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main installation
echo "=== Installing Slimbook EVO Screensaver ==="

# Determine source
if [[ -z "$INSTALL_MODE" ]]; then
    INSTALL_MODE=$(detect_source)
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$INSTALL_MODE" == "local" ]]; then
    echo "  Installing from local files..."
    SOURCE_DIR="$SCRIPT_DIR"
else
    echo "  Installing from GitHub release..."
    download_release
fi

check_dependencies
install_tte
install_files
create_config
configure_gnome
setup_path
show_complete

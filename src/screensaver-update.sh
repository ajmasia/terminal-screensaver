#!/bin/bash
# Terminal screensaver updater
set -e

INSTALL_DIR="$HOME/.local/share/terminal-screensaver"
REPO_URL="https://github.com/ajmasia/terminal-screensaver"
API_URL="https://api.github.com/repos/ajmasia/terminal-screensaver/releases/latest"

show_help() {
    echo "Terminal Screensaver Updater"
    echo ""
    echo "Usage: terminal-screensaver-update [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --check    Check for updates without installing"
    echo "  -f, --force    Force update even if already on latest version"
}

get_local_version() {
    cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "0.0.0"
}

get_remote_version() {
    curl -fsSL "$API_URL" 2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//'
}

CHECK_ONLY=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if installed
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "Terminal Screensaver is not installed."
    echo "Run the installer first."
    exit 1
fi

echo "Checking for updates..."

LOCAL_VERSION=$(get_local_version)
REMOTE_VERSION=$(get_remote_version)

if [[ -z "$REMOTE_VERSION" ]]; then
    echo "Error: Could not fetch remote version."
    exit 1
fi

echo "  Installed: v$LOCAL_VERSION"
echo "  Latest:    v$REMOTE_VERSION"

# Compare versions
if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]] && [[ "$FORCE" == "false" ]]; then
    echo ""
    echo "Already up to date."
    exit 0
fi

if [[ "$CHECK_ONLY" == "true" ]]; then
    echo ""
    echo "Update available: v$LOCAL_VERSION -> v$REMOTE_VERSION"
    echo "Run 'terminal-screensaver-update' to install."
    exit 0
fi

echo ""
echo "Updating v$LOCAL_VERSION -> v$REMOTE_VERSION..."

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download and extract
TARBALL_URL="${REPO_URL}/archive/refs/tags/v${REMOTE_VERSION}.tar.gz"
echo "  Downloading..."
curl -fsSL "$TARBALL_URL" -o "$TEMP_DIR/release.tar.gz"

echo "  Extracting..."
tar -xzf "$TEMP_DIR/release.tar.gz" -C "$TEMP_DIR"

# Find extracted directory
SOURCE_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "terminal-screensaver-*" | head -1)

if [[ -z "$SOURCE_DIR" ]]; then
    echo "Error: Could not find extracted files."
    exit 1
fi

# Update files
echo "  Installing..."
cp "$SOURCE_DIR/src/screensaver-launch.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/src/screensaver-toggle.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/src/screensaver-update.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/src/screensaver.conf" "$INSTALL_DIR/"
cp "$SOURCE_DIR/src/screensaver-multimonitor.py" "$INSTALL_DIR/"
cp "$SOURCE_DIR/scripts/uninstall.sh" "$INSTALL_DIR/"
cp "$SOURCE_DIR/VERSION" "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/screensaver-launch.sh"
chmod +x "$INSTALL_DIR/screensaver-toggle.sh"
chmod +x "$INSTALL_DIR/screensaver-update.sh"
chmod +x "$INSTALL_DIR/uninstall.sh"

# Update tte if needed
echo "  Updating tte..."
"$INSTALL_DIR/venv/bin/pip" install --quiet --upgrade terminaltexteffects

echo ""
echo "=== Update complete (v$REMOTE_VERSION) ==="

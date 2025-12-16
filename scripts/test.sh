#!/bin/bash
# Test script - run screensaver from repo without installing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check for tte (try installed version first, then project venv)
if command -v tte &>/dev/null; then
    TTE_BIN="$(command -v tte)"
elif [[ -x "$REPO_ROOT/.venv/bin/tte" ]]; then
    TTE_BIN="$REPO_ROOT/.venv/bin/tte"
else
    echo "tte not found. Install the screensaver first or run:"
    echo "  python3 -m venv $REPO_ROOT/.venv"
    echo "  $REPO_ROOT/.venv/bin/pip install terminaltexteffects"
    exit 1
fi

# Set defaults
TERMINAL_SCREENSAVER_TERMINAL="${TERMINAL_SCREENSAVER_TERMINAL:-alacritty}"
TERMINAL_SCREENSAVER_ASCII_FILE="${TERMINAL_SCREENSAVER_ASCII_FILE:-$REPO_ROOT/assets/screensaver.txt}"
TERMINAL_SCREENSAVER_FRAME_RATE="${TERMINAL_SCREENSAVER_FRAME_RATE:-60}"
TERMINAL_SCREENSAVER_EXCLUDE_EFFECTS="${TERMINAL_SCREENSAVER_EXCLUDE_EFFECTS:-dev_worm}"
TERMINAL_SCREENSAVER_FONT_SIZE="${TERMINAL_SCREENSAVER_FONT_SIZE:-16}"

# Validate terminal
case "$TERMINAL_SCREENSAVER_TERMINAL" in
    alacritty|gnome-terminal|ptyxis)
        if ! command -v "$TERMINAL_SCREENSAVER_TERMINAL" &>/dev/null; then
            echo "Warning: Terminal '$TERMINAL_SCREENSAVER_TERMINAL' not found. Using gnome-terminal." >&2
            TERMINAL_SCREENSAVER_TERMINAL="gnome-terminal"
        fi
        ;;
    *)
        echo "Warning: Invalid terminal '$TERMINAL_SCREENSAVER_TERMINAL'. Using gnome-terminal." >&2
        TERMINAL_SCREENSAVER_TERMINAL="gnome-terminal"
        ;;
esac

# Create temporary test script
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cat > "$TEST_DIR/screensaver-cmd.sh" << CMDEOF
#!/bin/bash
TTE_BIN="$TTE_BIN"
ASCII_FILE="$TERMINAL_SCREENSAVER_ASCII_FILE"
FRAME_RATE="$TERMINAL_SCREENSAVER_FRAME_RATE"
EXCLUDE_EFFECTS="$TERMINAL_SCREENSAVER_EXCLUDE_EFFECTS"

exit_screensaver() {
    pkill -x tte 2>/dev/null
    printf '\033[?25h'
    exit 0
}

trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

printf '\033]11;rgb:00/00/00\007'
printf '\033[?25l'

while true; do
    "\$TTE_BIN" -i "\$ASCII_FILE" \\
        --frame-rate "\$FRAME_RATE" \\
        --canvas-width 0 \\
        --canvas-height 0 \\
        --reuse-canvas \\
        --anchor-canvas c \\
        --anchor-text c \\
        --random-effect \\
        --exclude-effects "\$EXCLUDE_EFFECTS" \\
        --no-eol \\
        --no-restore-cursor &

    TTE_PID=\$!

    while kill -0 \$TTE_PID 2>/dev/null; do
        if read -n 1 -t 1; then
            exit_screensaver
        fi
    done
done
CMDEOF
chmod +x "$TEST_DIR/screensaver-cmd.sh"

echo "Launching test screensaver with $TERMINAL_SCREENSAVER_TERMINAL..."
echo "Press any key to exit."

# Launch based on terminal
case "$TERMINAL_SCREENSAVER_TERMINAL" in
    alacritty)
        alacritty \
            --class terminal.screensaver \
            --title "Terminal Screensaver (Test)" \
            -o "font.size=$TERMINAL_SCREENSAVER_FONT_SIZE" \
            -o "window.padding.x=0" \
            -o "window.padding.y=0" \
            -o 'window.decorations="None"' \
            -o 'colors.primary.background="#000000"' \
            -o 'window.startup_mode="Fullscreen"' \
            -e "$TEST_DIR/screensaver-cmd.sh"
        ;;
    gnome-terminal)
        gnome-terminal \
            --class=terminal.screensaver \
            --title="Terminal Screensaver (Test)" \
            --full-screen \
            --hide-menubar \
            -- "$TEST_DIR/screensaver-cmd.sh"
        ;;
    ptyxis)
        ptyxis \
            --class=terminal.screensaver \
            --title="Terminal Screensaver (Test)" \
            -- "$TEST_DIR/screensaver-cmd.sh"
        ;;
esac

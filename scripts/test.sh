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

# Check for GTK4 VTE bindings
if ! python3 -c "import gi; gi.require_version('Vte', '3.91')" 2>/dev/null; then
    echo "GTK4 VTE bindings not found. Install with:"
    echo "  sudo apt install gir1.2-vte-3.91"
    exit 1
fi

# Set defaults for testing
export TERMINAL_SCREENSAVER_ASCII_FILE="${TERMINAL_SCREENSAVER_ASCII_FILE:-$REPO_ROOT/assets/banner.txt}"
export TERMINAL_SCREENSAVER_FRAME_RATE="${TERMINAL_SCREENSAVER_FRAME_RATE:-60}"

# Create temp directory for test
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Create a modified version of the multimonitor script for testing
cat > "$TEST_DIR/screensaver-test.py" << 'PYEOF'
#!/usr/bin/env python3
"""
Test version of multimonitor screensaver.
Uses environment variables for paths.
"""

import gi
import os
import sys
import signal
import random

gi.require_version('Gtk', '4.0')
gi.require_version('Vte', '3.91')
gi.require_version('Gdk', '4.0')

from gi.repository import Gtk, Vte, Gdk, GLib, Gio

TTE_BIN = os.environ.get("TTE_BIN", os.path.expanduser("~/.local/bin/tte"))
BANNER_FILE = os.environ.get("TERMINAL_SCREENSAVER_ASCII_FILE", "")
FRAME_RATE = os.environ.get("TERMINAL_SCREENSAVER_FRAME_RATE", "60")

EFFECTS = [
    "beams", "binarypath", "blackhole", "bouncyballs", "bubbles", "burn",
    "colorshift", "crumble", "decrypt", "errorcorrect", "expand", "fireworks",
    "highlight", "laseretch", "matrix", "middleout", "orbittingvolley",
    "overflow", "pour", "print", "rain", "randomsequence", "rings", "scattered",
    "slice", "slide", "smoke", "spotlights", "spray", "swarm", "sweep",
    "synthgrid", "thunderstorm", "unstable", "vhstape", "waves", "wipe"
]


class ScreensaverWindow(Gtk.Window):
    def __init__(self, app, monitor):
        super().__init__(application=app)
        self.monitor = monitor
        self.app = app

        self.set_title("Terminal Screensaver (Test)")
        self.set_decorated(False)

        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(b"window { background-color: #000000; }")
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        self.terminal = Vte.Terminal()
        self.terminal.set_cursor_blink_mode(Vte.CursorBlinkMode.OFF)
        self.terminal.set_scroll_on_output(False)
        self.terminal.set_scrollback_lines(0)

        bg = Gdk.RGBA()
        bg.parse("#000000")
        fg = Gdk.RGBA()
        fg.parse("#FFFFFF")
        self.terminal.set_color_background(bg)
        self.terminal.set_color_foreground(fg)
        self.terminal.set_color_cursor(bg)
        self.terminal.set_color_cursor_foreground(bg)

        self.set_child(self.terminal)

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self.on_key_pressed)
        self.add_controller(key_controller)

        term_key_controller = Gtk.EventControllerKey()
        term_key_controller.connect("key-pressed", self.on_key_pressed)
        self.terminal.add_controller(term_key_controller)

        self.terminal.connect("commit", self.on_terminal_input)

        motion_controller = Gtk.EventControllerMotion()
        motion_controller.connect("motion", self.on_mouse_motion)
        self.add_controller(motion_controller)

        click_controller = Gtk.GestureClick()
        click_controller.connect("pressed", self.on_mouse_click)
        self.add_controller(click_controller)

        self.terminal.connect("child-exited", self.on_child_exited)
        self.motion_started = False

    def on_key_pressed(self, controller, keyval, keycode, state):
        self.get_application().quit()
        return True

    def on_terminal_input(self, terminal, text, size):
        self.get_application().quit()

    def on_mouse_motion(self, controller, x, y):
        if self.motion_started:
            self.get_application().quit()
        else:
            self.motion_started = True

    def on_mouse_click(self, controller, n_press, x, y):
        self.get_application().quit()

    def on_child_exited(self, terminal, status):
        self.spawn_command()

    def spawn_command(self):
        self.terminal.reset(True, True)
        self.terminal.feed(b"\033[3J\033[2J\033[H\033[?25l")

        effect = random.choice(EFFECTS)

        cmd = [
            TTE_BIN,
            "-i", BANNER_FILE,
            "--frame-rate", FRAME_RATE,
            "--canvas-width", "0",
            "--canvas-height", "0",
            "--anchor-canvas", "c",
            "--anchor-text", "c",
            "--no-eol",
            effect
        ]

        self.terminal.spawn_async(
            Vte.PtyFlags.DEFAULT,
            os.environ.get("HOME"),
            cmd,
            None,
            GLib.SpawnFlags.DEFAULT,
            None, None, -1, None, None, None
        )

    def present_fullscreen(self):
        self.present()
        self.fullscreen_on_monitor(self.monitor)


class ScreensaverApp(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="org.terminal.screensaver.test",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        self.windows = []

    def do_activate(self):
        display = Gdk.Display.get_default()
        monitors = display.get_monitors()

        for i in range(monitors.get_n_items()):
            monitor = monitors.get_item(i)
            window = ScreensaverWindow(self, monitor)
            window.present_fullscreen()
            window.spawn_command()
            self.windows.append(window)

    def do_shutdown(self):
        for window in self.windows:
            window.close()
        Gtk.Application.do_shutdown(self)


def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    app = ScreensaverApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    sys.exit(main())
PYEOF

chmod +x "$TEST_DIR/screensaver-test.py"

echo "Launching test screensaver with GTK4/VTE..."
echo "Press any key or move mouse to exit."
echo ""

# Export tte path for Python script
export TTE_BIN

python3 "$TEST_DIR/screensaver-test.py"

#!/usr/bin/env python3
"""
Terminal Screensaver AppIndicator.
System tray icon with idle monitoring and screensaver control.
"""

import gi
import os
import subprocess
import signal
import json
import urllib.request
import fcntl

gi.require_version('Gtk', '3.0')
gi.require_version('AyatanaAppIndicator3', '0.1')

from gi.repository import Gtk, GLib, AyatanaAppIndicator3

SCREENSAVER_DIR = os.path.expanduser("~/.local/share/terminal-screensaver")
CONFIG_DIR = os.path.expanduser("~/.config/terminal-screensaver")
STATE_DIR = os.path.expanduser("~/.local/state/terminal-screensaver")
CONFIG_FILE = os.path.join(CONFIG_DIR, "screensaver.conf")
STATE_FILE = os.path.join(STATE_DIR, "screensaver-off")
VERSION_FILE = os.path.join(SCREENSAVER_DIR, "VERSION")
API_URL = "https://api.github.com/repos/ajmasia/terminal-screensaver/releases/latest"

# Default values
DEFAULT_IDLE_TIMEOUT = 120
DEFAULT_FRAME_RATE = 60
UPDATE_CHECK_INTERVAL = 86400  # 24 hours in seconds


class ScreensaverIndicator:
    def __init__(self):
        self.idle_timeout = DEFAULT_IDLE_TIMEOUT
        self.update_available = None  # None = not checked, False = up to date, "x.y.z" = new version
        self.load_config()

        # Create indicator
        self.indicator = AyatanaAppIndicator3.Indicator.new(
            "terminal-screensaver",
            self.get_icon_name(),
            AyatanaAppIndicator3.IndicatorCategory.APPLICATION_STATUS
        )
        self.indicator.set_status(AyatanaAppIndicator3.IndicatorStatus.ACTIVE)

        # Build menu
        self.build_menu()

        # Start idle monitoring
        GLib.timeout_add_seconds(5, self.check_idle)

        # Check for updates on startup (after 30 seconds) and then daily
        GLib.timeout_add_seconds(30, self.check_updates_once)
        GLib.timeout_add_seconds(UPDATE_CHECK_INTERVAL, self.check_updates)

    def load_config(self):
        """Load configuration from file."""
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line.startswith('TERMINAL_SCREENSAVER_IDLE_TIMEOUT='):
                            value = line.split('=', 1)[1].strip()
                            self.idle_timeout = int(value)
            except Exception:
                pass

    def save_timeout(self, timeout):
        """Save timeout to config file."""
        self.idle_timeout = timeout

        # Read existing config
        lines = []
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE, 'r') as f:
                lines = f.readlines()

        # Update or add timeout line
        found = False
        for i, line in enumerate(lines):
            if line.strip().startswith('TERMINAL_SCREENSAVER_IDLE_TIMEOUT='):
                lines[i] = f'TERMINAL_SCREENSAVER_IDLE_TIMEOUT={timeout}\n'
                found = True
                break

        if not found:
            lines.append(f'TERMINAL_SCREENSAVER_IDLE_TIMEOUT={timeout}\n')

        # Write config
        os.makedirs(CONFIG_DIR, exist_ok=True)
        with open(CONFIG_FILE, 'w') as f:
            f.writelines(lines)

        self.notify(f"Timeout: {timeout}s")

    def get_icon_name(self):
        """Get icon based on enabled state."""
        if self.is_enabled():
            return "video-display"
        else:
            return "video-display-symbolic"

    def is_enabled(self):
        """Check if screensaver is enabled."""
        return not os.path.exists(STATE_FILE)

    def is_running(self):
        """Check if screensaver is currently running."""
        try:
            result = subprocess.run(
                ["pgrep", "-f", "screensaver-multimonitor.py"],
                capture_output=True
            )
            return result.returncode == 0
        except Exception:
            return False

    def is_session_locked(self):
        """Check if GNOME session is locked."""
        try:
            result = subprocess.run(
                ["gdbus", "call", "--session",
                 "--dest", "org.gnome.ScreenSaver",
                 "--object-path", "/org/gnome/ScreenSaver",
                 "--method", "org.gnome.ScreenSaver.GetActive"],
                capture_output=True, text=True, timeout=2
            )
            return "true" in result.stdout.lower()
        except Exception:
            return False

    def get_idle_time(self):
        """Get idle time in seconds from GNOME Mutter."""
        try:
            result = subprocess.run(
                ["dbus-send", "--print-reply",
                 "--dest=org.gnome.Mutter.IdleMonitor",
                 "/org/gnome/Mutter/IdleMonitor/Core",
                 "org.gnome.Mutter.IdleMonitor.GetIdletime"],
                capture_output=True, text=True, timeout=2
            )
            for line in result.stdout.split('\n'):
                if 'uint64' in line:
                    ms = int(line.split()[-1])
                    return ms // 1000
        except Exception:
            pass
        return 0

    def check_idle(self):
        """Check idle time and launch screensaver if needed."""
        if not self.is_enabled():
            return True

        if self.is_session_locked():
            return True

        if self.is_running():
            return True

        idle_sec = self.get_idle_time()

        if idle_sec >= self.idle_timeout:
            self.launch_screensaver()

        return True  # Continue timer

    def get_local_version(self):
        """Get locally installed version."""
        try:
            with open(VERSION_FILE, 'r') as f:
                return f.read().strip()
        except Exception:
            return "0.0.0"

    def get_remote_version(self):
        """Get latest version from GitHub."""
        try:
            req = urllib.request.Request(API_URL, headers={'User-Agent': 'terminal-screensaver'})
            with urllib.request.urlopen(req, timeout=10) as response:
                data = json.loads(response.read().decode())
                return data.get('tag_name', '').lstrip('v')
        except Exception:
            return None

    def check_updates_once(self):
        """Check for updates once (used for startup check)."""
        self.check_updates()
        return False  # Don't repeat

    def check_updates(self):
        """Check for updates and notify if available."""
        local = self.get_local_version()
        remote = self.get_remote_version()

        if remote and remote != local:
            # Simple version comparison (works for semver)
            if remote > local:
                self.update_available = remote
                self.notify(f"Update available: v{remote}")
                self.build_menu()
        else:
            self.update_available = False

        return True  # Continue timer

    def run_update(self, widget):
        """Run the update command."""
        subprocess.Popen([
            "gnome-terminal", "--",
            "bash", "-c",
            "terminal-screensaver-update; echo ''; echo 'Press Enter to close...'; read"
        ])

    def check_updates_now(self, widget):
        """Manually check for updates."""
        self.notify("Checking for updates...")
        self.check_updates()
        if not self.update_available:
            self.notify("Already up to date")

    def launch_screensaver(self):
        """Launch the screensaver."""
        script = os.path.join(SCREENSAVER_DIR, "screensaver-multimonitor.py")
        if os.path.exists(script):
            subprocess.Popen(["python3", script])

    def toggle_enabled(self, widget):
        """Toggle screensaver enabled/disabled."""
        if self.is_enabled():
            os.makedirs(STATE_DIR, exist_ok=True)
            open(STATE_FILE, 'w').close()
            self.notify("Screensaver disabled")
        else:
            if os.path.exists(STATE_FILE):
                os.remove(STATE_FILE)
            self.notify("Screensaver enabled")

        self.indicator.set_icon_full(self.get_icon_name(), "Terminal Screensaver")
        self.build_menu()

    def on_launch_now(self, widget):
        """Launch screensaver immediately."""
        self.launch_screensaver()

    def on_timeout_selected(self, widget, timeout):
        """Handle timeout selection."""
        if widget.get_active():
            self.save_timeout(timeout)
            self.build_menu()

    def notify(self, message):
        """Show desktop notification."""
        try:
            subprocess.run(
                ["notify-send", "Terminal Screensaver", message],
                capture_output=True
            )
        except Exception:
            pass

    def build_menu(self):
        """Build the indicator menu."""
        menu = Gtk.Menu()

        # Update available notification
        if self.update_available:
            update_item = Gtk.MenuItem(label=f"Update available: v{self.update_available}")
            update_item.connect("activate", self.run_update)
            menu.append(update_item)
            menu.append(Gtk.SeparatorMenuItem())

        # Status
        status = "Enabled" if self.is_enabled() else "Disabled"
        status_item = Gtk.MenuItem(label=f"Status: {status}")
        status_item.set_sensitive(False)
        menu.append(status_item)

        menu.append(Gtk.SeparatorMenuItem())

        # Toggle
        toggle_label = "Disable" if self.is_enabled() else "Enable"
        toggle_item = Gtk.MenuItem(label=toggle_label)
        toggle_item.connect("activate", self.toggle_enabled)
        menu.append(toggle_item)

        # Launch now
        launch_item = Gtk.MenuItem(label="Launch Now")
        launch_item.connect("activate", self.on_launch_now)
        menu.append(launch_item)

        menu.append(Gtk.SeparatorMenuItem())

        # Timeout submenu
        timeout_item = Gtk.MenuItem(label="Idle Timeout")
        timeout_menu = Gtk.Menu()

        timeouts = [
            (30, "30 seconds"),
            (60, "1 minute"),
            (120, "2 minutes"),
            (180, "3 minutes"),
            (300, "5 minutes"),
            (600, "10 minutes"),
        ]

        group = None
        for seconds, label in timeouts:
            radio = Gtk.RadioMenuItem(label=label, group=group)
            if group is None:
                group = radio
            radio.set_active(self.idle_timeout == seconds)
            radio.connect("toggled", self.on_timeout_selected, seconds)
            timeout_menu.append(radio)

        timeout_item.set_submenu(timeout_menu)
        menu.append(timeout_item)

        menu.append(Gtk.SeparatorMenuItem())

        # Check for updates
        check_update_item = Gtk.MenuItem(label="Check for Updates")
        check_update_item.connect("activate", self.check_updates_now)
        menu.append(check_update_item)

        # Quit
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", self.on_quit)
        menu.append(quit_item)

        menu.show_all()
        self.indicator.set_menu(menu)

    def on_quit(self, widget):
        """Quit the indicator."""
        Gtk.main_quit()

    def run(self):
        """Run the indicator."""
        Gtk.main()


LOCK_FILE = os.path.join(STATE_DIR, "indicator.lock")
lock_fd = None


def acquire_lock():
    """Try to acquire lock file using flock. Returns True if successful."""
    global lock_fd
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        lock_fd = open(LOCK_FILE, 'w')
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        lock_fd.write(str(os.getpid()))
        lock_fd.flush()
        return True
    except (IOError, OSError):
        if lock_fd:
            lock_fd.close()
            lock_fd = None
        return False


def release_lock():
    """Release lock file."""
    global lock_fd
    try:
        if lock_fd:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
            lock_fd.close()
            lock_fd = None
        if os.path.exists(LOCK_FILE):
            os.remove(LOCK_FILE)
    except Exception:
        pass


def notify(message):
    """Show desktop notification."""
    try:
        subprocess.run(
            ["notify-send", "Terminal Screensaver", message],
            capture_output=True
        )
    except Exception:
        pass


def main():
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    # Try to acquire lock
    if not acquire_lock():
        notify("Already running")
        return

    try:
        notify("Started")
        indicator = ScreensaverIndicator()
        indicator.run()
    finally:
        release_lock()


if __name__ == "__main__":
    main()

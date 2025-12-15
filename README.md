# Slimbook EVO Screensaver for Debian 13 + GNOME

A terminal-based screensaver with animated text effects, adapted from [Omarchy](https://omarchy.org) for Debian 13 with GNOME.

## Features

- ASCII art "Slimbook EVO" logo with random visual effects
- Automatic activation after 2.5 minutes of inactivity
- Manual launch and toggle commands
- Uses [Terminal Text Effects (tte)](https://github.com/ChrisBuilds/terminaltexteffects)

## Installation

```bash
cd migrations/screensaver
chmod +x install.sh
./install.sh
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `slimbook-screensaver` | Launch screensaver manually |
| `slimbook-screensaver-toggle` | Enable/disable automatic screensaver |

### Exit Screensaver

Press any key to exit the screensaver.

## Configuration

### Change Idle Timeout

Edit `~/.local/share/slimbook-screensaver/idle-monitor.sh`:

```bash
IDLE_TIMEOUT=150  # seconds (default: 2.5 min)
```

### Customize Text

Edit `~/.local/share/slimbook-screensaver/screensaver.txt` with your own ASCII art or text.

## File Structure

```
~/.local/share/slimbook-screensaver/
├── screensaver.txt       # ASCII art displayed
├── screensaver-cmd.sh    # Core screensaver logic
├── screensaver-launch.sh # Launcher script
├── screensaver-toggle.sh # Toggle on/off
├── idle-monitor.sh       # GNOME idle detection
└── venv/                 # Python venv with tte

~/.local/bin/
├── tte                        # Symlink to tte binary
├── slimbook-screensaver       # Symlink to launcher
└── slimbook-screensaver-toggle # Symlink to toggle

~/.config/autostart/
└── slimbook-screensaver-monitor.desktop  # Autostart entry
```

## Uninstall

```bash
rm -rf ~/.local/share/slimbook-screensaver
rm ~/.local/bin/slimbook-screensaver
rm ~/.local/bin/slimbook-screensaver-toggle
rm ~/.local/bin/tte
rm ~/.config/autostart/slimbook-screensaver-monitor.desktop
rm -rf ~/.local/state/slimbook-screensaver
```

## Dependencies

- `python3-pip`, `python3-venv` - For tte installation
- `kitty` - Terminal emulator (fullscreen support)
- `jq` - JSON parsing
- `libnotify-bin` - Desktop notifications

## Acknowledgments

This project is inspired by the screensaver from [Omarchy](https://github.com/basecamp/omarchy), created by David Heinemeier Hansson (DHH) and Basecamp, released under the MIT License.

The original implementation was designed for Arch Linux with Hyprland. This version has been adapted and rewritten for Debian 13 + GNOME, with modifications including:

- GNOME Mutter D-Bus integration for idle detection (replacing hypridle)
- Kitty terminal emulator support
- Standalone installation without Omarchy dependencies

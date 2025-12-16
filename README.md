# Slimbook EVO Screensaver

![Version](https://img.shields.io/badge/version-0.1.0-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Python](https://img.shields.io/badge/python-3.8%2B-yellow)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey)

Terminal-based screensaver with animated ASCII art effects for GNOME desktops. Displays the Slimbook EVO logo with random visual effects powered by [Terminal Text Effects](https://github.com/ChrisBuilds/terminaltexteffects).

**Compatibility:** Debian 13+ / Ubuntu 22.04+ with GNOME

## Installation

**Quick install:**
```bash
curl -fsSL https://raw.githubusercontent.com/ajmasia/slimbook-screensaver/main/install.sh | bash
```

**From source:**
```bash
git clone https://github.com/ajmasia/slimbook-screensaver.git
cd slimbook-screensaver
./install.sh
```

## Uninstall

```bash
slimbook-screensaver-uninstall          # Keep config
slimbook-screensaver-uninstall --all    # Remove everything
```

## Configuration

Edit `~/.config/slimbook-screensaver/screensaver.conf`:

```bash
# Terminal: alacritty (default), gnome-terminal, ptyxis
SLIMBOOK_SCREENSAVER_TERMINAL=alacritty

# Idle timeout in seconds (default: 120)
SLIMBOOK_SCREENSAVER_IDLE_TIMEOUT=120

# Animation frame rate (default: 60)
SLIMBOOK_SCREENSAVER_FRAME_RATE=60
```

Custom ASCII art: edit `~/.local/share/slimbook-screensaver/screensaver.txt`

## Usage

| Command | Description |
|---------|-------------|
| `slimbook-screensaver` | Launch manually |
| `slimbook-screensaver-toggle` | Enable/disable auto-activation |
| `slimbook-screensaver-uninstall` | Uninstall |

Press any key to exit the screensaver.

## Dependencies

- Python 3.8+
- Terminal: `alacritty`, `gnome-terminal`, or `ptyxis`
- `jq`, `curl`

## Acknowledgments

Inspired by the screensaver from [Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson (DHH) and Basecamp (MIT License).

Adapted for Debian/Ubuntu + GNOME with:
- GNOME Mutter D-Bus idle detection (replacing hypridle)
- Multi-terminal support
- Standalone installation

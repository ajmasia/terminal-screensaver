# Terminal Screensaver

![Version](https://img.shields.io/github/v/release/ajmasia/terminal-screensaver)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Python](https://img.shields.io/badge/python-3.8%2B-yellow)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey)

Terminal-based screensaver with animated ASCII art effects for GNOME desktops. Displays customizable ASCII art with random visual effects powered by [Terminal Text Effects](https://github.com/ChrisBuilds/terminaltexteffects).

**Compatibility:** Debian 13+ / Ubuntu 22.04+ with GNOME

## Demo

https://github.com/user-attachments/assets/771f8253-1c31-47d1-9825-8acc2cb5e593

## Installation

**Quick install:**
```bash
curl -fsSL https://raw.githubusercontent.com/ajmasia/terminal-screensaver/main/scripts/install.sh | bash
```

**From source:**
```bash
git clone https://github.com/ajmasia/terminal-screensaver.git
cd terminal-screensaver
./scripts/install.sh
```

## Uninstall

```bash
terminal-screensaver-uninstall          # Interactive (asks about config)
terminal-screensaver-uninstall --all    # Remove everything without asking
```

## Configuration

Edit `~/.config/terminal-screensaver/screensaver.conf`:

```bash
# Path to banner file
TERMINAL_SCREENSAVER_ASCII_FILE=$HOME/.config/terminal-screensaver/banner.txt

# Idle timeout in seconds (default: 120)
TERMINAL_SCREENSAVER_IDLE_TIMEOUT=120

# Animation frame rate (default: 60)
TERMINAL_SCREENSAVER_FRAME_RATE=60
```

### Custom Banner

Edit `~/.config/terminal-screensaver/banner.txt` with your own text or ASCII art.

**Included banners:**

| File | Description |
|------|-------------|
| `banner.txt` | Default "SCREEN SAVER" text |
| `banner_debian.txt` | Debian swirl logo |
| `banner_trixie.txt` | Debian Trixie text |

To use an included banner, copy it from the repo:
```bash
cp assets/banner_debian.txt ~/.config/terminal-screensaver/banner.txt
```

Or set a custom path in `screensaver.conf`:
```bash
TERMINAL_SCREENSAVER_ASCII_FILE=$HOME/.config/terminal-screensaver/banner_debian.txt
```

**Online generators:**
- [patorjk.com/software/taag](https://patorjk.com/software/taag/) - Text to ASCII
- [ascii-art-generator.org](https://www.ascii-art-generator.org/) - Image to ASCII
- [asciiart.eu](https://www.asciiart.eu/) - ASCII art collection

**From terminal:**
```bash
# Install generators
sudo apt install figlet toilet

# Generate ASCII art
figlet -f slant "Your Text" > ~/.config/terminal-screensaver/banner.txt
toilet -f future "Your Text" > ~/.config/terminal-screensaver/banner.txt
```

## Usage

| Command | Description |
|---------|-------------|
| `terminal-screensaver` | Launch manually |
| `terminal-screensaver -v` | Show version |
| `terminal-screensaver-toggle` | Enable/disable auto-activation |
| `terminal-screensaver-update` | Update to latest version |
| `terminal-screensaver-uninstall` | Uninstall |

Press any key or move the mouse to exit the screensaver.

## Update

Check for updates and install the latest version:

```bash
terminal-screensaver-update           # Update if new version available
terminal-screensaver-update --check   # Check only, don't install
terminal-screensaver-update --force   # Force reinstall current version
```

## Dependencies

- Python 3.8+
- GTK4 with VTE (`gir1.2-vte-3.91`)
- `jq`, `curl`, `libnotify-bin`

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for development setup and guidelines.

For release process, see [RELEASING.md](.github/RELEASING.md).

## Acknowledgments

Inspired by the screensaver from [Omarchy](https://github.com/basecamp/omarchy) by David Heinemeier Hansson (DHH) and Basecamp (MIT License).

Adapted for Debian/Ubuntu + GNOME with:
- GNOME Mutter D-Bus idle detection (replacing hypridle)
- Multimonitor support via GTK4/VTE
- Standalone installation

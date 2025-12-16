# Terminal Screensaver

![Version](https://img.shields.io/badge/version-0.3.0-blue)
![License](https://img.shields.io/badge/license-GPL--3.0-green)
![Python](https://img.shields.io/badge/python-3.8%2B-yellow)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey)

Terminal-based screensaver with animated ASCII art effects for GNOME desktops. Displays customizable ASCII art with random visual effects powered by [Terminal Text Effects](https://github.com/ChrisBuilds/terminaltexteffects).

**Compatibility:** Debian 13+ / Ubuntu 22.04+ with GNOME

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
terminal-screensaver-uninstall          # Keep config
terminal-screensaver-uninstall --all    # Remove everything
```

## Configuration

Edit `~/.config/terminal-screensaver/screensaver.conf`:

```bash
# Terminal: alacritty (default), gnome-terminal, ptyxis
TERMINAL_SCREENSAVER_TERMINAL=alacritty

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

Press any key to exit the screensaver.

## Update

Check for updates and install the latest version:

```bash
terminal-screensaver-update           # Update if new version available
terminal-screensaver-update --check   # Check only, don't install
terminal-screensaver-update --force   # Force reinstall current version
```

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

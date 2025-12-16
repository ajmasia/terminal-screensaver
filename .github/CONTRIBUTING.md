# Contributing

Thanks for your interest in contributing to Terminal Screensaver!

## Getting started

1. **Fork and clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/terminal-screensaver.git
   cd terminal-screensaver
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature
   ```

3. **Test locally**
   ```bash
   ./scripts/test.sh
   ```

## Development setup

Install dependencies for local development:

```bash
# Create virtual environment
python3 -m venv .venv
.venv/bin/pip install terminaltexteffects

# Test screensaver
./scripts/test.sh
```

## Project structure

```
terminal-screensaver/
├── assets/           # Banner files (ASCII art)
├── scripts/          # Install, uninstall, test scripts
├── src/              # Main application scripts
└── .github/          # GitHub Actions and docs
```

## Guidelines

- **Commits**: Write clear, descriptive commit messages
- **Code style**: Follow existing bash script conventions
- **Testing**: Test changes locally before submitting PR
- **Documentation**: Update README if adding features

## Pull requests

1. Create PR against `develop` branch
2. Describe changes clearly
3. Link related issues if any

## Reporting issues

- Check existing issues first
- Include system info (distro, GNOME version, terminal)
- Add steps to reproduce

## Questions?

Open an issue for questions or suggestions.

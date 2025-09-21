# dotfiles

capytan's dotfiles - Development environment configuration for macOS (Apple Silicon) and Ubuntu.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/capytan/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run setup for your platform
./macos/dotfileslink.sh      # macOS (Apple Silicon)
./ubuntu/dotfileslink.sh      # Ubuntu

# Install dependencies (macOS)
brew bundle --file=Brewfile

# Setup Claude custom commands (optional)
./configs/claude/setup-claude-commands.sh
```

## Repository Structure

```
.
├── macos/              # macOS (Apple Silicon) specific configs
├── macos_intel/        # macOS (Intel) specific configs (deprecated)
├── ubuntu/             # Ubuntu specific configs
├── configs/
│   ├── alacritty/     # Terminal emulator configuration
│   └── claude/        # Claude Code custom commands
├── git-utils/         # Git completion and prompt utilities
├── mise/              # Development environment manager config
├── .vscode/           # VSCode/Cursor settings
├── Brewfile           # Homebrew packages
└── init.vim           # Neovim configuration
```

## Key Aliases & Functions

- Git shortcuts: `g` (git), `gb` (branch), `gs` (switch), `gd` (diff), `gst` (status)
- FZF functions: `fbr` (interactive branch switch), `fa` (interactive file staging)
- Directory navigation: Smart aliases for common directories

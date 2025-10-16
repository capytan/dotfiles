# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Ubuntu systems. It contains configuration files for various development tools, shell environments, and system settings.

## Common Commands

### Initial Setup
```bash
# Clone repository to home directory
git clone https://github.com/capytan/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Setup dotfiles links (choose your platform)
./macos/dotfileslink.sh      # macOS (Apple Silicon)
./macos_intel/dotfileslink.sh # macOS (Intel) - deprecated
./ubuntu/dotfileslink.sh      # Ubuntu
./dotfileslink.sh            # Generic link script

# Install dependencies (macOS)
brew bundle --file=Brewfile

# Setup Claude custom commands
./configs/claude/setup-claude-commands.sh
```

### Verify Setup
```bash
# Check if links are created correctly
ls -la ~ | grep "^l.*dotfiles"

# Verify zsh configuration loaded
echo $SHELL  # Should show /bin/zsh or similar
source ~/.zshrc  # Reload shell configuration

# Test git aliases are working
g status  # Should run git status
```

### Update Dependencies
```bash
# Update Homebrew packages
brew update && brew upgrade

# Update mise/asdf tools
mise upgrade
```

## Repository Architecture

The repository follows a platform-specific organization:

- **Platform-specific directories**: `macos/`, `macos_intel/`, `ubuntu/` - contain OS-specific configurations and link scripts
- **Configuration files**: Root directory contains common dotfiles (.zshrc, .tmux.conf, .zprofile, init.vim, etc.)
- **Tool configurations**:
  - `configs/alacritty/` - Alacritty terminal configuration with shared settings and fonts
  - `configs/claude/` - Claude Code custom commands (commit, switch, security-review)
  - `.vscode/` - VSCode/Cursor settings and extensions
  - `mise/` - mise (development environment manager) configuration
- **Git utilities**: `git-utils/` - Contains git completion and prompt scripts
- **Package management**: `Brewfile` - Homebrew packages for macOS

## Key Configurations

### Shell Environment
- Primary shell: zsh with custom prompt showing git status
- Key aliases configured in .zshrc:
  - Git shortcuts (g, gb, gs, gd, gst, etc.)
  - FZF functions for interactive git branch switching (fbr, fbrm)
  - Interactive file staging with fzf (fa)

### Editor
- Primary editor: vim/neovim (configuration in init.vim)
- VSCode/Cursor with vim extension and specific formatting settings

### Development Tools
- Version management: mise, jenv, direnv
- Language support: Python, Ruby, Go, Java, Node.js
- Container tools: Docker, Kubernetes (kind)
- Infrastructure: Terraform, AWS Copilot CLI

## Claude Custom Commands

Two custom commands are available in `configs/claude/commands/`:
1. **commit**: Analyzes staged changes and creates a Conventional Commits formatted commit message
2. **switch**: Analyzes current changes and creates an appropriately named feature branch

Setup and usage:
```bash
# Setup commands (creates symlinks in ~/.claude/commands/ and settings.json in ~/.claude/config/)
./configs/claude/setup-claude-commands.sh

# Usage in Claude Code
/commit  # Create conventional commit
/switch  # Create feature branch
```

Claude settings are configured in `configs/claude/settings.json` (symlinked to `~/.claude/config/settings.json`)

## Important Guidelines

### When modifying this repository:
- Respect the platform-specific directory structure
- Maintain consistency with existing shell aliases and functions
- Update the appropriate dotfileslink.sh script when adding new configuration files
- Test link scripts on the target platform before committing
- Preserve file permissions (especially for executable scripts)

### Cursor AI Rules
This repository includes Cursor AI rules in `.cursor/rules/`:
- **global.mdc**: Contains Japanese instructions for task analysis, implementation, and quality control
- **zunda.mdc**: Defines character speaking style (Zundamon)

Key points from global rules:
- Never change technology stack versions without approval
- Avoid duplicate implementations
- No UI/UX design changes without approval
- Follow existing directory structure and naming conventions

## Troubleshooting

### Common Issues
```bash
# If dotfiles links are broken
ls -la ~ | grep "dotfiles"  # Check existing links
rm ~/.zshrc ~/.tmux.conf    # Remove broken links if needed
./dotfileslink.sh           # Re-run setup

# If shell aliases not working
source ~/.zshrc             # Reload configuration
which g                     # Check if alias exists
type g                      # Show alias definition

# If mise/asdf commands not found
export PATH="$HOME/.local/share/mise/shims:$PATH"
mise doctor                 # Check mise installation
```

## File Locations
- Shell configs: `~/.zshrc`, `~/.zprofile` (symlinked from repo)
- Neovim config: `~/.config/nvim/init.vim` (symlinked)
- VSCode settings: `~/Library/Application Support/Code/User/settings.json` (macOS)
- Claude commands: `~/.claude/commands/` (symlinked)
- Alacritty config: Platform-specific in `configs/alacritty/`

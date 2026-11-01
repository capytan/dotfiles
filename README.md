# dotfiles

Personal development environment configuration for macOS (Apple Silicon) and Ubuntu.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/capytan/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer (auto-detects platform)
./install.sh

# Apply macOS system preferences (optional)
source platform/macos/defaults.sh
```

## Repository Structure

```
dotfiles/
├── configs/              # Application configs (XDG-oriented)
│   ├── alacritty/       # Terminal emulator configuration
│   ├── claude/          # Claude Code custom commands & settings, default PR/issue templates
│   ├── cursor/          # Cursor IDE rules and settings
│   ├── ghostty/         # Ghostty terminal config
│   ├── git/             # Git config, ignore, completion, prompt
│   ├── herdr/           # herdr multiplexer config and tab bar scripts
│   ├── mise/            # Development environment manager config
│   ├── nvim/            # Neovim (LazyVim) config and lazy-lock.json
│   └── vscode/          # VSCode settings, VSCode/Cursor extensions
├── shell/               # Shell configuration (shared layer)
│   ├── zshrc            # Thin loader (auto-detects platform)
│   ├── zprofile         # Login shell settings
│   ├── fzf.zsh          # fzf setup (platform-aware)
│   └── zsh/             # Shared modules
│       ├── aliases.zsh        # Shell aliases
│       ├── fzf-functions.zsh  # fzf interactive functions
│       ├── git-aliases.zsh    # Git aliases (oh-my-zsh style)
│       ├── history.zsh        # History settings & shell options
│       ├── tfj.zsh            # Terraform directory jumper
│       └── tools.zsh          # mise, nvim, pnpm, gdcp
├── platform/            # Platform-specific layer
│   ├── macos/           # Brewfile, defaults.sh, zprofile, zshrc
│   └── ubuntu/          # zprofile, zshrc, alacritty config
├── archive/             # Legacy config records
├── install.sh           # Single setup entry point
└── CLAUDE.md            # AI assistant guidelines
```

## Shell Loading Order

```
~/.zprofile → shell/zprofile
  └─ platform/$DOTFILES_PLATFORM/zprofile.zsh

~/.zshrc → shell/zshrc
  ├─ shell/zsh/*.zsh (shared modules)
  ├─ shell/fzf.zsh (platform-aware fzf setup)
  ├─ platform/$DOTFILES_PLATFORM/zshrc.zsh
  └─ shell/zsh/local.zsh (if exists, gitignored)
```

`$DOTFILES_PLATFORM` is auto-detected from `uname -s` (`Darwin` → `macos`, `Linux` → `ubuntu`).

## Key Aliases & Functions

- **Git shortcuts**: `g` (git), `gb` (branch), `gsw` (switch), `gd` (diff), `gst` (status)
- **FZF functions**: `fbr` (branch switch), `fbrm` (remote branch), `fa` (git add), `fzf-src` (ghq + fzf)
- **Commit helpers**: `gdcp` (diff to Japanese commit msg), `gdcpe` (English)
- **Modern CLI**: `cat` → bat, `ls` → eza, `du` → dust, `top` → btm

## Neovim Plugin Updates

`configs/nvim/lazy-lock.json` pins every plugin to a commit. lazy.nvim only checks for updates in the background and never installs them on its own.

1. Update plugins with the `update-nvim-plugins` Claude Code skill (`configs/claude/skills/update-nvim-plugins/`). It holds back commits pushed less than 7 days ago, checks each candidate for supply-chain risks, edits `lazy-lock.json` only for the approved ones, and opens a PR
2. Inside nvim, stop at `:Lazy check` to see what is incoming. Don't use `:Lazy update`, `:Lazy sync`, or `U`/`S` in the `:Lazy` window — they jump to the latest commit or tag without those checks
3. If something breaks, revert `lazy-lock.json` and run `:Lazy restore`

## Machine-Specific Settings

For settings that differ between personal and work machines, use gitignored local files:

```bash
# Shell-level (proxy, API keys, team aliases)
cp shell/zsh/local.zsh.example shell/zsh/local.zsh
```

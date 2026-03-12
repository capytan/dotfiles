# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Ubuntu systems. It contains configuration files for various development tools, shell environments, and system settings.

## Repository Architecture

```
dotfiles/
├── configs/              # Application configs (XDG-oriented)
│   ├── alacritty/       # Terminal emulator (alacritty.toml + shared modules)
│   ├── claude/          # Claude Code (agents/, commands/, hooks/, skills/, settings.json)
│   ├── cursor/rules/    # Cursor IDE rules
│   ├── ghostty/         # Ghostty terminal config
│   ├── git/             # Git config, ignore, completion, prompt
│   ├── mise/            # mise (dev environment manager) config
│   ├── nvim/            # Neovim config (legacy vim-plug, reference only)
│   ├── tmux/            # tmux config, keybindings, startup scripts
│   ├── vim/             # Vim config (legacy, reference only)
│   ├── vscode/          # VSCode/Cursor settings and extensions
│   └── zeno/            # zeno.zsh completions and snippets
├── shell/               # Shell configuration (shared layer)
│   ├── zshrc            # Thin loader (auto-detects platform)
│   ├── zprofile         # Login shell settings
│   └── zsh/             # Numbered modules (01-options … 08-zeno)
├── platform/            # Platform-specific layer
│   ├── macos/           # Brewfile, defaults.sh, zprofile.zsh, zshrc.zsh
│   └── ubuntu/          # zprofile.zsh, zshrc.zsh, alacritty.toml
├── tasks/               # lessons.md (session learnings) + todo.md (cross-session TODO)
├── archive/             # Legacy config records
├── .editorconfig        # indent=2spaces, UTF-8, LF (Makefile はタブ)
├── install.sh           # Single setup entry point
└── CLAUDE.md
```

**Key constraint**: Shared between personal Mac and work Mac. Machine-specific settings go in gitignored local files:
- `shell/zsh/local.zsh` — Shell machine-specific settings
- `configs/tmux/tmux-start.local.sh` — tmux machine-specific window layout
- `.claude/settings.local.json` — Claude Code machine-specific settings

## Quick Start

```bash
./install.sh              # Auto-detects macOS/Ubuntu, creates symlinks
```

### Key Symlink Mappings

| Source | Destination |
|--------|------------|
| `shell/zshrc` | `~/.zshrc` |
| `shell/zprofile` | `~/.zprofile` |
| `configs/git/` | `~/.config/git/` |
| `configs/tmux/` | `~/.config/tmux/` |
| `configs/alacritty/` | `~/.config/alacritty/` |
| `configs/ghostty/` | `~/.config/ghostty/` |
| `configs/mise/` | `~/.config/mise/` |
| `configs/zeno/` | `~/.config/zeno/` |

macOS のみ: `configs/vscode/` → `~/Library/Application Support/{Cursor,Code}/User/`

### After Editing Configs

```bash
source ~/.zshrc           # Reload shell config (or open new terminal)
tmux source ~/.config/tmux/tmux.conf  # Reload tmux config (inside tmux)
```

## Claude Code Configuration

Custom agents, skills, hooks, and settings are in `configs/claude/`. Setup: `./configs/claude/setup-claude.sh`

## Claude Code Behavior

This section defines how Claude Code should operate when working in this repository.

### Core Principles

- **Verify symlinks**: Never consider a task complete without checking symlinks work (`ls -la ~ | grep "\-> .*dotfiles"`)
- **Respect layers**: `configs/` for apps, `shell/` for shared shell, `platform/` for OS-specific. Do not mix.
- **Local files are sacred**: Never commit `local.zsh`, `tmux-start.local.sh`, `settings.local.json`

### Workflow

**Plan First**: Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
If something goes sideways, stop and re-plan. Do not keep pushing forward.

**Verification**: Check symlinks and script permissions before marking work complete.

### Task Management

- Update `tasks/lessons.md` after any user correction
- Use `tasks/todo.md` for cross-session TODO items (TaskCreate はセッション内のみ)

## Important Guidelines

### When modifying this repository:
- Respect the layered structure: `configs/` for apps, `shell/` for shared shell, `platform/` for OS-specific
- Maintain consistency with existing shell aliases and functions
- Update `install.sh` when adding new configuration files that need symlinks
- Test `install.sh` on the target platform before committing
- Preserve file permissions (especially for executable scripts)

### Cursor AI Rules

See `configs/cursor/rules/global.mdc` for Cursor-specific constraints. Cursor rules are separate from Claude Code instructions and do not need to be kept in sync.

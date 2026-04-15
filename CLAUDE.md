# CLAUDE.md

## Overview

Personal dotfiles for macOS/Ubuntu, shared between personal Mac and work Mac.

Three layers — do not mix:
- `configs/` — App configs (XDG-oriented)
- `shell/` — Shared shell config (zsh modules)
- `platform/` — OS-specific overrides (macos/, ubuntu/)

## Key Rules

- **Local files are sacred**: Never commit `shell/zsh/local.zsh`, `configs/tmux/tmux-start.local.sh`, `.claude/settings.local.json`
- **Verify symlinks**: `ls -la ~ | grep "\-> .*dotfiles"` — check before marking work complete

## Commands

```bash
./install.sh                              # Setup (idempotent, creates symlinks)
source ~/.zshrc                           # Reload shell
tmux source ~/.config/tmux/tmux.conf      # Reload tmux (inside tmux)
./configs/claude/setup-claude.sh          # Setup Claude Code symlinks
```

## Non-Obvious Patterns

- `shell/zshrc` is a thin loader — add shell config to numbered modules in `shell/zsh/` (`01-options` … `08-zeno`), not to zshrc directly
- `configs/alacritty/` uses shared TOML modules (font, theme, pane) imported by per-platform config
- `configs/nvim/` and `configs/vim/` are legacy (vim-plug era) — do not modify
- `configs/tmux/tmux-start.sh` sources `tmux-start.local.sh` for machine-specific window layout
- Claude Code hooks use shared functions from `configs/claude/hooks/tmux-lib.sh`
- `configs/claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md` (global rules for all projects) — separate scope from this repo's `./CLAUDE.md`, not duplication

## Task Management

- Use `tasks/todo.md` for cross-session TODO items (TaskCreate is session-scoped only)

# CLAUDE.md

## Overview

Personal dotfiles for macOS/Ubuntu, shared between personal Mac and work Mac.

Three layers — do not mix:
- `configs/` — App configs (XDG-oriented)
- `shell/` — Shared shell config (zsh modules)
- `platform/` — OS-specific overrides (macos/, ubuntu/)

## Key Rules

- **Local files are sacred**: Never commit `shell/zsh/local.zsh`, `configs/tmux/tmux-start.local.sh`, `.claude/settings.local.json`
- **Verify symlinks**: `find -L ~ -maxdepth 1 -type l; find -L ~/.config ~/.claude -type l` — `-L` follows targets, so anything printed is *broken*. `~/.config` must be searched at full depth (`install.sh` links `.config/{git,tmux,alacritty,ghostty,mise,zed}/**`, not just its top level). Check before marking work complete; five dangling links from old repo layouts (`~/.mcp.json`, `~/.fzf.zsh`, `~/.zshrc.pre-oh-my-zsh`, `~/.config/alacritty.toml`, `~/.tmux.conf`) are known noise — anything else is a regression. `~/.tmux.conf` points at the removed `macos/` tree and is safe to delete (tmux now lives at `configs/tmux/`, linked into `~/.config/tmux/` by `install.sh:77-81`); if you delete it, drop it from this list and change the count to four.

## Commands

```bash
./install.sh                              # Setup (idempotent, creates symlinks)
source ~/.zshrc                           # Reload shell
tmux source ~/.config/tmux/tmux.conf      # Reload tmux (inside tmux)
./configs/claude/setup-claude.sh          # Setup Claude Code symlinks

bash configs/claude/hooks/test-pretooluse-validate-command.sh          # Hook validator tests (only suite in the repo)
HOOK_BASH=/bin/bash bash configs/claude/hooks/test-pretooluse-validate-command.sh   # Same, under macOS bash 3.2
```

CI (`.github/workflows/hooks-test.yml`) runs the validator suite on both bash 5 and bash 3.2, but only for same-repo PRs that touch `configs/claude/hooks/**` or the workflow file itself (fork PRs are skipped by design). Hook-adjacent changes outside that path — `configs/claude/settings.json` wiring, `setup-claude.sh`, `.claude/rules/claude-config.md` — get no CI run, so run the suite locally for those.

## Non-Obvious Patterns

- `shell/zshrc` is a thin loader — add shell config to numbered modules in `shell/zsh/`, not to zshrc directly (naming + local-file rules in `.claude/rules/shell-config.md`)
- `configs/alacritty/alacritty.toml` imports the shared modules `theme`/`font`/`font-size`/`shared`. `pane.toml` is **not** one of them — its only importer is `btop.toml`, which `install.sh` never links. `platform/ubuntu/alacritty.toml` has no `import` at all, so a change to a shared module does not reach Ubuntu
- `configs/nvim/` and `configs/vim/` are legacy (vim-plug era) — do not modify
- `configs/tmux/tmux-start.sh` sources `tmux-start.local.sh` for machine-specific window layout
- `configs/claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md` (global rules for all projects) — separate scope from this repo's `./CLAUDE.md`, not duplication
- Claude Code hook conventions live in `.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`)

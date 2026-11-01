# CLAUDE.md

## Overview

Personal dotfiles for macOS/Ubuntu, shared between personal Mac and work Mac.

Three layers — do not mix:
- `configs/` — App configs (XDG-oriented)
- `shell/` — Shared shell config (zsh modules)
- `platform/` — OS-specific overrides (macos/, ubuntu/)

## Key Rules

- **Local files are sacred**: Never commit `shell/zsh/local.zsh`, `.claude/settings.local.json`
- **Verify symlinks** before marking work complete: `find -L ~ -maxdepth 1 -type l; find -L ~/.config ~/.claude -type l`. Expected output is *empty* — `-L` follows targets, so anything printed is a broken link
  - Search `~/.config` at full depth: `install.sh` links `.config/{git,herdr,alacritty,ghostty,mise,zed}/**`, not just its top level

## Commands

```bash
./install.sh                              # Setup (idempotent, creates symlinks)
source ~/.zshrc                           # Reload shell (not from agent Bash)
zsh -i -c exit                            # Check zsh startup for errors (agent-safe)
herdr server reload-config                # Reload herdr config.toml in the running server
./configs/claude/setup-claude.sh          # Setup Claude Code symlinks

bash configs/claude/hooks/test-pretooluse-validate-command.sh          # Hook validator tests (only suite in the repo)
HOOK_BASH=/bin/bash bash configs/claude/hooks/test-pretooluse-validate-command.sh   # Same, under macOS bash 3.2
```

CI (`.github/workflows/hooks-test.yml`) runs the validator suite on bash 5 and bash 3.2, only for same-repo PRs (fork PRs are skipped by design) that touch:
- `configs/claude/hooks/**`
- `configs/claude/settings.json` — the suite checks its `Read()`/`Edit()` rules against the sensitive-path table
- the workflow file itself

Hook-adjacent changes outside those paths (`setup-claude.sh`, `.claude/rules/claude-config.md`) get no CI run — run the suite locally for those.

## Non-Obvious Patterns

- `shell/zshrc` is a thin loader — add shell config to numbered modules in `shell/zsh/`, not to zshrc directly (naming + local-file rules in `.claude/rules/shell-config.md`)
- `configs/alacritty/alacritty.toml` imports the shared modules `theme`/`font`/`font-size`/`shared`. `pane.toml` is **not** one of them — its only importer is `btop.toml`, which `install.sh` never links. `platform/ubuntu/alacritty.toml` has no `import` at all, so a change to a shared module does not reach Ubuntu
- `configs/nvim/` is the LazyVim config. `lazy-lock.json` is committed on purpose to pin plugins against supply-chain attacks; the update procedure is in README's "Neovim Plugin Updates"
- `configs/vim/` is legacy (vim-plug era) — do not modify
- `configs/herdr/config.toml` keeps herdr's default `ctrl+b` prefix by omitting `[keys]` entirely. Validate edits with `herdr config check`; the full key list is `herdr --default-config`
- `configs/claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md` (global rules for all projects) — separate scope from this repo's `./CLAUDE.md`, not duplication
- Claude Code config conventions live in `.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`); the PreToolUse validator's stripping algorithm and bypass history live in `.claude/rules/pretooluse-validator.md` (path-scoped to `configs/claude/hooks/**`, `configs/claude/settings.json`, and `.github/workflows/hooks-test.yml`)

---
paths:
  - "shell/**"
  - "platform/**"
---

# Shell Config Rules

- Keep numbered module naming in `shell/zsh/` (`01-options` … `08-zeno`) — zshrc loads `[0-9]*.zsh` in glob order, so the number is the load order; `local.zsh` is sourced last, after all modules
- New machine: copy `local.zsh.example` → `local.zsh` (never commit it — sacred-file list in root `CLAUDE.md`)
- Place platform-specific settings in `platform/{macos,ubuntu}/`

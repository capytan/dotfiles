---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- Hooks must use shared functions from `configs/claude/hooks/tmux-lib.sh`
- Keep permissions comments in settings.json (`// Git operations` etc.)
- Update `setup-claude.sh` when adding new symlink targets
- Use `set -euo pipefail` in hook scripts (except tmux hooks — guard pattern `tmux_guard || exit 0` and emoji matching conflict with `-e`/`-u`)

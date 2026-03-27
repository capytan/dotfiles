---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- hooks は `configs/claude/hooks/tmux-lib.sh` の共有関数を使う
- settings.json の permissions コメント (`// Git operations` 等) を維持する
- 新しいシンボリックリンク対象を追加したら `setup-claude.sh` も更新する
- hooks スクリプトには `set -euo pipefail` を使う

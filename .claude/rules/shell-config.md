---
paths:
  - "shell/**"
  - "platform/**"
---

# Shell Config Rules

- `shell/zsh/` のモジュールは番号付き命名 (`01-options` … `08-zeno`) を維持する
- `local.zsh`, `tmux-start.local.sh` は絶対にコミットしない
- プラットフォーム固有の設定は `platform/{macos,ubuntu}/` に配置する

#!/bin/bash
# SubagentStart hook: サブエージェント起動中アイコンを表示
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
CURRENT=$(tmux display-message -p '#W')
# ⚠️ と ✅ は保護、⏳ のみ 🤖 に更新
[[ "$CURRENT" == "⚠️"* ]] || [[ "$CURRENT" == "⚠"* ]] || [[ "$CURRENT" == "✅"* ]] && exit 0
tmux_set_status "🤖" "$(tmux_get_clean_name "$CURRENT")"

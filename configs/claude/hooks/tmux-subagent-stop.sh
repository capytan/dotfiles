#!/bin/bash
# SubagentStop hook: サブエージェント終了後に作業中アイコンへ戻す（🤖→⏳）
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
CURRENT=$(tmux display-message -p '#W')
# 🤖 のときだけ ⏳ に戻す
[[ "$CURRENT" == "🤖"* ]] || exit 0
tmux_set_status "⏳" "$(tmux_get_clean_name "$CURRENT")"

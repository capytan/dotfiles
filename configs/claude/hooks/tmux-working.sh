#!/bin/bash
# PostToolUse hook: 許可後/ツール使用後に作業中アイコンへ戻す（⚠️/❌→⏳）
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
CURRENT=$(tmux display-message -p '#W')
# ⚠️ か ❌ のときだけ ⏳ に戻す
if [[ "$CURRENT" == "⚠️"* ]] || [[ "$CURRENT" == "⚠"* ]] || [[ "$CURRENT" == "❌"* ]]; then
    tmux_set_status "⏳" "$(tmux_get_clean_name "$CURRENT")"
fi

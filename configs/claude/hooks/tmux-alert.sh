#!/bin/bash
# Notification hook: 許可待ちなどユーザーの注意が必要なときに通知
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
CURRENT=$(tmux display-message -p '#W')
# ✅ は保護（Stop後にNotificationが来るケースを考慮）
[[ "$CURRENT" == "✅"* ]] && exit 0
tmux_set_status "⚠️" "$(tmux_get_clean_name "$CURRENT")"
printf '\a'

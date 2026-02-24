#!/bin/bash
# Stop hook: Claude Code 応答完了をtmuxウィンドウ名で通知
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
tmux_set_status "✅" "$(tmux_current_clean_name)"
printf '\a'

#!/bin/bash
# StopFailure hook: API エラーや rate limit 時に tmux で警告表示
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
tmux_set_status "⚠️" "$(tmux_current_clean_name)"
printf '\a'

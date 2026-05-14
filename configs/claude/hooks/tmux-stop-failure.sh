#!/bin/bash
# StopFailure hook: API/rate limit エラー → 強制 ⚠️ + bell
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
tmux_force_set_status "⚠️" "StopFailure"
printf '\a'

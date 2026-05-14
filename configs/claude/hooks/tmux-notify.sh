#!/bin/bash
# Stop hook: 応答完了 → 強制 ✅ + bell
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
tmux_force_set_status "✅" "Stop"
printf '\a'

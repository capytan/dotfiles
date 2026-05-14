#!/bin/bash
# UserPromptSubmit hook: 新ターン開始 → 強制 ⏳
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
tmux_force_set_status "⏳" "UserPromptSubmit"

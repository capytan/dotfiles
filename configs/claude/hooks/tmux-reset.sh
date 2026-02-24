#!/bin/bash
# UserPromptSubmit hook: 作業中アイコンを表示
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
tmux_set_status "⏳" "$(tmux_current_clean_name)"

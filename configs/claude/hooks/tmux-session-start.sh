#!/bin/bash
# SessionStart hook: Claude セッション開始時にウィンドウ名を設定
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
tmux_set_status "⏳" "$(basename "$PWD")"

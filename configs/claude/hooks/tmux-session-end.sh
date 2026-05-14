#!/bin/bash
# SessionEnd hook: ウィンドウ名から emoji を剥がし、auto-rename を復元、subagent counter を削除
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
CURRENT=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN=$(tmux_get_clean_name "$CURRENT")
tmux rename-window "$CLEAN" 2>/dev/null
tmux set-window-option automatic-rename on 2>/dev/null
_tmux_log "SessionEnd" "clean" "$CURRENT" "$CLEAN"
[ -n "$CLAUDE_TMUX_SESSION_ID" ] && tmux_subagent_clear "$CLAUDE_TMUX_SESSION_ID"

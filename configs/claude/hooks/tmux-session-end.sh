#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
CURRENT=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN=$(tmux_get_clean_name "$CURRENT")
tmux set-window-option automatic-rename on \; rename-window "$CLEAN" >/dev/null 2>&1
_tmux_log "SessionEnd" "clean" "$CURRENT" "$CLEAN"
[ -n "$CLAUDE_TMUX_SESSION_ID" ] && tmux_subagent_clear "$CLAUDE_TMUX_SESSION_ID"

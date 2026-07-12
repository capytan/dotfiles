#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
CURRENT=$(tmux display-message -p '#W' 2>/dev/null)
CLEAN=$(tmux_get_clean_name "$CURRENT")
# rename-window は tmux の仕様で automatic-rename を強制 off にするため、
# 「rename → automatic-rename を on」の順にして #{b:pane_current_path} で自動追従に戻す
tmux rename-window "$CLEAN" \; set-window-option automatic-rename on >/dev/null 2>&1
_tmux_log "SessionEnd" "clean" "$CURRENT" "$CLEAN"
# 空 session_id も "default" fallback があるのでガードせず clear
tmux_subagent_clear "$CLAUDE_TMUX_SESSION_ID"

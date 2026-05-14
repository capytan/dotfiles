#!/bin/bash
# SubagentStart hook: counter +1、最初の subagent のときだけ 🤖 へ昇格
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
COUNT=$(tmux_subagent_inc "$CLAUDE_TMUX_SESSION_ID")
_tmux_log "SubagentStart" "counter_inc" "$(tmux display-message -p '#W' 2>/dev/null)" "$(tmux display-message -p '#W' 2>/dev/null)" "count=$COUNT"
if [ "$COUNT" = "1" ]; then
    tmux_set_status_if_priority_allows "🤖" "SubagentStart"
fi

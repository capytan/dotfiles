#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
COUNT=$(tmux_subagent_inc "$CLAUDE_TMUX_SESSION_ID")
WIN=$(tmux display-message -p '#W' 2>/dev/null)
_tmux_log "SubagentStart" "counter_inc" "$WIN" "$WIN" "count=$COUNT"
[ "$COUNT" = "1" ] && tmux_set_status_if_priority_allows "🤖" "SubagentStart"

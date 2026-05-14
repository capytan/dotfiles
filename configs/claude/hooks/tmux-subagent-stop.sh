#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
COUNT=$(tmux_subagent_dec "$CLAUDE_TMUX_SESSION_ID")
WIN=$(tmux display-message -p '#W' 2>/dev/null)
_tmux_log "SubagentStop" "counter_dec" "$WIN" "$WIN" "count=$COUNT"
[ "$COUNT" = "0" ] && tmux_demote_status "🤖" "⏳" "SubagentStop"

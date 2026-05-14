#!/bin/bash
# SubagentStop hook: counter -1、全 subagent 終了したときだけ 🤖→⏳ に降格
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
COUNT=$(tmux_subagent_dec "$CLAUDE_TMUX_SESSION_ID")
_tmux_log "SubagentStop" "counter_dec" "$(tmux display-message -p '#W' 2>/dev/null)" "$(tmux display-message -p '#W' 2>/dev/null)" "count=$COUNT"
if [ "$COUNT" = "0" ]; then
    tmux_demote_status "🤖" "⏳" "SubagentStop"
fi

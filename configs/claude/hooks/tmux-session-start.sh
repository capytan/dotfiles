#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
tmux_force_set_status "⏳" "SessionStart" "$(basename "$PWD")"
[ -n "$CLAUDE_TMUX_SESSION_ID" ] && tmux_subagent_reset "$CLAUDE_TMUX_SESSION_ID"

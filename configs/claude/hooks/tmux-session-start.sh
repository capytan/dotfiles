#!/bin/bash
# SessionStart hook: 開始時に ⏳ + ディレクトリ名で初期化、subagent counter リセット
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
tmux_force_set_status "⏳" "SessionStart" "$(basename "$PWD")"
[ -n "$CLAUDE_TMUX_SESSION_ID" ] && tmux_subagent_reset "$CLAUDE_TMUX_SESSION_ID"

#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
tmux_force_set_status "✅" "Stop"
printf '\a'
# Stop 時点で subagent は全て終わっているはず。SubagentStop 未発火などで
# counter がリークしていると次のターン以降で 🤖 が付かなくなるため明示的に 0 に戻す
# (空 session_id は "default" にフォールバック)
tmux_subagent_reset "$CLAUDE_TMUX_SESSION_ID"

#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
# permission 承認 / tool 失敗からの回復を反映するため ⚠️/❌ からは降格させる
tmux_set_status_or_demote_alert "⏳" "PostToolUse"

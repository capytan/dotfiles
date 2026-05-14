#!/bin/bash
# PostToolUse hook: ツール成功 → 優先度ガード ⏳（⚠️/❌ 中は維持、✅/🤖 中も維持）
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
tmux_set_status_if_priority_allows "⏳" "PostToolUse"

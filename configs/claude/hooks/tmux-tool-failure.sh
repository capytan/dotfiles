#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
tmux_set_status_if_priority_allows "❌" "PostToolUseFailure"

#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
tmux_force_set_status "✅" "Stop"
printf '\a'

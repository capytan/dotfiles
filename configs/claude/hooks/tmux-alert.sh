#!/bin/bash
# matcher 名は settings.json から第1引数で受け取る
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
MATCHER="${1:-unknown}"
tmux_set_status_if_priority_allows "⚠️" "Notification:$MATCHER"
# permission_prompt / idle_prompt / elicitation_dialog はいずれもユーザー入力待ち — bell で促す
printf '\a'

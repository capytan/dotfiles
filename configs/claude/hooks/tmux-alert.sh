#!/bin/bash
# Notification hook: matcher 別の警告表示
# settings.json から matcher 名を引数で受け取る（permission_prompt / idle_prompt / elicitation_dialog）
# bell は permission_prompt のみ
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
_tmux_init_session "$(cat)"
MATCHER="${1:-unknown}"
tmux_set_status_if_priority_allows "⚠️" "Notification:$MATCHER"
if [ "$MATCHER" = "permission_prompt" ]; then
    printf '\a'
fi

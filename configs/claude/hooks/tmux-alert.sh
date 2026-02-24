#!/bin/bash
# Notification hook: 許可待ちなどユーザーの注意が必要なときに通知
if [ -n "$TMUX" ]; then
  tmux set-window-option automatic-rename off
  CURRENT_WIN=$(tmux display-message -p '#W')
  # 既に✅ 完了マークがあれば上書きしない（Stop後にNotificationが来るケースを考慮）
  if [[ "$CURRENT_WIN" != "✅"* ]]; then
    CLEAN_WIN="${CURRENT_WIN#⚠️ }"
    tmux rename-window "⚠️ ${CLEAN_WIN}"
    printf '\a'
  fi
fi

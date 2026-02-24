#!/bin/bash
# Stop hook: Claude Code 応答完了をtmuxウィンドウ名で通知
if [ -n "$TMUX" ]; then
  tmux set-window-option automatic-rename off
  CURRENT_WIN=$(tmux display-message -p '#W')
  # 既にマーク済みなら上書き（⚠️→✅ への更新も含む）
  CLEAN_WIN="${CURRENT_WIN#✅ }"
  CLEAN_WIN="${CLEAN_WIN#⚠️ }"
  tmux rename-window "✅ ${CLEAN_WIN}"
  printf '\a'
fi

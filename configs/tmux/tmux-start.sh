#!/bin/bash
SESSION="main"

# 既存セッションがあればそのままアタッチして終了（再構成しない）
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

# 新規セッション作成（デタッチ状態でウィンドウを構成してからアタッチ）
tmux new-session -d -s "$SESSION" -n "home" -c "$HOME"

# ローカル設定があれば source（追加ウィンドウを注入できる）
LOCAL_SCRIPT="$HOME/dotfiles/configs/tmux/tmux-start.local.sh"
if [ -f "$LOCAL_SCRIPT" ]; then
  export SESSION
  source "$LOCAL_SCRIPT" || true
fi

tmux select-window -t "$SESSION:home"
exec tmux attach-session -t "$SESSION"

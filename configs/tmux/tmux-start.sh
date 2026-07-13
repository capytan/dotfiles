#!/bin/bash
SESSION="main"

# 既存セッションがあればそのままアタッチして終了（再構成しない）
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach-session -t "$SESSION"
fi

# 新規セッション作成（デタッチ状態でウィンドウを構成してからアタッチ）
tmux new-session -d -s "$SESSION" -n "home" -c "$HOME"

# ローカル設定があれば source（追加ウィンドウを注入できる）
# このスクリプトは ~/.config/tmux/ に symlink されるため、symlink を辿って実体
# (dotfiles 内) を解決し、隣の local script を探す。dotfiles の clone 先が
# ~/dotfiles 以外でも壊れないようにする (macOS の readlink は -f 非対応)
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
while [ -L "$SCRIPT_PATH" ]; do
  link=$(readlink "$SCRIPT_PATH")
  case "$link" in
    /*) SCRIPT_PATH="$link" ;;
    *)  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")/$link" ;;
  esac
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
LOCAL_SCRIPT="$SCRIPT_DIR/tmux-start.local.sh"
if [ -f "$LOCAL_SCRIPT" ]; then
  export SESSION
  source "$LOCAL_SCRIPT" || true
fi

tmux select-window -t "$SESSION:home"
exec tmux attach-session -t "$SESSION"

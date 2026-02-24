#!/bin/bash
# SessionEnd hook: セッション終了時にウィンドウ名をクリーンアップ
source "$(dirname "$0")/tmux-lib.sh"
tmux_guard || exit 0
CLEAN=$(tmux_current_clean_name)
tmux rename-window "$CLEAN"                     # 絵文字なしで上書き
tmux set-window-option automatic-rename on      # auto-rename を復元（format 経由でディレクトリ名が出る）

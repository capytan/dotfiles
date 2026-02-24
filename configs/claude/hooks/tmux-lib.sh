#!/bin/bash
# 全 tmux hook スクリプトが source する共通ライブラリ
# 使い方: source "$(dirname "$0")/tmux-lib.sh"

# tmux セッション外なら即座に終了（各スクリプトの先頭で使用）
tmux_guard() { [ -n "$TMUX" ]; }

# 既知の絵文字プレフィックスを除去して返す
# ⚠️ は variation selector あり/なし両方を試みる（tmux がバージョンによって落とすため）
tmux_get_clean_name() {
    local name="$1"
    name="${name#✅ }"; name="${name#⏳ }"
    name="${name#🤖 }"; name="${name#❌ }"
    name="${name#⚠️ }"  # U+26A0 + U+FE0F
    name="${name#⚠ }"   # U+26A0 のみ（tmux が variation selector を落とした場合）
    echo "$name"
}

# 現在ウィンドウのクリーン名を返す
tmux_current_clean_name() {
    tmux_get_clean_name "$(tmux display-message -p '#W')"
}

# 絵文字付きでウィンドウ名を設定する
tmux_set_status() {
    tmux set-window-option automatic-rename off
    tmux rename-window "$1 $2"
}

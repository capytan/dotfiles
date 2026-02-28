#!/bin/bash
# tmux status-right から #() で毎秒呼ばれる軽量スクリプト
# ~/.cache/claude-usage.txt を読んで Catppuccin Mocha 配色で出力する
#
# 出力例: "#[bg=#313244,fg=#cba6f7] 128K tok #[default]"
# ファイルなし or 空の場合: 無出力（tmux の見た目に影響なし）

CACHE_FILE="${HOME}/.cache/claude-usage.txt"

# ファイルが存在しない or 空なら何も出力しない
[ -f "$CACHE_FILE" ] || exit 0

# 軽量な read コマンドでファイルを読む
IFS= read -r USAGE_TEXT < "$CACHE_FILE" 2>/dev/null

# 空なら何も出力しない
[ -n "$USAGE_TEXT" ] || exit 0

# Catppuccin Mocha: Surface1 (#313244) 背景、Mauve (#cba6f7) 前景
printf '#[bg=#313244,fg=#cba6f7] %s #[default]' "$USAGE_TEXT"

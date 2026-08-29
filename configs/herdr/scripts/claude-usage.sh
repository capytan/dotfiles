#!/bin/bash
# herdr の tab_bar_right から interval_seconds ごとに呼ばれる軽量スクリプト
# ~/.cache/claude-usage.txt を読んで plain text で出力する
# (キャッシュは configs/claude/hooks/session-end-usage.sh が更新する)
#
# 出力例: "128K tok"
# ファイルなし or 空の場合: 無出力（tab bar に何も出さない）

CACHE_FILE="${HOME}/.cache/claude-usage.txt"

# ファイルが存在しない or 空なら何も出力しない
[ -f "$CACHE_FILE" ] || exit 0

# 軽量な read コマンドでファイルを読む
IFS= read -r USAGE_TEXT < "$CACHE_FILE" 2>/dev/null

# 空なら何も出力しない
[ -n "$USAGE_TEXT" ] || exit 0

printf '%s' "$USAGE_TEXT"

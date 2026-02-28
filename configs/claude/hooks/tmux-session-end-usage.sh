#!/bin/bash
# SessionEnd hook (async): 今日のトークン使用量を集計してキャッシュ更新
# tmux の有無に関わらず動作する（tmux_guard 不要）
#
# 出力先: ~/.cache/claude-usage.txt
# 出力例: "128K tok"

CACHE_FILE="${HOME}/.cache/claude-usage.txt"

# キャッシュディレクトリを作成
mkdir -p "$(dirname "$CACHE_FILE")"

# --- 方法1: ccusage CLI を使用 ---
aggregate_with_ccusage() {
    if ! command -v npx &>/dev/null; then
        return 1
    fi

    # ccusage の today 集計 (JSON 出力)
    local output
    output=$(npx --yes ccusage@latest --output-format json 2>/dev/null) || return 1

    # 今日のトークン合計を jq で取得
    local today
    today=$(date +%Y-%m-%d)
    local tokens
    tokens=$(echo "$output" | jq -r \
        --arg today "$today" \
        '[.[] | select(.date == $today)] | map(.total_tokens) | add // 0' \
        2>/dev/null) || return 1

    echo "$tokens"
}

# --- 方法2: Python3 で JSONL を直接パース（フォールバック） ---
aggregate_with_python() {
    if ! command -v python3 &>/dev/null; then
        return 1
    fi

    python3 - <<'PYEOF'
import json
import os
import glob
from datetime import date

today = date.today().isoformat()
total_tokens = 0

# ~/.claude/projects/**/*.jsonl を走査
pattern = os.path.expanduser("~/.claude/projects/**/*.jsonl")
for filepath in glob.glob(pattern, recursive=True):
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = json.loads(line)
                    # タイムスタンプが今日かチェック
                    ts = record.get("timestamp", "")
                    if not ts.startswith(today):
                        continue
                    # usage フィールドからトークン数を取得
                    usage = record.get("usage", {})
                    if isinstance(usage, dict):
                        total_tokens += usage.get("input_tokens", 0)
                        total_tokens += usage.get("output_tokens", 0)
                        total_tokens += usage.get("cache_read_input_tokens", 0)
                        total_tokens += usage.get("cache_creation_input_tokens", 0)
                except (json.JSONDecodeError, TypeError):
                    continue
    except (IOError, OSError):
        continue

print(total_tokens)
PYEOF
}

# --- トークン数をヒューマンリーダブルに変換 ---
format_tokens() {
    local tokens=$1
    if [ -z "$tokens" ] || [ "$tokens" -eq 0 ] 2>/dev/null; then
        echo "0 tok"
        return
    fi

    if [ "$tokens" -ge 1000000 ]; then
        echo "$tokens" | awk '{printf "%.1fM tok", $1/1000000}'
    elif [ "$tokens" -ge 1000 ]; then
        echo "$tokens" | awk '{printf "%dK tok", int($1/1000)}'
    else
        echo "${tokens} tok"
    fi
}

# --- メイン処理 ---
TOTAL_TOKENS=""

# ccusage を試みる
TOTAL_TOKENS=$(aggregate_with_ccusage 2>/dev/null)

# フォールバック: Python3 で JSONL パース
if [ -z "$TOTAL_TOKENS" ] || ! [[ "$TOTAL_TOKENS" =~ ^[0-9]+$ ]]; then
    TOTAL_TOKENS=$(aggregate_with_python 2>/dev/null)
fi

# 数値でなければ 0 にする
if ! [[ "$TOTAL_TOKENS" =~ ^[0-9]+$ ]]; then
    TOTAL_TOKENS=0
fi

# フォーマットしてキャッシュに保存
FORMATTED=$(format_tokens "$TOTAL_TOKENS")
echo "$FORMATTED" > "$CACHE_FILE"

#!/bin/bash
# SessionEnd hook (async): 今日のトークン使用量を集計してキャッシュ更新
# tmux の有無に関わらず動作する（tmux_guard 不要）
#
# 出力先: ~/.cache/claude-usage.txt
# 出力例: "128K tok"
# 集計対象は「ローカル日付の今日」。JSONL の timestamp は UTC(Z) なので
# Python 側でタイムゾーン変換を挟んでから比較する。

set -euo pipefail

CACHE_FILE="${HOME}/.cache/claude-usage.txt"

mkdir -p "$(dirname "$CACHE_FILE")"

# --- 方法1: ccusage CLI (daily --json) を使用 ---
# 現行 ccusage の出力は {daily: [{period, totalTokens, ...}], totals: {...}}
# period はローカル日付なので `date +%Y-%m-%d` と直接比較できる。
aggregate_with_ccusage() {
    command -v npx >/dev/null 2>&1 || return 1
    command -v jq  >/dev/null 2>&1 || return 1

    local output
    output=$(npx --yes ccusage@latest daily --json 2>/dev/null) || return 1
    [ -z "$output" ] && return 1

    local today
    today=$(date +%Y-%m-%d)

    # today エントリの有無を明示的に判定する。エントリが無い場合 (スキーマドリフトや
    # ccusage の空応答を含む) は "0" を成功扱いせず MISSING を返し、python フォール
    # バックに委ねる。today が在って 0 トークンなら正しく "0" を返す
    local tokens
    tokens=$(printf '%s' "$output" | jq -r \
        --arg today "$today" \
        '[.daily[]? | select(.period == $today)] as $t
         | if ($t | length) == 0 then "MISSING"
           else ([$t[] | .totalTokens] | add // 0) end' \
        2>/dev/null) || return 1

    [ "$tokens" = "MISSING" ] && return 1
    [[ "$tokens" =~ ^[0-9]+$ ]] || return 1
    printf '%s' "$tokens"
}

# --- 方法2: Python3 で JSONL を直接パース（フォールバック） ---
# ~/.claude/projects/**/*.jsonl を走査し、record.message.usage を合算する。
# timestamp は ISO 8601 UTC (`...Z`) なのでローカル日付に変換して比較する。
aggregate_with_python() {
    command -v python3 >/dev/null 2>&1 || return 1

    python3 - <<'PYEOF'
import json
import os
import glob
from datetime import datetime, timezone

today_local = datetime.now().date()
total_tokens = 0

def parse_ts(ts):
    if not ts:
        return None
    try:
        if ts.endswith("Z"):
            return datetime.fromisoformat(ts[:-1]).replace(tzinfo=timezone.utc)
        return datetime.fromisoformat(ts)
    except ValueError:
        return None

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
                except (json.JSONDecodeError, TypeError):
                    continue
                ts = parse_ts(record.get("timestamp", ""))
                if ts is None:
                    continue
                if ts.astimezone().date() != today_local:
                    continue
                # 実データは message.usage 配下にネストされている
                message = record.get("message") or {}
                usage = message.get("usage") if isinstance(message, dict) else None
                if not isinstance(usage, dict):
                    # 旧レイアウト保険: トップレベル usage も見る
                    usage = record.get("usage")
                if not isinstance(usage, dict):
                    continue
                total_tokens += usage.get("input_tokens", 0) or 0
                total_tokens += usage.get("output_tokens", 0) or 0
                total_tokens += usage.get("cache_read_input_tokens", 0) or 0
                total_tokens += usage.get("cache_creation_input_tokens", 0) or 0
    except (IOError, OSError):
        continue

print(total_tokens)
PYEOF
}

# --- トークン数をヒューマンリーダブルに変換 ---
# 0 は空文字を返して、reader 側 (claude-usage-status.sh) の [ -n ... ] ガードで
# status bar から usage セグメントを隠す
format_tokens() {
    awk -v t="${1:-0}" 'BEGIN {
        n = t + 0
        if (n <= 0)          { exit }
        else if (n >= 1000000) printf "%.1fM tok", n/1000000
        else if (n >= 1000)    printf "%dK tok", int(n/1000)
        else                   printf "%d tok", n
    }'
}

# --- メイン処理 ---
TOTAL_TOKENS=""

# aggregate_* は失敗を return 1 で表すフォールバック設計。set -e 下では代入文の
# 非ゼロ終了で即死するため `|| true` で受け、後続の正規表現判定で分岐させる
TOTAL_TOKENS=$(aggregate_with_ccusage 2>/dev/null) || true

if ! [[ "$TOTAL_TOKENS" =~ ^[0-9]+$ ]]; then
    TOTAL_TOKENS=$(aggregate_with_python 2>/dev/null) || true
fi

if ! [[ "$TOTAL_TOKENS" =~ ^[0-9]+$ ]]; then
    TOTAL_TOKENS=0
fi

FORMATTED=$(format_tokens "$TOTAL_TOKENS")

# atomic replace: 一時ファイルに書いてから mv。
# reader (1秒毎に読む claude-usage-status.sh) が truncate 中の空ファイルを
# 掴む race を防ぐ。
TMP_FILE="${CACHE_FILE}.tmp.$$"
printf '%s\n' "$FORMATTED" > "$TMP_FILE" && mv -f "$TMP_FILE" "$CACHE_FILE"

#!/bin/bash
# Claude Code Native Statusline スクリプト
# JSON stdin を受け取り、フォーマット済み1行を stdout に出力する
#
# 入力 JSON フィールド:
#   model.display_name          - モデル名
#   context_window.used_percentage - コンテキスト使用率 (0-100)
#   cost.total_cost_usd         - 累計コスト (USD)
#   cost.total_duration_ms      - 累計時間 (ms)
#
# 出力例: [Sonnet] ████░░░░░░ 40%  $0.12  ⏱ 3m0s

# --- Catppuccin Mocha カラー定義 ---
GREEN='\033[38;2;166;227;161m'   # #a6e3a1
YELLOW='\033[38;2;249;226;175m'  # #f9e2af
RED='\033[38;2;243;139;168m'     # #f38ba8
MAUVE='\033[38;2;203;166;247m'   # #cba6f7
TEXT='\033[38;2;205;214;244m'    # #cdd6f4
DIM='\033[38;2;127;132;156m'     # #7f849c
RESET='\033[0m'

# jq が使えるか確認
if ! command -v jq &>/dev/null; then
    echo "[Claude] (jq not found)"
    exit 0
fi

# stdin から JSON を読み込む
INPUT=$(cat)

# フィールドを jq でパース
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "unknown"' 2>/dev/null)
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
COST=$(echo "$INPUT" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0' 2>/dev/null)

# モデル名を短縮 (claude-sonnet-4-6 → Sonnet)
# macOS (BSD sed) は \u をサポートしないため awk で大文字化
MODEL_SHORT=$(echo "$MODEL" | sed 's/claude-//' | sed 's/-[0-9].*//' | \
    awk '{print toupper(substr($0,1,1)) substr($0,2)}')

# コンテキスト使用率に応じた色を設定
CTX_INT=$(echo "$CTX_PCT" | awk '{printf "%d", $1}')
if [ "$CTX_INT" -ge 80 ]; then
    CTX_COLOR="$RED"
elif [ "$CTX_INT" -ge 50 ]; then
    CTX_COLOR="$YELLOW"
else
    CTX_COLOR="$GREEN"
fi

# プログレスバーを生成 (10マス、filled + empty)
BAR_FILLED=$(echo "$CTX_PCT" | awk '{printf "%d", ($1 / 10)}')
BAR_FILLED=$(( BAR_FILLED > 10 ? 10 : BAR_FILLED ))
BAR_EMPTY=$(( 10 - BAR_FILLED ))
BAR_STR=""
for ((i=0; i<BAR_FILLED; i++)); do BAR_STR+="█"; done
for ((i=0; i<BAR_EMPTY; i++)); do BAR_STR+="░"; done

# コスト表示 ($0.12)
COST_STR=$(echo "$COST" | awk '{printf "$%.2f", $1}')

# 経過時間を mm:ss / hh:mm:ss に変換
DURATION_SEC=$(echo "$DURATION_MS" | awk '{printf "%d", $1 / 1000}')
DURATION_MIN=$(( DURATION_SEC / 60 ))
DURATION_REMAINING=$(( DURATION_SEC % 60 ))
if [ "$DURATION_MIN" -ge 60 ]; then
    DURATION_HOUR=$(( DURATION_MIN / 60 ))
    DURATION_MIN=$(( DURATION_MIN % 60 ))
    TIME_STR="${DURATION_HOUR}h${DURATION_MIN}m${DURATION_REMAINING}s"
else
    TIME_STR="${DURATION_MIN}m${DURATION_REMAINING}s"
fi

# フォーマット済み出力
printf "${MAUVE}[%s]${RESET} ${CTX_COLOR}%s %d%%${RESET}  ${DIM}%s${RESET}  ${TEXT}⏱ %s${RESET}\n" \
    "$MODEL_SHORT" "$BAR_STR" "$CTX_INT" "$COST_STR" "$TIME_STR"

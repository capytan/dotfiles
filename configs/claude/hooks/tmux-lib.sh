#!/bin/bash
# Claude Code tmux status hook 共通ライブラリ
#
# Public API:
#   _tmux_hook_init <stdin_json>                  # hook 冒頭で必ず1度呼ぶ (guard + session 初期化)
#   tmux_get_clean_name <name>
#   tmux_current_clean_name
#   tmux_force_set_status <emoji> <hook> [<base>]
#   tmux_set_status_if_priority_allows <emoji> <hook>
#   tmux_demote_status <from> <to> <hook>
#   tmux_subagent_inc <session_id>
#   tmux_subagent_dec <session_id>
#   tmux_subagent_count <session_id>
#   tmux_subagent_reset <session_id>
#   tmux_subagent_clear <session_id>
#   _tmux_log <hook> <action> <from> <to> [<extra_kv>]
#
# 環境変数:
#   CLAUDE_TMUX_LOG=0   — ログ無効化（既定: 有効）
#
# 規則: tmux hook では `set -euo pipefail` を使わない（emoji マッチ・guard 早期 return と相性が悪い）

CLAUDE_TMUX_CACHE_DIR="${HOME}/.cache/claude-tmux"
CLAUDE_TMUX_LOG_FILE="${HOME}/.cache/claude-tmux-status.log"
CLAUDE_TMUX_LOG_MAX_BYTES=1048576

tmux_guard() { [ -n "$TMUX" ]; }

tmux_get_clean_name() {
    local name="$1"
    name="${name#✅ }"; name="${name#⏳ }"
    name="${name#🤖 }"; name="${name#❌ }"
    name="${name#⚠️ }"
    name="${name#⚠ }"
    echo "$name"
}

tmux_current_clean_name() {
    tmux_get_clean_name "$(tmux display-message -p '#W' 2>/dev/null)"
}

# 引数: <window 名>。display-message を呼ばずに渡された名前から判定する
_tmux_emoji_of() {
    case "$1" in
        "✅ "*) echo "✅" ;;
        "⏳ "*) echo "⏳" ;;
        "🤖 "*) echo "🤖" ;;
        "❌ "*) echo "❌" ;;
        "⚠️ "*) echo "⚠️" ;;
        "⚠ "*)  echo "⚠️" ;;  # tmux が variation selector を落とした場合
        *)       echo "" ;;
    esac
}

_tmux_priority() {
    case "$1" in
        "⚠️"|"⚠") echo 50 ;;
        "❌")      echo 40 ;;
        "✅")      echo 30 ;;
        "🤖")      echo 20 ;;
        "⏳")      echo 10 ;;
        *)         echo 0 ;;
    esac
}

# bash 正規表現で session_id を抽出。jq fork を避ける。pattern は変数経由で渡す（=~ の引用符仕様）
_tmux_session_id_from_stdin() {
    local stdin_data="$1"
    [ -z "$stdin_data" ] && { echo ""; return; }
    local pat='"session_id"[[:space:]]*:[[:space:]]*"([^"]+)"'
    if [[ "$stdin_data" =~ $pat ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

_tmux_init_session() {
    CLAUDE_TMUX_SESSION_ID=$(_tmux_session_id_from_stdin "$1")
    export CLAUDE_TMUX_SESSION_ID
}

# 各 hook の冒頭で1度呼ぶ。guard を関数内 exit で済ませ、_tmux_init_session の呼び忘れも防ぐ
_tmux_hook_init() {
    tmux_guard || exit 0
    _tmux_init_session "$1"
}

_tmux_log() {
    [ "${CLAUDE_TMUX_LOG:-1}" = "0" ] && return 0
    local hook="$1" action="$2" from="$3" to="$4" extra="${5:-}"
    mkdir -p "$(dirname "$CLAUDE_TMUX_LOG_FILE")" 2>/dev/null
    if [ -f "$CLAUDE_TMUX_LOG_FILE" ]; then
        local size
        size=$(wc -c < "$CLAUDE_TMUX_LOG_FILE" 2>/dev/null)
        [ -z "$size" ] && size=0
        if [ "$size" -gt "$CLAUDE_TMUX_LOG_MAX_BYTES" ]; then
            mv -f "$CLAUDE_TMUX_LOG_FILE" "${CLAUDE_TMUX_LOG_FILE}.1" 2>/dev/null
        fi
    fi
    local ts pane_combined pane pane_id sid
    ts=$(date '+%Y-%m-%dT%H:%M:%S%z')
    pane_combined=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}|#{pane_id}' 2>/dev/null)
    pane="${pane_combined%|*}"; [ -z "$pane" ] && pane="?"
    pane_id="${pane_combined#*|}"; [ -z "$pane_id" ] && pane_id="?"
    sid="${CLAUDE_TMUX_SESSION_ID:-?}"
    [ -z "$sid" ] && sid="?"
    printf "%s pid=%s session=%s pane=%s pane_id=%s hook=%s action=%s from='%s' to='%s'%s\n" \
        "$ts" "$$" "$sid" "$pane" "$pane_id" "$hook" "$action" "$from" "$to" \
        "${extra:+ $extra}" >> "$CLAUDE_TMUX_LOG_FILE" 2>/dev/null
}

# tmux RPC: automatic-rename off と rename-window をセミコロン1コマンドにまとめる
_tmux_rename() {
    tmux set-window-option automatic-rename off \; rename-window "$1" >/dev/null 2>&1
}

tmux_force_set_status() {
    local emoji="$1" hook="$2" base="${3:-}"
    local current_full
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    [ -z "$base" ] && base=$(tmux_get_clean_name "$current_full")
    local new_full="$emoji $base"
    if [ "$new_full" != "$current_full" ]; then
        _tmux_rename "$new_full"
    fi
    _tmux_log "$hook" "force" "$current_full" "$new_full"
}

tmux_set_status_if_priority_allows() {
    local emoji="$1" hook="$2"
    local current_full current_emoji current_pri new_pri base new_full
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    current_emoji=$(_tmux_emoji_of "$current_full")
    current_pri=$(_tmux_priority "$current_emoji")
    new_pri=$(_tmux_priority "$emoji")
    base=$(tmux_get_clean_name "$current_full")
    new_full="$emoji $base"
    if [ "$new_pri" -lt "$current_pri" ]; then
        _tmux_log "$hook" "skip" "$current_full" "$current_full" "reason=priority_too_low new_pri=$new_pri current_pri=$current_pri"
        return 0
    fi
    if [ "$new_full" != "$current_full" ]; then
        _tmux_rename "$new_full"
    fi
    _tmux_log "$hook" "update" "$current_full" "$new_full" "priority=$new_pri"
}

tmux_demote_status() {
    local from="$1" to="$2" hook="$3"
    local current_full current_emoji base new_full
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    current_emoji=$(_tmux_emoji_of "$current_full")
    if [ "$current_emoji" != "$from" ]; then
        _tmux_log "$hook" "skip" "$current_full" "$current_full" "reason=not_in_from_state from=$from current=$current_emoji"
        return 0
    fi
    base=$(tmux_get_clean_name "$current_full")
    new_full="$to $base"
    if [ "$new_full" != "$current_full" ]; then
        _tmux_rename "$new_full"
    fi
    _tmux_log "$hook" "demote" "$current_full" "$new_full"
}

# === subagent counter ===

_tmux_counter_file() {
    local sid="$1"
    [ -z "$sid" ] && sid="default"
    sid=$(printf '%s' "$sid" | tr -c 'A-Za-z0-9_-' '_')
    echo "${CLAUDE_TMUX_CACHE_DIR}/subagent-count.${sid}"
}

# mkdir mutex (atomic, portable; macOS lacks flock)
_tmux_counter_op() {
    local file="$1" delta="$2"
    mkdir -p "$(dirname "$file")" 2>/dev/null
    local lockdir="${file}.lock.d"
    local tries=50
    while ! mkdir "$lockdir" 2>/dev/null; do
        tries=$((tries - 1))
        [ "$tries" -le 0 ] && break
        sleep 0.01
    done
    local cur=0
    [ -f "$file" ] && cur=$(cat "$file" 2>/dev/null)
    case "$cur" in ''|*[!0-9-]*) cur=0 ;; esac
    local new=$((cur + delta))
    [ "$new" -lt 0 ] && new=0
    printf '%s' "$new" > "$file"
    rmdir "$lockdir" 2>/dev/null
    printf '%s' "$new"
}

tmux_subagent_inc() { _tmux_counter_op "$(_tmux_counter_file "$1")" 1; }
tmux_subagent_dec() { _tmux_counter_op "$(_tmux_counter_file "$1")" -1; }

tmux_subagent_count() {
    local file
    file=$(_tmux_counter_file "$1")
    if [ -f "$file" ]; then
        cat "$file" 2>/dev/null
    else
        echo 0
    fi
}

tmux_subagent_reset() {
    local file
    file=$(_tmux_counter_file "$1")
    mkdir -p "$(dirname "$file")" 2>/dev/null
    echo 0 > "$file"
}

tmux_subagent_clear() {
    local file
    file=$(_tmux_counter_file "$1")
    rm -f "$file" 2>/dev/null
    rmdir "${file}.lock.d" 2>/dev/null
}

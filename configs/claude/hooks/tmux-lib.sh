#!/bin/bash
# Claude Code tmux status hook 共通ライブラリ
#
# Public API:
#   tmux_guard
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
#   _tmux_init_session <stdin_json>     # hook 冒頭で1度呼ぶ
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

_tmux_current_emoji() {
    local name
    name=$(tmux display-message -p '#W' 2>/dev/null)
    case "$name" in
        "✅ "*) echo "✅" ;;
        "⏳ "*) echo "⏳" ;;
        "🤖 "*) echo "🤖" ;;
        "❌ "*) echo "❌" ;;
        "⚠️ "*) echo "⚠️" ;;
        "⚠ "*)  echo "⚠️" ;;
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

_tmux_session_id_from_stdin() {
    local stdin_data="$1"
    [ -z "$stdin_data" ] && { echo ""; return; }
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$stdin_data" | jq -r '.session_id // empty' 2>/dev/null
    fi
}

# 各 hook が冒頭で呼ぶ
_tmux_init_session() {
    CLAUDE_TMUX_SESSION_ID=$(_tmux_session_id_from_stdin "$1")
    export CLAUDE_TMUX_SESSION_ID
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
    local ts pane pane_id sid
    ts=$(date '+%Y-%m-%dT%H:%M:%S%z')
    pane=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)
    [ -z "$pane" ] && pane="?"
    pane_id=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
    [ -z "$pane_id" ] && pane_id="?"
    sid="${CLAUDE_TMUX_SESSION_ID:-?}"
    [ -z "$sid" ] && sid="?"
    printf "%s pid=%s session=%s pane=%s pane_id=%s hook=%s action=%s from='%s' to='%s'%s\n" \
        "$ts" "$$" "$sid" "$pane" "$pane_id" "$hook" "$action" "$from" "$to" \
        "${extra:+ $extra}" >> "$CLAUDE_TMUX_LOG_FILE" 2>/dev/null
}

_tmux_rename() {
    tmux set-window-option automatic-rename off >/dev/null 2>&1
    tmux rename-window "$1" >/dev/null 2>&1
}

# 強制更新: 優先度無視
tmux_force_set_status() {
    tmux_guard || return 0
    local emoji="$1" hook="$2" base="${3:-}"
    local current_full
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    [ -z "$base" ] && base=$(tmux_get_clean_name "$current_full")
    local new_full="$emoji $base"
    _tmux_rename "$new_full"
    _tmux_log "$hook" "force" "$current_full" "$new_full"
}

# 優先度ガード更新: new >= current のときだけ更新（同値は冪等）
tmux_set_status_if_priority_allows() {
    tmux_guard || return 0
    local emoji="$1" hook="$2"
    local current_full current_emoji current_pri new_pri base new_full
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    current_emoji=$(_tmux_current_emoji)
    current_pri=$(_tmux_priority "$current_emoji")
    new_pri=$(_tmux_priority "$emoji")
    base=$(tmux_get_clean_name "$current_full")
    new_full="$emoji $base"
    if [ "$new_pri" -ge "$current_pri" ]; then
        _tmux_rename "$new_full"
        _tmux_log "$hook" "update" "$current_full" "$new_full" "priority=$new_pri"
    else
        _tmux_log "$hook" "skip" "$current_full" "$current_full" "reason=priority_too_low new_pri=$new_pri current_pri=$current_pri"
    fi
}

# 降格: 現在が <from> のときだけ <to> に下げる
tmux_demote_status() {
    tmux_guard || return 0
    local from="$1" to="$2" hook="$3"
    local current_emoji current_full base new_full
    current_emoji=$(_tmux_current_emoji)
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    if [ "$current_emoji" = "$from" ]; then
        base=$(tmux_get_clean_name "$current_full")
        new_full="$to $base"
        _tmux_rename "$new_full"
        _tmux_log "$hook" "demote" "$current_full" "$new_full"
    else
        _tmux_log "$hook" "skip" "$current_full" "$current_full" "reason=not_in_from_state from=$from current=$current_emoji"
    fi
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
    local file="$1" delta="$2" clamp="${3:-0}"
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
    [ "$new" -lt "$clamp" ] && new=$clamp
    printf '%s' "$new" > "$file"
    rmdir "$lockdir" 2>/dev/null
    printf '%s' "$new"
}

tmux_subagent_inc() { _tmux_counter_op "$(_tmux_counter_file "$1")" 1; }
tmux_subagent_dec() { _tmux_counter_op "$(_tmux_counter_file "$1")" -1 0; }

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
    rm -f "$file" "${file}.lock" 2>/dev/null
    rmdir "${file}.lock.d" 2>/dev/null
}

# === legacy alias（旧 hook が誤って残っても破綻しないため） ===
tmux_set_status() {
    tmux_force_set_status "$1" "legacy_set_status" "$2"
}

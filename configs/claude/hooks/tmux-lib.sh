#!/bin/bash
# Claude Code tmux status hook 共通ライブラリ
#
# Public API:
#   _tmux_hook_init <stdin_json>                       # hook 冒頭で必ず1度呼ぶ (guard + session 初期化)
#   tmux_get_clean_name <name>
#   tmux_current_clean_name
#   tmux_force_set_status <emoji> <hook> [<base>]
#   tmux_set_status_if_priority_allows <emoji> <hook>
#   tmux_set_status_or_demote_alert <emoji> <hook>     # ⚠️/❌ の場合は降格、それ以外は priority チェック
#   tmux_demote_status <from> <to> <hook>
#   tmux_subagent_inc <session_id>
#   tmux_subagent_dec <session_id>
#   tmux_subagent_count <session_id>
#   tmux_subagent_reset <session_id>
#   tmux_subagent_clear <session_id>
#   _tmux_log <hook> <action> <from> <to> [<extra_kv>]
#
# 環境変数:
#   CLAUDE_TMUX_LOG=0        — ログ無効化（既定: 有効）
#   CLAUDE_TMUX_LOG_SKIP=1   — priority_too_low の skip ログを有効化（既定: 無効。debug 用）
#
# 規則: tmux hook では `set -euo pipefail` を使わない（emoji マッチ・guard 早期 return と相性が悪い）

CLAUDE_TMUX_CACHE_DIR="${HOME}/.cache/claude-tmux"
CLAUDE_TMUX_LOG_FILE="${HOME}/.cache/claude-tmux-status.log"
CLAUDE_TMUX_LOG_MAX_BYTES=1048576

tmux_guard() { [ -n "$TMUX" ]; }

tmux_get_clean_name() {
    local name="$1" prev=""
    # 稀な競合で emoji が二重積みされたケースに備え、変化がなくなるまで剥がす
    while [ "$name" != "$prev" ]; do
        prev="$name"
        name="${name#✅ }"; name="${name#⏳ }"
        name="${name#🤖 }"; name="${name#❌ }"
        name="${name#⚠️ }"
        name="${name#⚠ }"
    done
    # bash builtin echo は -e/-n/-E 等を option 扱いするため、
    # `-e` 等で始まる window 名を空文字にしてしまう。printf で回避
    printf '%s\n' "$name"
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
    # _tmux_emoji_of が常に VS16 込みの "⚠️" に正規化するので、ここで "⚠" (VS15) 単独は不要
    case "$1" in
        "⚠️") echo 50 ;;
        "❌") echo 40 ;;
        "✅") echo 30 ;;
        "🤖") echo 20 ;;
        "⏳") echo 10 ;;
        *)    echo 0 ;;
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
        # PostToolUse など高頻度 hook が延々と skip されるとログを埋め尽くすので既定で抑止
        [ "${CLAUDE_TMUX_LOG_SKIP:-0}" = "1" ] && \
            _tmux_log "$hook" "skip" "$current_full" "$current_full" "reason=priority_too_low new_pri=$new_pri current_pri=$current_pri"
        return 0
    fi
    if [ "$new_full" != "$current_full" ]; then
        _tmux_rename "$new_full"
    fi
    _tmux_log "$hook" "update" "$current_full" "$new_full" "priority=$new_pri"
}

# alert 状態 (⚠️ / ❌) のときは無条件で降格、そうでなければ通常の priority チェック。
# permission_prompt には対応する「解除」イベントがないので、次の PostToolUse で降格させる。
# ただし subagent が動作中 (counter > 0) の場合は 🤖 に戻して subagent 状態を維持する
tmux_set_status_or_demote_alert() {
    local emoji="$1" hook="$2"
    local current_full current_emoji base new_full target_emoji count
    current_full=$(tmux display-message -p '#W' 2>/dev/null)
    current_emoji=$(_tmux_emoji_of "$current_full")
    case "$current_emoji" in
        "⚠️"|"❌")
            base=$(tmux_get_clean_name "$current_full")
            target_emoji="$emoji"
            # subagent が生きている間に alert を挟まれると 🤖 が上書きされる。
            # counter > 0 なら 🤖 に戻して subagent lifetime を可視化し続ける
            count=$(tmux_subagent_count "$CLAUDE_TMUX_SESSION_ID")
            case "$count" in ''|*[!0-9]*) count=0 ;; esac
            if [ "$count" -gt 0 ]; then
                target_emoji="🤖"
            fi
            new_full="$target_emoji $base"
            if [ "$new_full" != "$current_full" ]; then
                _tmux_rename "$new_full"
            fi
            _tmux_log "$hook" "demote_alert" "$current_full" "$new_full" "subagent_count=$count"
            ;;
        *)
            tmux_set_status_if_priority_allows "$emoji" "$hook"
            ;;
    esac
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
# - ロック取得に成功したときだけ末尾で rmdir する (他プロセスのロックを剥がさない)
# - 500ms 経っても取れなかった場合は stale lockdir とみなして強制取得
# - cur の numeric 検証は `-` も不許可 (負値の混入を防ぎ arithmetic 例外を回避)
# - counter file は改行付きで書く (`read -r` が exit 1 で `|| cur=0` に落ちるのを防ぐ)
_tmux_counter_op() {
    local file="$1" delta="$2"
    mkdir -p "$(dirname "$file")" 2>/dev/null
    local lockdir="${file}.lock.d"
    local acquired=0 tries=50
    while [ "$tries" -gt 0 ]; do
        if mkdir "$lockdir" 2>/dev/null; then
            acquired=1
            break
        fi
        tries=$((tries - 1))
        sleep 0.01
    done
    if [ "$acquired" = "0" ]; then
        # stale lock 回復: SIGKILL 等で残った lockdir を強制解放して取り直す
        rmdir "$lockdir" 2>/dev/null
        mkdir "$lockdir" 2>/dev/null && acquired=1
    fi
    local cur=0
    [ -f "$file" ] && IFS= read -r cur < "$file" 2>/dev/null
    case "$cur" in ''|*[!0-9]*) cur=0 ;; esac
    local new=$((cur + delta))
    [ "$new" -lt 0 ] && new=0
    printf '%s\n' "$new" > "$file"
    [ "$acquired" = "1" ] && rmdir "$lockdir" 2>/dev/null
    printf '%s' "$new"
}

tmux_subagent_inc() { _tmux_counter_op "$(_tmux_counter_file "$1")" 1; }
tmux_subagent_dec() { _tmux_counter_op "$(_tmux_counter_file "$1")" -1; }

tmux_subagent_count() {
    local file cur=0
    file=$(_tmux_counter_file "$1")
    [ -f "$file" ] && IFS= read -r cur < "$file" 2>/dev/null
    case "$cur" in ''|*[!0-9]*) cur=0 ;; esac
    printf '%s\n' "$cur"
}

tmux_subagent_reset() {
    local file
    file=$(_tmux_counter_file "$1")
    mkdir -p "$(dirname "$file")" 2>/dev/null
    printf '%s\n' 0 > "$file"
}

tmux_subagent_clear() {
    local file
    file=$(_tmux_counter_file "$1")
    rm -f "$file" 2>/dev/null
    rmdir "${file}.lock.d" 2>/dev/null
}

#!/bin/bash
source "$(dirname "$0")/tmux-lib.sh"
_tmux_hook_init "$(cat)"
# 既存 window 名 (絵文字剥ぎ後) が空でなければそれを保持し、tmux-start.local.sh 等で
# 明示的に付けた名前を潰さない。空の場合のみ PWD basename にフォールバック
BASE=$(tmux_current_clean_name)
[ -z "$BASE" ] && BASE=$(basename "$PWD")
tmux_force_set_status "⏳" "SessionStart" "$BASE"
# SessionEnd が発火せず残った古い subagent counter / lockdir を掃除。
# lockdir はディレクトリなので `-type f` では消えないため両方対象にする
find "${CLAUDE_TMUX_CACHE_DIR}" -type f -name 'subagent-count.*' -mtime +7 -delete 2>/dev/null
find "${CLAUDE_TMUX_CACHE_DIR}" -type d -name 'subagent-count.*.lock.d' -mtime +7 -empty -delete 2>/dev/null
# CLAUDE_TMUX_SESSION_ID が空でも "default" fallback があるのでガードせず reset
tmux_subagent_reset "$CLAUDE_TMUX_SESSION_ID"
# hot path から外した log rotation をこの低頻度 hook でまとめて行う
_tmux_log_rotate_if_needed

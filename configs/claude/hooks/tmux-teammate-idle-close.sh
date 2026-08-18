#!/bin/bash
# TeammateIdle hook: 作業を終えた teammate の pane を閉じる
#
# teammate は idle になっても SendMessage で起こせる設計なので、プロセスは生き続け
# pane も残る。放置すると pane が溜まるため、idle を検知して閉じる。
#
# pane の特定は推測に頼らない。payload の teammate_name / team_name を繋いだ
# "<name>@<team>" が、pane_start_command の --agent-id と一致する pane だけを対象にする。
#
# ただし idle 直後に追加メッセージで起こされることがあるので即座には閉じない。
# GRACE 秒待ち、その間の CPU 使用率が閾値未満なら本当に終わったと判断して閉じる。
# 起こされた場合は CPU を使うので閉じない。
#
# アイドルでも CPU 使用がゼロにはならない (TUI の描画で 3 秒あたり 0.02 秒ほど進む)。
# そのため「変化なし」ではなく「使用率 CLAUDE_TMUX_TEAMMATE_IDLE_PCT% 未満」で判定する。
#
#   CLAUDE_TMUX_TEAMMATE_CLOSE=0     — この掃除を無効化
#   CLAUDE_TMUX_TEAMMATE_GRACE=N     — 待機秒数 (既定 60)。0 なら CPU 判定なしで即閉じる
#   CLAUDE_TMUX_TEAMMATE_IDLE_PCT=N  — アイドルとみなす CPU 使用率の上限 (既定 5)

source "$(dirname "$0")/tmux-lib.sh"
STDIN_DATA="$(cat)"
_tmux_hook_init "$STDIN_DATA"

[ "${CLAUDE_TMUX_TEAMMATE_CLOSE:-1}" = "0" ] && exit 0
GRACE="${CLAUDE_TMUX_TEAMMATE_GRACE:-60}"
IDLE_PCT="${CLAUDE_TMUX_TEAMMATE_IDLE_PCT:-5}"

# ps -o time= の "M:SS.ss" / "HH:MM:SS" を 1/100 秒に正規化する
_cpu_centis() {
    awk -v t="$1" 'BEGIN {
        n = split(t, a, ":")
        if (n == 3)      v = a[1] * 3600 + a[2] * 60 + a[3]
        else if (n == 2) v = a[1] * 60 + a[2]
        else             v = a[1]
        printf "%d", v * 100
    }'
}

# jq fork を避け、lib と同じく bash 正規表現で取り出す
_teammate_field() {
    local pat="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]+)\""
    [[ "$STDIN_DATA" =~ $pat ]] && printf '%s\n' "${BASH_REMATCH[1]}"
}

NAME=$(_teammate_field teammate_name)
TEAM=$(_teammate_field team_name)
[ -z "$NAME" ] || [ -z "$TEAM" ] && exit 0
AGENT_ID="${NAME}@${TEAM}"

# 末尾の空白まで含めて照合し、前方一致で別 teammate を巻き込まないようにする
TARGET=""
while IFS='|' read -r pane_id start_cmd; do
    case "$start_cmd" in
        *"--agent-id $AGENT_ID "*) TARGET="$pane_id"; break ;;
    esac
done < <(tmux list-panes -a -F '#{pane_id}|#{pane_start_command}' 2>/dev/null)

# この hook は teammate 自身の pane の中で走るので、TARGET は自分の pane と一致するのが正常。
# 「自分の pane は閉じない」というガードは入れない。安全性は --agent-id 一致で担保する:
# 親セッションの pane は start_command が空なので決して一致せず、teammate が in-process で
# 動いている場合も該当 pane が存在せず TARGET が空になる。
[ -z "$TARGET" ] && exit 0

PANE_PID=$(tmux display-message -p -t "$TARGET" '#{pane_pid}' 2>/dev/null)
[ -z "$PANE_PID" ] && exit 0

_tmux_log "TeammateIdle" "close_scheduled" "$AGENT_ID" "$TARGET" "grace=${GRACE}s"

# hook 自体は即座に返す。待機は切り離したプロセスに任せ、hook の寿命に依存させない
(
    BEFORE=$(_cpu_centis "$(ps -o time= -p "$PANE_PID" 2>/dev/null | tr -d '[:space:]')")
    sleep "$GRACE"
    tmux display-message -p -t "$TARGET" '#{pane_id}' >/dev/null 2>&1 || exit 0

    # GRACE=0 のときは経過時間がないので CPU 判定を行わない
    if [ "$GRACE" -gt 0 ]; then
        AFTER=$(_cpu_centis "$(ps -o time= -p "$PANE_PID" 2>/dev/null | tr -d '[:space:]')")
        DELTA=$((AFTER - BEFORE))
        BUDGET=$((GRACE * IDLE_PCT))
        if [ "$DELTA" -gt "$BUDGET" ]; then
            _tmux_log "TeammateIdle" "close_skipped_resumed" "$AGENT_ID" "$TARGET" \
                "cpu_delta=${DELTA} budget=${BUDGET}"
            exit 0
        fi
    fi

    # pane を閉じるとこのサブシェル自身も一緒に死ぬので、ログは kill の前に書く
    _tmux_log "TeammateIdle" "close_done" "$AGENT_ID" "$TARGET" "cpu_delta=${DELTA:-n/a}"
    tmux kill-pane -t "$TARGET" 2>/dev/null
) </dev/null >/dev/null 2>&1 &
disown 2>/dev/null

exit 0

# shellcheck shell=bash
# 引用や commit message に出てくるだけのコマンド名で止めないよう、区切りの後の先頭だけを見る
command_segments() {
  printf '%s\n' "$1" | tr ';&|' '\n\n\n' | sed -E 's/^[[:space:]({]+//'
}

deny() {
  jq -nc --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
}

# marker <name> <key>: 印のパスを MARKER に入れ、30 分以内に書いた印があれば 0 を返す。
# 放置された印で後の別の実行を見直し無しに通さないよう、印は 30 分で切る
marker() {
  local dir="${TMPDIR:-/tmp}/claude-$1"
  mkdir -p "$dir"
  MARKER="$dir/$(printf '%s' "$2" | shasum | cut -c1-40)"
  [ -n "$(find "$MARKER" -mmin -30 2>/dev/null)" ]
}

# deny_once <name> <key> <reason>: 同じ key の 2 回目は通す
deny_once() {
  if marker "$1" "$2"; then
    rm -f "$MARKER"
    return 0
  fi
  : >"$MARKER"
  deny "$3"
}

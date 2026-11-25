# shellcheck shell=bash
# 引用や commit message に出てくるだけのコマンド名で止めないよう、区切りの後の先頭だけを見る
command_segments() {
  printf '%s\n' "$1" | tr ';&|' '\n\n\n' | sed -E 's/^[[:space:]({]+//'
}

# deny_once <name> <key> <reason>: 同じ key の 2 回目は通す。
# 放置された印で後の別の実行を見直し無しに通さないよう、印は 30 分で切る
deny_once() {
  local dir="${TMPDIR:-/tmp}/claude-$1" marker
  mkdir -p "$dir"
  marker="$dir/$(printf '%s' "$2" | shasum | cut -c1-40)"
  if [ -n "$(find "$marker" -mmin -30 2>/dev/null)" ]; then
    rm -f "$marker"
    return 0
  fi
  : >"$marker"
  jq -nc --arg r "$3" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
}

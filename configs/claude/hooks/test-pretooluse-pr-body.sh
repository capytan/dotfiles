#!/bin/bash
# 使い方: bash configs/claude/hooks/test-pretooluse-pr-body.sh
set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/pretooluse-pr-body.sh"
HOOK_BASH="${HOOK_BASH:-bash}"
TMPDIR=$(mktemp -d)
export TMPDIR
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

check() {
  local expected=$1 cmd=$2 out actual
  out=$("$HOOK_BASH" "$HOOK" <<<"$(jq -nc --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}')")
  actual=$([ -n "$out" ] && jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" || echo allow)
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected=%-5s actual=%-5s  %s\n' "$expected" "$actual" "$cmd"
  fi
}

check deny 'gh pr create --draft --body-file body.md'
check allow 'gh pr create --draft --body "直した本文"'
check deny 'gh pr create --draft --body-file body.md'
check deny 'git fetch && gh pr edit 3 --body-file other.md'
check allow 'gh pr edit 3 --title "x"'
check allow 'gh pr view 3'
check allow 'git commit -m "add gh pr create hook"'

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

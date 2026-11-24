#!/bin/bash
# 使い方: bash configs/claude/hooks/test-pretooluse-added-comments.sh
set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/pretooluse-added-comments.sh"
HOOK_BASH="${HOOK_BASH:-bash}"
TMPDIR=$(mktemp -d)
export TMPDIR
trap 'rm -rf "$TMPDIR"' EXIT

repo="$TMPDIR/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init
git -C "$repo" update-ref refs/remotes/origin/main HEAD

pass=0
fail=0

check() {
  local expected=$1 cmd=$2 cwd=${3:-$repo} out actual
  out=$("$HOOK_BASH" "$HOOK" <<<"$(jq -nc --arg c "$cmd" --arg d "$cwd" '{tool_name: "Bash", cwd: $d, tool_input: {command: $c}}')")
  actual=$([ -n "$out" ] && jq -r '.hookSpecificOutput.permissionDecision' <<<"$out" || echo allow)
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected=%-5s actual=%-5s  %s\n' "$expected" "$actual" "$cmd"
  fi
}

commit_file() {
  printf '%s\n' "$2" >"$repo/$1"
  git -C "$repo" add "$1"
  git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q -m "$1"
}

commit_file a.tf 'resource "x" "y" {}'
commit_file README.md '# 見出し'
check allow 'git push'

commit_file b.tf '# 理由'
check allow 'git commit -m "stop git push here"'
check deny 'git push'
check allow 'git push'
check deny 'gh pr create --draft'
check deny "git -C $repo push" "$TMPDIR"

commit_file c.tf "$(printf '# c\n%.0s' $(seq 1 3000))"
check deny "cd $repo && git push origin HEAD" "$TMPDIR"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

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
  # 直後の listed が見る
  reason=$([ -n "$out" ] && jq -r '.hookSpecificOutput.permissionDecisionReason' <<<"$out" || true)
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected=%-5s actual=%-5s  %s\n' "$expected" "$actual" "$cmd"
  fi
}

# listed <yes|no> <text>: 直前の check で止めたときの一覧に text が出たか
listed() {
  local actual=no
  case $reason in *"$2"*) actual=yes ;; esac
  if [ "$actual" = "$1" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  listed %s expected=%s\n' "$2" "$1"
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

commit_file b.tf "$(printf '# 理由\n# 消す')"
check allow 'git commit -m "stop git push here"'
check deny 'git push'
check allow 'git push'
check deny 'gh pr create --draft'

# 見直してコメントを消し、行がずれた commit では止めない
commit_file b.tf "$(printf 'x\n# 理由')"
check allow 'gh pr create --draft'

# 後から足したコメントだけを出し、見せたものと消したものは出さない。出しても覚えている期限は延ばさない
: >"$TMPDIR/before"
sleep 1
commit_file c.tf '# 足した'
check deny "git -C $repo push" "$TMPDIR"
listed yes 'c.tf:1: # 足した'
listed no 'b.tf'
if [ -n "$(find "$TMPDIR/claude-added-comments" -type f ! -name '*.stamp' -newer "$TMPDIR/before")" ]; then
  fail=$((fail + 1))
  echo 'FAIL  marker expiry extended'
fi

commit_file d.tf "$(printf '# d%s\n' $(seq 1 3000))"
check deny "cd $repo && git push origin HEAD" "$TMPDIR"
# 一覧に出しきれなかった分は次の回に出す
check deny 'git push'
listed yes 'd.tf:41: # d41'

# main を fetch していない clone の push は upstream を起点にする
repo="$TMPDIR/topic"
git init -q -b topic "$repo"
commit_file a.tf 'x'
git -C "$repo" config remote.origin.url .
git -C "$repo" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
git -C "$repo" update-ref refs/remotes/origin/topic HEAD
git -C "$repo" config branch.topic.remote origin
git -C "$repo" config branch.topic.merge refs/heads/topic
commit_file b.tf '# 理由'
check deny 'git push'

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]

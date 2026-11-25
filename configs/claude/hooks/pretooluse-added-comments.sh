#!/bin/bash
# PreToolUse hook: 足したコードのコメントがある gh pr create / git push を 1 回止め、コメントを一覧にして見直させる
set -euo pipefail

INPUT=$(cat)
# Bash のたびに動くので、対象外は fork せずに抜ける
case $INPUT in *'gh pr'* | *push*) ;; *) exit 0 ;; esac
. "$(dirname "$0")/lib-hook-common.sh"
[ "$(jq -r '.tool_name // empty' <<<"$INPUT")" = "Bash" ] || exit 0
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
CWD=$(jq -r '.cwd // empty' <<<"$INPUT")
[ -n "$CWD" ] && [ -d "$CWD" ] && cd "$CWD"

# 対象の repo を、前の cd と git -C から決める
kind="" dir=$PWD
while IFS= read -r seg; do
  if [[ $seg =~ ^cd[[:space:]]+([^[:space:]]+) ]]; then
    dir=$(cd "$dir" && cd "${BASH_REMATCH[1]//[\"\']/}" 2>/dev/null && pwd) || exit 0
  elif [[ $seg =~ ^gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$) ]]; then
    kind=pr
    break
  elif [[ $seg =~ ^git(([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)|([[:space:]]+--?[^[:space:]]+))*[[:space:]]+push([[:space:]]|$) ]]; then
    kind=push
    if [[ $seg =~ [[:space:]]-C[[:space:]]+([^[:space:]]+) ]]; then
      dir=$(cd "$dir" && cd "${BASH_REMATCH[1]//[\"\']/}" 2>/dev/null && pwd) || exit 0
    fi
    break
  fi
done < <(command_segments "$COMMAND")
[ -n "$kind" ] || exit 0
cd "$dir"
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

# rebase の後に main 側の変更を拾わないよう、tip 同士の diff ではなく commit ごとの差分を見る
range=""
[ "$kind" = push ] && git rev-parse --verify -q '@{upstream}' >/dev/null 2>&1 && range='@{upstream}..HEAD'
if [ -z "$range" ]; then
  default=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
  git rev-parse --verify -q "$default" >/dev/null || exit 0
  range="$default..HEAD"
fi

# Markdown などの見出しと箇条書きはコメントではないので外す
comments=$(git log -p --no-merges --format= -U0 --no-color "$range" -- . ':(exclude)*.md' ':(exclude)*.mdx' ':(exclude)*.txt' ':(exclude)*.rst' | awk '
  /^\+\+\+ / { file = substr($0, 7); next }
  /^@@/ { split($3, a, ","); line = substr(a[1], 2) + 0; next }
  /^\+/ {
    text = substr($0, 2)
    if (n < 40 && text ~ /^[[:space:]]*(#|\/\/|\/\*|\*[[:space:]]|--[[:space:]]|<!--)/ && text !~ /^#!/) {
      sub(/^[[:space:]]+/, "", text)
      printf "%s:%d: %s\n", file, line, text
      n++
    }
    line++
  }')
[ -n "$comments" ] || exit 0

deny_once added-comments "$PWD
$(git rev-parse HEAD)
$kind" "足したコメントが必要最小限かを見直す。コードから読めない理由・制約・前提だけを残し、処理の説明、名前の言い換え、経緯、Issue への誘導は消す。直したら commit してから、このままでよければそのまま、もう一度実行する
$comments"

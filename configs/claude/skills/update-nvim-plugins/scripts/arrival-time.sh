#!/usr/bin/env bash
# 使い方: arrival-time.sh <owner/repo> <branch> <プラグインのディレクトリ> <sha>
# sha が branch に届いた時刻を出す。新しい activity から順に、after が sha を含むあいだ時刻を出し、
# 含まなくなったところで止めて最後の（最も古い）時刻を使う。空なら届いた時刻不明。
# while が止まると gh も止まるので、必要なページだけを取る。pipefail を付けないのはそのため。
set -eu

repo=$1 b=$2 d=$3 sha=$4
gh api "repos/$repo/activity?ref=refs/heads/$b&per_page=100" --paginate \
  --jq '.[] | select(.activity_type != "branch_deletion") | "\(.after) \(.timestamp)"' </dev/null |
while read -r a ts; do git -C "$d" merge-base --is-ancestor "$sha" "$a" 2>/dev/null || break; echo "$ts"; done | tail -1

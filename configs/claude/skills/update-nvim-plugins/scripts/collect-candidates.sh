#!/usr/bin/env bash
# 使い方: collect-candidates.sh <基準の lock> <cutoff> > nvim-candidates.tsv
# プラグインごとに fetch し、1 行に 名前、repo、branch、基準、HEAD、168 時間前の先頭とその時刻 をタブ区切りで出す。
# fetch に失敗したプラグインは "<名前>\tFETCH-FAILED" を出して続ける。
set -eu

lock=$1 cutoff=$2
here=$(cd "$(dirname "$0")" && pwd)
LAZY=~/.local/share/nvim/lazy

jq -r 'to_entries[] | "\(.key)\t\(.value.branch)\t\(.value.commit)"' "$lock" |
while IFS=$'\t' read -r n b base; do
  d="$LAZY/$n"
  git -C "$d" fetch --quiet --tags origin </dev/null || { printf '%s\tFETCH-FAILED\n' "$n"; continue; }
  repo=$(git -C "$d" remote get-url origin | sed -E 's#^https://github.com/##; s#\.git$##')
  t7=$(bash "$here/activity-tip.sh" "$repo" "$b" "$cutoff")
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$repo" "$b" "$base" "$(git -C "$d" rev-parse HEAD)" "$t7"
done

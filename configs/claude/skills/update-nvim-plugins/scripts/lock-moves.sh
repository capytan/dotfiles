#!/usr/bin/env bash
# 使い方: lock-moves.sh <lock>
# restore で動くプラグインを、今の HEAD と lock から出す（restore は lock の commit に checkout するので、違うものだけが動く）。
#   NEW <名前> <sha>               入っていない（起動時のインストールが lock の commit で入れる）
#   MOVE <名前> <HEAD> -> <lock>   restore で checkout される
#   NOT-ON-BRANCH <名前> <sha>     lock の commit が origin の branch に無い（sha の書き間違いか force push）
set -euo pipefail

LAZY=~/.local/share/nvim/lazy
jq -r 'to_entries[] | "\(.key)\t\(.value.branch)\t\(.value.commit)"' "$1" | while IFS=$'\t' read -r n b c; do
  d="$LAZY/$n"
  [ -d "$d/.git" ] || { echo "NEW $n $c"; continue; }
  h=$(git -C "$d" rev-parse HEAD)
  [ "$h" = "$c" ] && continue
  if git -C "$d" merge-base --is-ancestor "$c" "origin/$b" 2>/dev/null; then echo "MOVE $n ${h:0:8} -> ${c:0:8}"; else echo "NOT-ON-BRANCH $n $c"; fi
done

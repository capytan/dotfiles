#!/bin/bash
# PreToolUse hook: 本文を渡す gh pr create / gh pr edit を 1 回止め、本文を必要最小限に見直させる
# 行数で弾くと要る説明まで削られるので、上限は設けない
set -euo pipefail

INPUT=$(cat)
# Bash のたびに動くので、対象外は fork せずに抜ける
case $INPUT in *'gh pr'*) ;; *) exit 0 ;; esac
. "$(dirname "$0")/lib-hook-common.sh"
[ "$(jq -r '.tool_name // empty' <<<"$INPUT")" = "Bash" ] || exit 0
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

sub=$(command_segments "$COMMAND" | awk '
  function repo(  i, r) {
    for (i = 4; i <= NF; i++) {
      if ($i == "-R" || $i == "--repo") r = $(i + 1)
      else if ($i ~ /^--repo=/) r = substr($i, 8)
    }
    return r
  }
  /^gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)/ { print "create", repo() }
  /^gh[[:space:]]+pr[[:space:]]+edit([[:space:]]|$)/ && /[[:space:]](--body|--body-file|-b|-F)([[:space:]=]|$)/ { print "edit", ($4 ~ /^-/ ? "" : $4), repo() }')
[ -n "$sub" ] || exit 0

# 直した本文での再実行も通すよう、本文を含めずに repo・ブランチ・サブコマンドと edit の対象を key にする。
# 印は 30 分残るので、別の PR の本文を見直し無しに通さないよう、--repo を含めて対象の PR をすべて key に含める
deny_once pr-body "$PWD
$(git symbolic-ref -q --short HEAD 2>/dev/null || true)
$sub" "PR の本文が必要最小限かを見直す。diff とコミットから分からないことだけを書き、変えたファイルやリソースの列挙、作業の経緯、試して捨てた案、diff の言い換え、レビューの指摘への言い訳は消す。見直したら、直した本文か同じ本文でもう一度実行する"

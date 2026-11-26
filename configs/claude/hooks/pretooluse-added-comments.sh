#!/bin/bash
# PreToolUse hook: まだ見せていない足したコードのコメントがある gh pr create / git push を止め、コメントを一覧にして見直させる
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

# 後の commit で消したコメントを出さないよう正味の差分を見る。rebase の後に main 側の変更を拾わないよう、
# 起点は main との merge-base にし、push では upstream との merge-base のほうが新しいか main が無ければそれにする
default=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
base=$(git merge-base "$default" HEAD 2>/dev/null || true)
if [ "$kind" = push ] && up=$(git merge-base '@{upstream}' HEAD 2>/dev/null) &&
  { [ -z "$base" ] || git merge-base --is-ancestor "$base" "$up"; }; then
  base=$up
fi
[ -n "$base" ] || exit 0

# 見せたコメントを 30 分覚え、まだ見せていないものがあるときだけ止める。HEAD を key にすると、
# 見直して commit するたびに同じコメントでまた止まり、ほかの hook と交互に止め続ける。
# 行番号は前の行を消すとずれるので、ファイルと本文と、同じ本文の何個目かで覚える
marker added-comments "$PWD
$(git symbolic-ref -q --short HEAD || true)
$kind" || : >"$MARKER"
seen=$MARKER
# 追記のたびに期限が延びると、最初に見せたコメントがいつまでも見直し済みのままになるので、
# 期限は最初に見せた時から数える
touch -r "$seen" "$seen.stamp"

# Markdown などの見出しと箇条書きはコメントではないので外す
comments=$(git diff --no-color -U0 "$base" HEAD -- . ':(exclude)*.md' ':(exclude)*.mdx' ':(exclude)*.txt' ':(exclude)*.rst' | awk -v seen="$seen" '
  BEGIN { while ((getline l < seen) > 0) shown[l] }
  /^\+\+\+ / { file = substr($0, 7); next }
  /^@@/ { split($3, a, ","); line = substr(a[1], 2) + 0; next }
  /^\+/ {
    text = substr($0, 2)
    if (text ~ /^[[:space:]]*(#|\/\/|\/\*|\*[[:space:]]|--[[:space:]]|<!--)/ && text !~ /^#!/) {
      sub(/^[[:space:]]+/, "", text)
      key = file "\t" text "\t" ++count[file "\t" text]
      # 出せなかった分は覚えず、次の回に出す
      if (!(key in shown) && n++ < 40) {
        print key >>seen
        printf "%s:%d: %s\n", file, line, text
      }
    }
    line++
  }')
touch -r "$seen.stamp" "$seen"
[ -n "$comments" ] || exit 0

deny "足したコメントが必要最小限かを見直す。コードから読めない理由・制約・前提だけを残し、処理の説明、名前の言い換え、経緯、Issue への誘導は消す。直したら commit してから、このままでよければそのまま、もう一度実行する
$comments"

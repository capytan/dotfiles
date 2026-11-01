#!/usr/bin/env bash
# configs/vscode/settings.json (VS Code) と configs/cursor/settings.json (Cursor) が
# extensions.autoUpdate の行を除いて同じかを確かめる。CI (.github/workflows/editor-settings.yml) も使う
set -euo pipefail
cd "$(dirname "$0")/../.."

vscode=configs/vscode/settings.json
cursor=configs/cursor/settings.json
# VS Code は false を "off" に書き換え、Cursor は "off" をオンと読む。
# 除くのは値とコメントだけの行に限り、同じ行に別の設定を書けば diff に出るようにする
re_vscode='  "extensions\.autoUpdate": "off",( //.*)?'
re_cursor='  "extensions\.autoUpdate": false,( //.*)?'

fail=0
for f in "$vscode:$re_vscode" "$cursor:$re_cursor"; do
  file=${f%%:*} re=${f#*:}
  if [ "$(grep -cF '"extensions.autoUpdate"' "$file")" != 1 ] || ! grep -qxE "$re" "$file"; then
    echo "$file: extensions.autoUpdate must appear once, matching: $re" >&2
    fail=1
  fi
done
diff -u <(grep -vxE "$re_vscode" "$vscode") <(grep -vxE "$re_cursor" "$cursor") || fail=1
exit "$fail"

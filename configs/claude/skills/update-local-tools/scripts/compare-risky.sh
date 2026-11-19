#!/usr/bin/env bash
# 使い方: compare-risky.sh <owner/repo> <今の tag> <候補の tag>
# compare の変更ファイルの一覧を出し、release・publish・sign・build 系の workflow の差分から危険箇所に当たる行を出す。
# 変更ファイルの一覧は compare の最初のページにだけ全体の分が載る（後のページは commit だけ）ので、ページを送らない。
# gh の失敗は exit で返す（「危険箇所なし」と見分けがつかなくならないように）。
set -euo pipefail

repo=$1 cur=$2 new=$3
f=$(mktemp)
trap 'rm -f "$f"' EXIT
gh api "repos/$repo/compare/$cur...$new?per_page=1" --jq '.files[]' > "$f"
echo "## files"
jq -r '.filename' "$f" | sort -u
echo "## release workflows"
jq -r 'select(.filename|test("^\\.github/workflows/(release|publish|sign|build)")) | "=== \(.filename)\n\(.patch // "(no patch)")"' "$f" |
  { grep -E '^===|^\+.*(curl|wget|base64|eval|uses: |secrets\.|https?://)' || true; }

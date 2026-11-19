#!/usr/bin/env bash
# 使い方: write-lock.sh <基準の lock> '<c の JSON>' '<new の JSON>' > lazy-lock.json
#   c:   {"<名前>": "<40 桁の sha>", ...}                              commit だけを変えるプラグイン
#   new: {"<名前>": {"branch": "<branch>", "commit": "<sha>"}, ...}    足す新規プラグイン（無ければ {}）
# lazy.nvim が書き直すのと同じ書式（名前の順、1 行 1 プラグイン）で出すので、restore のあとに差分が出ない。
set -euo pipefail

jq -r --argjson c "$2" --argjson new "$3" \
  'reduce ($c | to_entries[]) as $e (.; .[$e.key].commit = $e.value) + $new | to_entries | sort_by(.key) | map("  \(.key | tojson): { \"branch\": \(.value.branch | tojson), \"commit\": \(.value.commit | tojson) }") | "{\n" + join(",\n") + "\n}"' \
  "$1"

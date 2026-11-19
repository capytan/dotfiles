#!/usr/bin/env bash
# 使い方: pypi-releases.sh <name>
# PyPI の直近 5 版を "<版> <最初のファイルの upload 時刻>" で公開の順に出す。ファイルの無い版（yank 済みなど）は除く。
set -euo pipefail

curl -sf "https://pypi.org/pypi/$1/json" |
  jq -r '.releases | to_entries | map(select(.value|length>0) | {v:.key, t:(.value|map(.upload_time_iso_8601)|min)}) | sort_by(.t) | .[-5:][] | "\(.v) \(.t)"'

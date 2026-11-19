#!/usr/bin/env bash
# 使い方: hours-since.sh <UTC の ISO 8601 の時刻>
# 公開からの経過時間を時間単位（切り捨て）で出す。小数秒付き（.389957Z、.0Z）も fromdateiso8601 が読めるように落とす。
set -euo pipefail

jq -rn --arg t "$1" '(now - ($t | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 3600 | floor'

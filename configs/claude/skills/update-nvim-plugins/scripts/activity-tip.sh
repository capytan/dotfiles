#!/usr/bin/env bash
# 使い方: activity-tip.sh <owner/repo> <branch> <cutoff>
# cutoff 以前で最新の activity を "<after> <timestamp> <activity_type>" の 1 行で出す（168 時間前の branch の先頭）。
# 取れなければ何も出さない（公開時刻不明）。
# activity は新しい順に返るので最初の 1 件でよい。--paginate はページごとに出力するので、head が閉じると残りのページは取らない。
# head が閉じたあとの gh の SIGPIPE で落ちないよう pipefail を付けない。
set -eu

repo=$1 b=$2 cutoff=$3
gh api "repos/$repo/activity?ref=refs/heads/$b&per_page=100" --paginate \
  --jq ".[] | select(.activity_type != \"branch_deletion\" and .timestamp <= \"$cutoff\") | \"\(.after) \(.timestamp) \(.activity_type)\"" </dev/null | head -1

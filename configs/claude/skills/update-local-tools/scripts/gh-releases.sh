#!/usr/bin/env bash
# 使い方: gh-releases.sh <owner/repo>
# 直近 10 件の GitHub Release のうち pre-release でないものを "<tag> <published_at>" で出す。
set -euo pipefail

gh api "repos/$1/releases?per_page=10" --jq '.[] | select(.prerelease|not) | "\(.tag_name) \(.published_at)"'

#!/usr/bin/env bash
# 使い方: uv-python-minor.sh
# 入っている uv 管理の CPython（default の variant）の安定版のうち、最も新しい minor（例 3.14）を出す。uv tool を入れる Python の <PYVER> に使う。
# download だけのもの（path が無い）は数えない。新しい minor に上げるのは承認を取ってから。安定版が 1 つも入っていなければ失敗する。
set -euo pipefail

command uv python list --managed-python --output-format json |
  jq -er '[.[] | select(.path != null and .implementation == "cpython" and .variant == "default" and (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))]
    | max_by(.version_parts | [.major, .minor, .patch]) | .version_parts | "\(.major).\(.minor)"'

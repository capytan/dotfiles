#!/bin/bash
# pretooluse-validate-command.sh の判定テーブルテスト
#
# 使い方: bash configs/claude/hooks/test-pretooluse-validate-command.sh
# 依存: jq のみ (hook 自体がすでに jq 必須)。CI では回さず、hook を触ったときに手で叩く
#
# allow ケースは単なる正常系ではなく、過去に踏んだ false positive の回帰テスト。
# 削らないこと (どの事故に対応するかは各ケースのコメントを参照)
#
# set -e は付けない: 失敗ケースで即死させず全件走らせて一覧を出すため
set -uo pipefail

HOOK="$(cd "$(dirname "$0")" && pwd)/pretooluse-validate-command.sh"

pass=0
fail=0

# decision <json> -> permissionDecision (hook が無出力 = 判定なし なら allow)
# jq は空入力だとプログラムを一度も実行しないので、`// "allow"` では拾えない。shell 側で分岐する
decision() {
  local out
  out=$(bash "$HOOK" <<<"$1")
  if [ -z "$out" ]; then
    echo allow
  else
    jq -r '.hookSpecificOutput.permissionDecision // "allow"' <<<"$out" 2>/dev/null
  fi
}

# check <expected> <command>
check() {
  local expected=$1 cmd=$2 actual
  actual=$(decision "$(jq -nc --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}')")
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected=%-5s actual=%-5s  %s\n' "$expected" "$actual" "$cmd"
  fi
}

# check_raw <expected> <label> <json> — tool_name 違いなど生 JSON を流す用
check_raw() {
  local expected=$1 label=$2 json=$3 actual
  actual=$(decision "$json")
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL  expected=%-5s actual=%-5s  %s\n' "$expected" "$actual" "$label"
  fi
}

# --- rule 1: git push force 系 ---
check deny 'git push --force'
check deny 'git push -f origin main'
check deny 'git push --force-with-lease origin main'
check deny 'git push origin +main:main'
# 改行正規化が無いと行継続で全 block を bypass できた
check deny "$(printf 'git push \\\n--force')"
check allow 'git push origin main'
check allow 'git push --set-upstream origin feat/foo'

# --- rule 2: git reset --hard ---
check deny 'git reset --hard HEAD~1'
check allow 'git reset HEAD~1'

# --- rule 3: git clean -f ---
check deny 'git clean -fd'
check deny 'git clean --force'
check allow 'git clean -n'

# --- rule 4: 破壊的な削除 ---
check ask 'git branch -D foo'
check ask 'git branch --delete --force foo'
check ask 'git branch -d -f foo'
check ask 'git branch -f -d foo'
check ask 'git update-ref -d refs/heads/foo'
check ask 'git update-ref --delete refs/heads/foo'
check ask 'git worktree remove --force ../wt'
check ask 'git worktree remove -f ../wt'
check allow 'git branch -d foo'
check allow 'git branch -vv'
# branch 名に含まれる -D を flag と誤認しない
check allow 'git checkout feature-D-42'
check allow 'git branch -m feature-D-42 feature-D-43'
check allow 'git update-ref refs/heads/foo HEAD'
check allow 'git worktree remove ../wt'
check allow 'git worktree list'

# --- rule 5: rm -rf ---
check deny 'rm -rf /tmp/x'
check deny 'rm -fr /tmp/x'
check deny 'rm -r -f /tmp/x'
check deny 'rm --recursive --force /tmp/x'
check allow 'rm /tmp/x'
check allow 'rm -r /tmp/x'
# path 中の -f を flag と誤認しない
check allow 'rm /var/log-final/app.log'

# --- rule 6: sed in-place ---
check deny "sed -i 's/a/b/' f.txt"
check deny "sed -i.bak 's/a/b/' f.txt"
check deny "sed --in-place 's/a/b/' f.txt"
# パイプ内・-n の read-only 用途は許可
check allow "git log | sed -n '1,5p'"
check allow "sed -n '1,5p' f.txt"

# --- rule 7: gawk in-place ---
check deny "gawk -i inplace '{print}' f.txt"
check deny "gawk --include=inplace '{print}' f.txt"
check allow "awk '{print \$1}' f.txt"

# --- rule 8: 鍵・証明書 (deny) ---
check deny 'cat ~/.ssh/id_rsa'
check deny 'openssl x509 -in cert.pem -text'
# 公開鍵とテンプレートは除外
check allow 'cat ~/.ssh/id_rsa.pub'
# commit message 内の literal は path ではない
check allow 'git commit -m "add id_rsa handling"'

# --- rule 9: 機微ファイル (ask) ---
check ask 'cat .env'
check ask 'cat envs/prod/terraform.tfvars'
check ask 'ls ~/.aws'
check allow 'cat .env.example'
check allow 'git log --oneline -- .env'

# --- 対象外の入力 ---
check_raw allow 'tool_name=Read' '{"tool_name": "Read", "tool_input": {"file_path": "/etc/passwd"}}'
check_raw allow 'empty command' '{"tool_name": "Bash", "tool_input": {"command": ""}}'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

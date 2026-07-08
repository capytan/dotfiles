#!/bin/bash
# PreToolUse hook: 危険なコマンドを実行前にブロック
# Claude Code の PreToolUse イベントで呼び出される
# stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# stdout: {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}} でブロック
# fail-open 方針: set -euo pipefail を使わず、jq 欠損時などは黙って allow (validator が二次的な信頼できないゲートである前提)

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Bash ツールのみ対象
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# 空コマンドは早期 allow
[ -z "$COMMAND" ] && exit 0

# deny 出力ヘルパ: 現行 Claude Code hook 契約 (hookSpecificOutput.permissionDecision) に準拠
deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# segment 境界 ([^|;&`]*) を挟むことで、globaloption や `cd && sed -i` のような連結を吸収しつつ
# `git status && git push origin main` のような cross-segment 混同を防ぐ

# 1. git push --force / -f / +refspec をブロック
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bpush\b[^|;&`]*(--force\b|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*|[[:space:]]\+[[:alnum:]_/@.^~:-])'; then
  deny "git push --force / +refspec は上流の履歴を破壊する危険があります。通常の git push を使用してください。どうしても force push が必要な場合はユーザーに明示的な確認を求めてください。"
fi

# 2. git reset --hard をブロック
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\breset\b[^|;&`]*--hard\b'; then
  deny "git reset --hard はコミットされていない変更を失います。代わりに git stash でスタッシュするか、バックアップブランチを作成してください。"
fi

# 3. git clean -f をブロック
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bclean\b[^|;&`]*(-[a-zA-Z]*f[a-zA-Z]*|--force\b)'; then
  deny "git clean -f は追跡されていないファイルを削除します。先に git clean -n でプレビューしてから、ユーザーに確認を求めてください。"
fi

# 4. git branch 強制削除をブロック: -D / combined -df|-fd / space-separated -d ... -f (双方向) / --delete --force (双方向)
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bbranch\b[^|;&`]*(-[a-zA-Z]*D\b|-[a-zA-Z]*d[a-zA-Z]*f\b|-[a-zA-Z]*f[a-zA-Z]*d\b|-d\b[^|;&`]*-f\b|-f\b[^|;&`]*-d\b|--delete\b[^|;&`]*--force\b|--force\b[^|;&`]*--delete\b)'; then
  deny "git branch の強制削除 (-D / -d -f / --delete --force) は取り消せません。安全な git branch -d を使用するか、削除前にユーザーに確認を求めてください。"
fi

# 5. rm -rf をブロック (-rf, -fr, -R+f, --recursive + --force のあらゆる組み合わせ)
if echo "$COMMAND" | grep -qE '\brm\b[^|;&`]*(-[a-zA-Z]*[rR][a-zA-Z]*f\b|-[a-zA-Z]*f[a-zA-Z]*[rR]\b|(-[rR]\b|--recursive\b)[^|;&`]*(-f\b|--force\b)|(-f\b|--force\b)[^|;&`]*(-[rR]\b|--recursive\b))'; then
  deny "rm -rf は復元不可能なファイル削除です。個別ファイルを指定するか、ユーザーに明示的な確認を求めてください。"
fi

# 6. sed の in-place 編集をブロック (`-i`, `-i.bak`, `-i ''`, `--in-place` すべて対象)
# パイプ内の read-only 用途 (git log | sed ...) や `sed -n 1,5p` は許可
if echo "$COMMAND" | grep -qE '\b(g)?sed\b[[:space:]][^|;&`]*(-i([[:space:]]|\.|=|$)|--in-place\b)'; then
  deny "sed の in-place 編集 (-i / --in-place) の代わりに Edit ツールを使用してください。read-only な用途 (sed -n, cmd | sed ...) は許可されています。"
fi

# 7. gawk の in-place 編集をブロック (`gawk -i inplace`)
# read-only な awk (awk '{print}' file 等) は許可
if echo "$COMMAND" | grep -qE '\b(g|n)?awk\b[[:space:]][^|;&`]*-i[[:space:]]+inplace\b'; then
  deny "gawk -i inplace の代わりに Edit ツールを使用してください。read-only な awk は許可されています。"
fi

exit 0

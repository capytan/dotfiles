#!/bin/bash
# PreToolUse hook: 危険なコマンドを実行前にブロック
# Claude Code の PreToolUse イベントで呼び出される
# stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# stdout: {"permissionDecision": "deny", "message": "..."} でブロック

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Bash ツールのみ対象
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 1. git push --force / -f をブロック（通常 push は ask リストで確認）
if echo "$COMMAND" | grep -qE 'git(\s+-C\s+\S+)?\s+push\s+.*(-f\b|--force)'; then
  jq -n '{"permissionDecision": "deny", "message": "git push --force は上流の履歴を破壊する危険があります。通常の git push を使用してください。どうしても force push が必要な場合はユーザーに明示的な確認を求めてください。"}'
  exit 0
fi

# 2. git reset --hard をブロック
if echo "$COMMAND" | grep -qE 'git(\s+-C\s+\S+)?\s+reset\s+--hard'; then
  jq -n '{"permissionDecision": "deny", "message": "git reset --hard はコミットされていない変更を失います。代わりに git stash でスタッシュするか、バックアップブランチを作成してください。"}'
  exit 0
fi

# 3. git clean -f をブロック（未追跡ファイルを削除）
if echo "$COMMAND" | grep -qE 'git(\s+-C\s+\S+)?\s+clean\s+.*-[a-zA-Z]*f'; then
  jq -n '{"permissionDecision": "deny", "message": "git clean -f は追跡されていないファイルを削除します。先に git clean -n でプレビューしてから、ユーザーに確認を求めてください。"}'
  exit 0
fi

# 4. git branch -D をブロック（大文字 -D のみ。安全な -d は許可）
if echo "$COMMAND" | grep -qE 'git(\s+-C\s+\S+)?\s+branch\s+.*-[a-zA-Z]*D'; then
  jq -n '{"permissionDecision": "deny", "message": "git branch -D は強制削除です。安全な git branch -d を使用するか、削除前にユーザーに確認を求めてください。"}'
  exit 0
fi

# 5. rm -rf をブロック（-rf, -fr, -r -f, -f -r のすべての形式）
if echo "$COMMAND" | grep -qE '\brm\b.*-[a-zA-Z]*r[a-zA-Z]*f|\brm\b.*-[a-zA-Z]*f[a-zA-Z]*r|\brm\b.*(-r\b.*-f\b|-f\b.*-r\b)|\brm\b.*--recursive'; then
  jq -n '{"permissionDecision": "deny", "message": "rm -rf は復元不可能なファイル削除です。個別ファイルを指定するか、ユーザーに明示的な確認を求めてください。"}'
  exit 0
fi

# 6. sed をコマンド先頭でブロック（ファイル直接編集を防ぐ）
# パイプ内（例: git log | sed ...）は許可
if echo "$COMMAND" | grep -qE '^\s*sed\s'; then
  jq -n '{"permissionDecision": "deny", "message": "sed の代わりに Edit ツールを使用してファイルを編集してください。パイプの中間で使用する場合（例: cmd | sed ...）は許可されています。"}'
  exit 0
fi

# 7. awk をコマンド先頭でブロック（ファイル直接処理を防ぐ）
# パイプ内（例: git log | awk ...）は許可
if echo "$COMMAND" | grep -qE '^\s*awk\s'; then
  jq -n '{"permissionDecision": "deny", "message": "awk の代わりに Grep ツールを使用してください。パイプの中間で使用する場合（例: cmd | awk ...）は許可されています。"}'
  exit 0
fi

exit 0

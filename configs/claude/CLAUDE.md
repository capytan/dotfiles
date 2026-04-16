## Communication

- 応答言語: 日本語
- コード識別子・コマンド・エラーメッセージは原文維持
- 技術用語は日本語訳が曖昧なら原文を使う
- Diacritical marks と特殊文字は保持（"für" → "fur" のような置換禁止）
- 冗長な前置き（「承知しました」「はい、喜んで」等）は不要、直接本題へ

## Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- Verify symlinks (`ls -la ~ | grep dotfiles`) and test affected configs before committing
- Track cross-session TODOs in ~/dotfiles/tasks/todo.md
- Custom agents/skills live in ~/.claude/agents/ and ~/.claude/skills/ — glob before creating new ones
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

## Hooks

PreToolUse validators block dangerous patterns (force-push, reset --hard, rm -rf, standalone sed/awk). Source: `configs/claude/hooks/pretooluse-validate-command.sh`.
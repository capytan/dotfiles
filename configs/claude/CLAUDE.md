## Communication

- 応答言語: 日本語
- コード識別子・コマンド・エラーメッセージは原文維持
- 技術用語は日本語訳が曖昧なら原文を使う
- Diacritical marks と特殊文字は保持（"für" → "fur" のような置換禁止）
- 冗長な前置き（「承知しました」「はい、喜んで」等）は不要、直接本題へ

## Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- Custom agents/skills live in `~/.claude/agents/` and `~/.claude/skills/` — glob before creating new ones (dotfiles source: `~/dotfiles/configs/claude/{agents,skills,hooks}/`, all symlinked into `~/.claude/`). Path-scoped rules live in the repo-local `~/dotfiles/.claude/rules/` (not symlinked into `~/.claude/`)
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

## Hooks

- PreToolUse validators block dangerous patterns (force-push/`+refspec`, `reset --hard`, `git clean -f`, `git branch -D`, `rm -rf`, `sed -i`, `gawk -i inplace`). Deny output uses the `hookSpecificOutput.permissionDecision` schema; validators fail open. Source: `~/dotfiles/configs/claude/hooks/pretooluse-validate-command.sh`
- settings.json の `Read()`/`Write()` deny・ask は Read/Write ツールにのみ適用され、Bash 経由の `cat`/`head`/`tail`/`echo`/`printf` は素通り。秘密ファイルへの Bash アクセスは validator でも塞いでいないので、コマンド組み立て時にエージェント側で回避する
- tmux window-name emoji state: ⏳ working / 🤖 subagent / ⚠️ permission/error / ❌ tool failure / ✅ stop. **1 tmux window = 1 Claude Code pane** (panes in the same window fight over the name)
- tmux ops: log `tail -F ~/.cache/claude-tmux-status.log`, disable `export CLAUDE_TMUX_LOG=0`. Engineering details (priority table, force-update events, ✅→⏳ reset) live in `~/dotfiles/.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`)

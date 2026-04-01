@RTK.md

# Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions
- Verify symlinks (`ls -la ~ | grep dotfiles`) and test affected configs before committing
- Track cross-session TODOs in ~/dotfiles/tasks/todo.md
- Custom agents/skills は ~/.claude/agents/ と ~/.claude/skills/ に配置済み — 新規作成前に glob で確認

# Hook System

PreToolUse hooks が安全性を保証:
- Blocked: `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, `rm -rf`, standalone `sed`/`awk`（piped 利用は可）
- RTK: コマンドは自動的に rtk に書き換えられる。手動で `rtk` prefix を付けないこと。

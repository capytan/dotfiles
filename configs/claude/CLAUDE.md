@RTK.md

# Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions
- Verify symlinks (`ls -la ~ | grep dotfiles`) and test affected configs before committing
- Track cross-session TODOs in ~/dotfiles/tasks/todo.md
- Custom agents/skills live in ~/.claude/agents/ and ~/.claude/skills/ — glob before creating new ones

# Hook System

PreToolUse hooks enforce safety:
- Blocked: `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`, `rm -rf`, standalone `sed`/`awk` (piped usage is allowed)
- RTK: Commands are automatically rewritten to rtk. Do not manually add `rtk` prefix.

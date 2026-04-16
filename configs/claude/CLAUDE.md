
# Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- Verify symlinks (`ls -la ~ | grep dotfiles`) and test affected configs before committing
- Track cross-session TODOs in ~/dotfiles/tasks/todo.md
- Custom agents/skills live in ~/.claude/agents/ and ~/.claude/skills/ — glob before creating new ones

# Hooks

PreToolUse validators block dangerous patterns (force-push, reset --hard, rm -rf, standalone sed/awk). Source: `configs/claude/hooks/pretooluse-validate-command.sh`.
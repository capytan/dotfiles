
# Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- Verify symlinks (`ls -la ~ | grep dotfiles`) and test affected configs before committing
- Track cross-session TODOs in ~/dotfiles/tasks/todo.md
- Custom agents/skills live in ~/.claude/agents/ and ~/.claude/skills/ — glob before creating new ones
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

# Hooks

PreToolUse validators block dangerous patterns (force-push, reset --hard, rm -rf, standalone sed/awk). Source: `configs/claude/hooks/pretooluse-validate-command.sh`.
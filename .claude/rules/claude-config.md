---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- Hooks must use shared functions from `configs/claude/hooks/tmux-lib.sh`
- Keep permissions comments in settings.json (`// Git operations` etc.)
- Update `setup-claude.sh` when adding new symlink targets
- Use `set -euo pipefail` in hook scripts (except tmux hooks — guard pattern `tmux_guard || exit 0` and emoji matching conflict with `-e`/`-u`)

## tmux status emoji priority model

| emoji | priority | meaning |
|---|---|---|
| ⚠️ | 50 | Awaiting user / API error (permission_prompt / idle_prompt / elicitation_dialog / StopFailure) |
| ❌ | 40 | Tool failure (PostToolUseFailure) |
| ✅ | 30 | Response complete (Stop) |
| 🤖 | 20 | Subagent running (SubagentStart, when counter == 1) |
| ⏳ | 10 | Working (SessionStart / UserPromptSubmit / PostToolUse) |

When adding a new hook, choose one of the three `tmux-lib.sh` APIs:

- `tmux_force_set_status <emoji> <hook> [<base>]` — force update, ignores priority. For new-turn / completion events only
- `tmux_set_status_if_priority_allows <emoji> <hook>` — update only when `new >= current`. Default choice
- `tmux_demote_status <from> <to> <hook>` — downgrade only when current matches `<from>`. Used by SubagentStop (🤖→⏳)

Each hook must call `_tmux_init_session "$(cat)"` first (extracts `session_id` from stdin for log lines).

Log: `tail -F ~/.cache/claude-tmux-status.log`. Disable with `CLAUDE_TMUX_LOG=0`.

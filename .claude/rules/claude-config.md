---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- Hooks must use shared functions from `configs/claude/hooks/tmux-lib.sh`
- Don't put `//` comments in the `permissions` arrays — Claude Code v2.1.216+ warns on unknown deny/ask rules (`"// ..." matches no known tool`). File rules must use `Edit()`/`Read()`, not `Write()`/`Glob()` (file permission checks only consult those two forms; `Write()`/`Glob()` are silently ignored)
- Update `setup-claude.sh` when adding new symlink targets
- Use `set -euo pipefail` in hook scripts (except tmux hooks — guard pattern `tmux_guard || exit 0` and emoji matching conflict with `-e`/`-u` — and `pretooluse-validate-command.sh` — validators must fail open; with `-e` a jq parse failure exits 2, which PreToolUse treats as "block all commands")

## tmux status emoji priority model

| emoji | priority | meaning |
|---|---|---|
| ⚠️ | 50 | Awaiting user / API error (permission_prompt / idle_prompt / elicitation_dialog / StopFailure) |
| ❌ | 40 | Tool failure (PostToolUseFailure) |
| ✅ | 30 | Response complete (Stop) |
| 🤖 | 20 | Subagent running (SubagentStart, when counter == 1) |
| ⏳ | 10 | Working (SessionStart / UserPromptSubmit / PostToolUse) |

Priority-guarded: a higher-priority state is not overwritten by a lower one. Only `UserPromptSubmit` / `Stop` / `StopFailure` / `SessionStart` force-update. ✅ is reset to ⏳ on the next `UserPromptSubmit`, and ⚠️/❌ is demoted to ⏳ on the next `PostToolUse` (permission approval / tool retry には解除イベントが無いので、次の tool 実行で自動回復させる)。

`SessionStart` の base name は既存の window 名 (絵文字剥ぎ後) を保持し、空のときのみ `basename $PWD` にフォールバックする。これで `tmux-start.local.sh` 等で明示した window 名を上書きしない。

When adding a new hook, choose one of the four `tmux-lib.sh` APIs:

- `tmux_force_set_status <emoji> <hook> [<base>]` — force update, ignores priority. For new-turn / completion events only
- `tmux_set_status_if_priority_allows <emoji> <hook>` — update only when `new >= current`. Default choice
- `tmux_set_status_or_demote_alert <emoji> <hook>` — same as priority-allows, but also demotes ⚠️/❌ regardless of `new`. Used by `PostToolUse` to recover from permission-approval / tool-retry
- `tmux_demote_status <from> <to> <hook>` — downgrade only when current matches `<from>`. Used by SubagentStop (🤖→⏳)

Skip logs (`reason=priority_too_low`) are suppressed by default because `PostToolUse` fires very frequently. Enable with `CLAUDE_TMUX_LOG_SKIP=1` for debugging.

Each hook must call `_tmux_hook_init "$(cat)"` first (runs `tmux_guard` and extracts `session_id` from stdin for log lines).

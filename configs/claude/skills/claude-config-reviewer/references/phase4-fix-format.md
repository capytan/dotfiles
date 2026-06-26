---
name: phase4-fix-format
description: Phase 4 fix-proposal template and token-savings table examples for the claude-config-reviewer skill
last_updated: 2026-06-26
---

# Phase 4 Fix Format

The claude-config-reviewer skill's Phase 4 presents each fix as a diff with quantified token impact, then a savings summary. This file holds the full template and a worked example — kept out of SKILL.md to reduce always-loaded token cost.

## Per-fix template

```markdown
### Fix N: [file path] — [Section Name]

**Reason:** [one-line why this fix is needed]
**Severity:** [Critical / Major / Minor]
**Lines:** [current] → [proposed] (−N lines, ~M tokens saved)

\```diff
- removed line
+ added line
\```
```

## Savings summary template

After all individual fixes, include:

```markdown
### Token Savings Summary

| Section | Action | Lines Saved | ~Tokens Saved |
|---------|--------|-------------|---------------|
| ... | ... | ... | ... |
| **Total** | | **−N** | **~M** |

**Before:** X lines (~Y tokens) → **After:** X' lines (~Y' tokens)
```

## Token estimation

Rough conversion only — not exact:

- English: word count × ~1.3
- Japanese / mixed Japanese-English: character count × ~0.5 (or ~2.0 per word equivalent)

Use the proposal's actual diff lines, not the file's total length, when computing per-section savings.

## Worked example

```markdown
### Fix 1: configs/claude/CLAUDE.md — Hooks / tmux status emoji

**Reason:** Engineering details (priority table, force-update events, ✅→⏳ reset) only matter to hook authors but are loaded into every global session. Move to path-scoped `.claude/rules/claude-config.md`.
**Severity:** Minor
**Lines:** 26 → 18 (−8 lines, ~120 tokens saved per session)

\```diff
- ### tmux status emoji
-
- Each hook prefixes the tmux window name with a state emoji (...). Priority-guarded: a higher-priority state is not overwritten by a lower one (full priority table in `~/dotfiles/.claude/rules/claude-config.md`). Only `UserPromptSubmit` / `Stop` / `StopFailure` / `SessionStart` force-update.
-
- - Log: `tail -F ~/.cache/claude-tmux-status.log` (key=value, rotates to `.1` at 1MB)
- - Disable: `export CLAUDE_TMUX_LOG=0`
- - Rule: **1 tmux window = 1 Claude Code pane** — multiple panes in the same window will fight over the name
- - ✅ is reset to ⏳ on the next `UserPromptSubmit` (response-complete is preserved until the user takes a new turn)
+ - tmux window-name emoji state: ⏳ working / 🤖 subagent / ⚠️ permission/error / ❌ tool failure / ✅ stop. **1 tmux window = 1 Claude Code pane** (panes in the same window fight over the name). Log: `tail -F ~/.cache/claude-tmux-status.log`. Disable: `export CLAUDE_TMUX_LOG=0`. Engineering details (priority table, force-update events, ✅→⏳ reset) live in `~/dotfiles/.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`)
\```

### Token Savings Summary

| Section | Action | Lines Saved | ~Tokens Saved |
|---------|--------|-------------|---------------|
| Hooks / tmux | Move engineering details to path-scoped rules file | −8 | ~120 |
| **Total** | | **−8** | **~120** |

**Before:** 26 lines (~390 tokens) → **After:** 18 lines (~270 tokens)
```

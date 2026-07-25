---
name: phase4-fix-format
description: Phase 4 fix-proposal template and token-savings table examples for the claude-config-reviewer skill
last_updated: 2026-07-25
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

## Worked example (synthetic)

```markdown
### Fix 1: skills/example-skill/SKILL.md — Phase 2 worked example

**Reason:** Worked example only needed when authoring new skills; loaded on every invocation. Move to `references/worked-examples.md`.
**Severity:** Minor
**Lines:** 64 → 38 (−26 lines, ~390 tokens saved per session)

\```diff
- ## Worked Example
-
- (... 26 lines of tutorial walk-through ...)
+ See [references/worked-examples.md](references/worked-examples.md) for full walk-throughs.
\```

### Token Savings Summary

| Section | Action | Lines Saved | ~Tokens Saved |
|---------|--------|-------------|---------------|
| Worked Example | Move to on-demand reference | −26 | ~390 |
| **Total** | | **−26** | **~390** |

**Before:** 64 lines (~960 tokens) → **After:** 38 lines (~570 tokens)
```

# SKILL.md Anti-Pattern Catalog

> Referenced during Phase 2, criterion G (Anti-patterns) for SKILL.md reviews.
> Each pattern has a severity: Critical / Major / Minor.

---

## Major -- Strongly Recommended to Fix

### Windows-Style Paths `[custom:derived-from-skill-reviewer]`
Backslashes in file references (`.\folder\file`, `C:\Users\...`).
**Fix:** Use forward slashes exclusively.

### Option Listing Without Default `[custom:derived-from-skill-reviewer]`
Multiple options/approaches listed without indicating which to use by default.
**Fix:** Mark the default choice; specify how/when to escape to alternatives.

### Critical Instructions Buried Past Line 200 `[custom:derived-from-skill-reviewer]`
"MUST"/"NEVER"/"ALWAYS" keywords or safety rules appearing after line 200.
**Fix:** Move critical instructions to the top 100 lines; push details into references/.

### Hedging Language for Required Actions `[custom:derived-from-skill-reviewer]`
Tentative language ("might", "could", "consider", "you may want to") for mandatory steps.
**Fix:** Use imperative: "must", "always", "never". Reserve hedging for genuinely optional guidance.

### Oversized SKILL.md Without Splitting `[custom:derived-from-skill-reviewer]`
Over 500 lines without offloading to `references/`; over 300 lines with all content inline.
**Fix:** Split complex details into references/. Keep SKILL.md as orchestrator under 500 lines.

### Redundant Content Claude Already Knows `[custom:derived-from-skill-reviewer]`
Basic git commands, standard HTTP methods, common framework patterns, generic advice.
**Fix:** Delete. Include only project-specific deltas and non-obvious behavior.

---

## Minor -- Recommended to Improve

### Inconsistent Terminology `[custom:derived-from-skill-reviewer]`
Same concept referred to by different names ("endpoint"/"URL"/"route" for one thing).
**Fix:** One term per concept. Add a terminology note if needed.

### Missing Error Handling Specificity `[custom:derived-from-skill-reviewer]`
Generic instructions ("handle errors gracefully") without concrete error types or recovery.
**Fix:** Specify error types and resolutions. Include fallback behavior.

### Unreferenced Resources `[custom:derived-from-skill-reviewer]`
`scripts/`, `references/`, or `assets/` directories exist but SKILL.md never mentions them.
**Fix:** Explicitly reference all bundled resources with paths and usage context.

---

## Changelog

- 2026-03-29: Initial version. Derived from skill-reviewer agent check items. All items tagged `[custom:derived-from-skill-reviewer]` pending Phase 0 research.

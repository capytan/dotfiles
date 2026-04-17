# SKILL.md Anti-Pattern Catalog

> Referenced during Phase 2, criterion G (Anti-patterns) for SKILL.md reviews.
> Each pattern has a severity: Critical / Major / Minor.

last_updated: 2026-04-17

---

## Critical -- Must Fix

### First-Person or Second-Person Description `[official]`
Description uses "I can help you..." or "You can use this..." instead of third person.
`[official]` quote: "The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems." — platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
**Fix:** Rewrite in third person ("Processes Excel files and generates reports").

### Description Over 1024 Characters `[official]`
Exceeds the hard validation cap; content beyond 1024 chars is silently truncated.
**Fix:** Trim to under 1024 chars. Front-load key triggers; move overflow into `when_to_use`. The listing cap is 1,536 chars combined (`description` + `when_to_use`).

### Missing `disable-model-invocation` on Side-Effect Skills `[community:high]`
Skills that deploy, commit, push, delete, or send messages without `disable-model-invocation: true` — Claude may trigger them unprompted.
**Fix:** Add `disable-model-invocation: true` to any skill whose actions cannot be safely auto-triggered.

---

## Major -- Strongly Recommended to Fix

### Windows-Style Paths `[official]`
Backslashes in file references (`.\folder\file`, `C:\Users\...`).
`[official]` quote: "Always use forward slashes in file paths, even on Windows... Unix-style paths work across all platforms, while Windows-style paths cause errors on Unix systems."
**Fix:** Use forward slashes exclusively.

### Option Listing Without Default `[official]`
Multiple options/approaches listed without indicating which to use by default ("You can use pypdf, or pdfplumber, or PyMuPDF...").
**Fix:** Pick a default; specify how/when to escape to alternatives ("Use pdfplumber for text; for scanned PDFs use pdf2image with pytesseract.").

### Nested References (More Than One Level Deep) `[official]`
SKILL.md → `advanced.md` → `details.md` chains.
`[official]` quote: "Claude may partially read files when they're referenced from other referenced files... Claude might use commands like `head -100` to preview content... resulting in incomplete information."
**Fix:** Flatten so every reference links directly from SKILL.md. Move shared content up, or inline.

### Reference File Over 100 Lines Without TOC `[official]`
Long reference files without a table of contents at the top.
`[official]` quote: "For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads."
**Fix:** Add a `## Contents` block listing sub-sections.

### Critical Instructions Buried Past Line 200 `[custom:derived-from-skill-reviewer]`
"MUST"/"NEVER"/"ALWAYS" keywords or safety rules appearing after line 200.
**Fix:** Move critical instructions to the top; push details into `references/`.

### Hedging Language for Required Actions `[custom:derived-from-skill-reviewer]`
Tentative language ("might", "could", "consider", "you may want to") for mandatory steps.
**Fix:** Use imperative: "must", "always", "never". Reserve hedging for genuinely optional guidance.

> Counter-note from skill-creator `[semi-official]`: "If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag — if possible, reframe and explain the reasoning so that the model understands why the thing you're asking for is important."

### Oversized SKILL.md Without Splitting `[official]`
Over 500 lines without offloading to `references/`; over 300 lines with all content inline.
`[official]` quote: "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."
**Fix:** Split complex details into `references/`. Keep SKILL.md as orchestrator under 500 lines.

### Redundant Content Claude Already Knows `[official]`
Basic git commands, standard HTTP methods, common framework patterns, generic advice.
`[official]` quote: "Only add context Claude doesn't already have. Challenge each piece of information: 'Does Claude really need this explanation?' 'Can I assume Claude knows this?' 'Does this paragraph justify its token cost?'"
**Fix:** Delete. Include only project-specific deltas and non-obvious behavior.

### README.md or CHANGELOG.md Inside Skill Directory `[community:high]`
Human-oriented docs bundled in a skill folder that Claude has to scan.
Quote: "Skills are for agents, not humans... Do not create: Documentation files: README.md, CHANGELOG.md, or INSTALLATION_GUIDE.md." — github.com/mgechev/skills-best-practices
**Fix:** Delete, or move to the parent repo's README. Keep skill-local content agent-actionable.

### Time-Sensitive Content in Main Body `[official]`
"After August 2025 use the new API" written in prose.
`[official]` quote: "Don't include information that will become outdated."
**Fix:** Move into a collapsed `<details>` block titled "Old patterns (deprecated YYYY-MM)" rather than inline dates.

### Voodoo Constants in Scripts `[official]`
`TIMEOUT = 47  # Why 47?` — unexplained magic numbers.
**Fix:** Document each constant with a reason ("30s accounts for slow connections", "3 retries balances reliability vs speed").

### Unqualified MCP Tool References `[official]`
Using `bigquery_schema` instead of `BigQuery:bigquery_schema`.
`[official]` quote: "Without the server prefix, Claude may fail to locate the tool, especially when multiple MCP servers are available."
**Fix:** Always use `ServerName:tool_name` format.

### Punting to Claude in Scripts `[official]`
Scripts that just call `open(path)` and let Claude handle failures.
**Fix:** Handle known error conditions explicitly (FileNotFoundError, PermissionError) with fallbacks and useful log output.

---

## Minor -- Recommended to Improve

### Inconsistent Terminology `[official]`
Same concept referred to by different names ("endpoint"/"URL"/"route" for one thing).
**Fix:** One term per concept. Add a terminology note if needed.

### Missing Error Handling Specificity `[custom:derived-from-skill-reviewer]`
Generic instructions ("handle errors gracefully") without concrete error types or recovery.
**Fix:** Specify error types and resolutions. Include fallback behavior.

### Unreferenced Resources `[custom:derived-from-skill-reviewer]`
`scripts/`, `references/`, or `assets/` directories exist but SKILL.md never mentions them.
**Fix:** Explicitly reference all bundled resources with paths and usage context.

### Overfitting Descriptions with Specific Queries `[semi-official]`
Description lists dozens of exact user phrases instead of generalizing intent.
Quote: "No Overfitting: Avoid lists of specific queries; instead, generalize to categories of intent." — skill-creator improve_description.py
**Fix:** Describe the category of intent ("when analyzing spreadsheets or tabular data"), not a catalog of verbatim phrases.

### Vague Name (`helper`, `utils`, `tools`) `[official]`
Generic names that do not describe the skill's activity.
**Fix:** Use gerund form (`processing-pdfs`) or action-oriented names (`deploy-staging`). Avoid reserved words (`anthropic`, `claude`).

### No "Gotchas" Section for Observed Failures `[community:high]`
Skill has accumulated real-world failure cases but nothing is documented.
**Fix:** Add a `## Gotchas` section and append observed failure modes over time — highest-signal content in mature skills.

### Railroaded Prescriptive Steps `[community:high]`
Skill dictates every micro-step, removing Claude's ability to adapt to context.
Quote: "Don't railroad Claude in skills — give goals and constraints, not prescriptive step-by-step instructions." — shanraisshan/claude-code-best-practice
**Fix:** State goals and hard constraints; leave tactical decisions to Claude unless the task is fragile.

---

## Changelog

- 2026-03-29: Initial version. Derived from skill-reviewer agent check items. All items tagged `[custom:derived-from-skill-reviewer]` pending Phase 0 research.
- 2026-04-17: Major expansion against 2026-04 official docs. Added Critical tier (3 items: first/second-person description, >1024-char description, missing `disable-model-invocation` on side-effect skills). Promoted Windows-style paths, option listing without default, and oversized SKILL.md from `[custom:...]` to `[official]` with source quotes. Added 7 new patterns: nested references, reference file >100 lines without TOC, README/CHANGELOG in skill dir, time-sensitive content in body, voodoo constants, unqualified MCP tool refs, punting to Claude in scripts. Added minor patterns: overfitting descriptions, vague names, missing Gotchas, railroaded prescriptive steps. Added a counter-note about not over-using ALL-CAPS MUST/NEVER (skill-creator guidance).

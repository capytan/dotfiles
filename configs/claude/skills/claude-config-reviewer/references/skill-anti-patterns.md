# SKILL.md Anti-Pattern Catalog

> Referenced during Phase 2, criterion G (Anti-patterns) for SKILL.md reviews.
> Each pattern has a severity: Critical / Major / Minor.

last_updated: 2026-09-04

---

## Contents

- Critical -- Must Fix
- Major -- Strongly Recommended to Fix
- Minor -- Recommended to Improve

## Critical -- Must Fix

### First-Person or Second-Person Description `[official]`
Description uses "I can help you..." or "You can use this..." instead of third person.
`[official]` quote: "The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems." — platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
**Fix:** Rewrite in third person ("Processes Excel files and generates reports").

### Description Over 1,536 Characters Combined `[official]`
The combined `description` + `when_to_use` text is truncated at 1,536 chars in the skill listing, so triggers past that point never reach Claude. (Revised 2026-07-25: the previously-recorded 1024-char hard field cap is no longer stated in official docs — do not flag on the 1024 figure alone.)
**Fix:** Keep `description` + `when_to_use` under 1,536 chars combined and front-load key triggers.

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

### Injected Command That Aborts the Invocation `[official]` (added 2026-09-04)
A `` !`command` `` (or ` ```! ` block) that can exit non-zero without `|| true`, or that matches an **ask or deny** permission rule. "A failed command aborts the entire skill invocation, not just its own placeholder. Claude never sees the skill content for that invocation." Injected commands never prompt: a rule that would normally ask you aborts instead, **regardless of `allowed-tools`**. Only exit code 1 from the search/comparison carveout (e.g. `grep`, `git diff`) is tolerated; exit ≥2 always fails.
**Fix:** Append `|| true` to commands expected to exit non-zero (check scripts that exit 1 on findings, etc.); pre-approve unmatched commands with `allowed-tools`; remove or rework commands that hit ask/deny rules.

### Content Before the Frontmatter Marker `[official]` (added 2026-09-04)
Anything before the opening `---` — blank lines, comments, a UTF-8 BOM. "Claude Code reads the frontmatter only when the opening `---` is the file's first line. Otherwise it treats the whole file, `---` markers included, as skill content", losing name/description/all fields. A BOM made the file **silently ignored entirely** before v2.1.243.
**Fix:** Ensure `---` is byte one of the file; strip BOMs. Diagnose with `claude plugin validate <skills-dir>` (v2.1.233+).

### Broad `allowed-tools` in a Repo-Committed Skill `[official]` (added 2026-09-04)
A project skill checked into a shared repository with wide grants such as `Bash(*)`. "Workspace trust doesn't gate this field... A skill can grant itself broad tool access, so review the `allowed-tools` of skills checked into a repository before you run Claude Code there" — the grant applies even in a `-p` run in an untrusted folder.
**Fix:** Scope grants to exact commands, ideally via the `${CLAUDE_SKILL_DIR}`-paired script pattern (`Bash(${CLAUDE_SKILL_DIR}/scripts/x.sh *)`).

### Skill Directory Named `synced` `[official]` (added 2026-09-04)
The folder name `synced` (any capitalization) is reserved in the enterprise/personal/project skills locations for skills downloaded from claude.ai; Claude Code "skips a skill you author at that name" — the skill never loads.
**Fix:** Rename the directory.

### Backgrounded `context: fork` Skill Needing an Excluded Tool `[official]` (added 2026-07-25)
A `context: fork` skill that leaves `background` at its `true` default while its body depends on a tool outside the narrower background-subagent tool set. The forked skill runs as a regular agent type, so the fork exemption does not cover it (v2.1.218).
**Fix:** Set `background: false` so the fork waits in the invoking turn and keeps the full tool set. Flag Major only when the body's core workflow provably needs an excluded tool — see cross-artifact-checks.md Check 9 for the single severity threshold.

---

## Minor -- Recommended to Improve

### Instructing Claude to Run `/verify` or `/code-review` `[official]` (added 2026-07-25)
As of v2.1.215 the **bundled** `/verify` and `/code-review` run only when the user invokes them, so an instruction to run them, or an agent `skills:` entry preloading them, silently never fires.
**Fix:** Inline the steps, or have the user invoke the command. Carve-out: if a local or enabled-plugin skill of the same name overrides the bundled one, it is model-invocable again — check before flagging (cross-artifact-checks.md Checks 8 and 11).

### Hardcoded Absolute Paths to Bundled Files `[official]` (added 2026-09-04)
Body or `allowed-tools` referencing bundled scripts by absolute path (`/Users/me/.claude/skills/x/scripts/run.sh`). Breaks on relocation and other machines; injected commands also run in the session shell's cwd, which moves with `cd`.
**Fix:** Use `${CLAUDE_SKILL_DIR}` (or `${CLAUDE_PROJECT_DIR}` for project-local files) in both the body step and the matching `allowed-tools` Bash rule.

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

### `@`-Import Syntax in SKILL.md References `[community:high]`
Using `@path` import syntax (e.g. `@reference/finance.md`) to pull in a reference file. Unlike CLAUDE.md, SKILL.md does **not** support `@` imports — references are plain paths Claude reads on demand via the Read/bash tools.
Quote: "file references are NOT @ imports — they're instructions for the agent to use the Read tool. (@ imports only work in CLAUDE.md, not in SKILL.md.)" — community 2026 guides (MindStudio, sidsaladi)
**Fix:** Name the file by plain path inside the step that needs it ("See `reference/finance.md` for revenue metrics"). Make references explicit and prominent so Claude doesn't miss the connection.

### Railroaded Prescriptive Steps `[community:high]`
Skill dictates every micro-step, removing Claude's ability to adapt to context.
Quote: "Don't railroad Claude in skills — give goals and constraints, not prescriptive step-by-step instructions." — shanraisshan/claude-code-best-practice
**Fix:** State goals and hard constraints; leave tactical decisions to Claude unless the task is fragile.

---

## Changelog

- 2026-03-29: Initial version. Derived from skill-reviewer agent check items. All items tagged `[custom:derived-from-skill-reviewer]` pending Phase 0 research.
- 2026-05-30: Minor refresh. Added one Minor anti-pattern: `@`-import syntax in SKILL.md references (`@` imports only work in CLAUDE.md; SKILL.md references are Read-tool instructions) `[community:high]`. Re-verified all existing Critical/Major/Minor patterns against 2026-05 official + community sources — no severity changes, no removals.
- 2026-04-17: Major expansion against 2026-04 official docs. Added Critical tier (3 items: first/second-person description, >1024-char description, missing `disable-model-invocation` on side-effect skills). Promoted Windows-style paths, option listing without default, and oversized SKILL.md from `[custom:...]` to `[official]` with source quotes. Added 7 new patterns: nested references, reference file >100 lines without TOC, README/CHANGELOG in skill dir, time-sensitive content in body, voodoo constants, unqualified MCP tool refs, punting to Claude in scripts. Added minor patterns: overfitting descriptions, vague names, missing Gotchas, railroaded prescriptive steps. Added a counter-note about not over-using ALL-CAPS MUST/NEVER (skill-creator guidance).
- 2026-06-10: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-06-10). No new anti-patterns; severities re-verified. Note: 2026 frontmatter fields (`when_to_use`, `arguments`, `disallowed-tools`, `effort`, `paths`, `shell`, `hooks`) are official — do not flag as unknown.
- 2026-06-26: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-06-26). No new anti-patterns; catalog re-verified. Assessor notes (negative findings worth flagging): (1) **Frontmatter keys** are case-tolerant (kebab/snake/camelCase all accepted as of changelog v2.1.186) — do NOT flag camelCase variants. (2) **Malformed YAML** still loads the skill body with empty metadata, so a "missing description" can be a YAML parse failure rather than an author omission — recommend running with `--debug` to disambiguate. (3) **Naming collision with bundled skills**: if a project/personal/plugin skill shares a name with a bundled skill (e.g. `code-review`, `debug`, `loop`), it silently replaces the bundled one — surface as advisory NOTE so authors realize they're overriding `/code-review`.
- 2026-07-25: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **One new Major anti-pattern**: a `context: fork` skill that leaves `background` at its `true` default while its body depends on a tool outside the **narrower background-subagent tool set** - the forked skill runs as a regular agent type, so the fork exemption does not cover it; the fix is `background: false` (v2.1.218). **One new Minor**: instructing Claude to run `/verify` or `/code-review` itself, or preloading them into a subagent - as of v2.1.215 only the user can invoke them, so the instruction silently never fires. **One de-escalation**: a `name` that differs from the skill's directory is **not** a defect in a personal or project skill - `name` sets only the display label there and the command comes from the directory name; keep the flag only for plugin skills, where `name` forms the command's last segment. **One tolerance note**: boolean frontmatter values `yes`/`no`/`on`/`off`/`1`/`0` in any case are valid as of v2.1.218 - do not flag them as malformed. last_updated bumped to 2026-07-25.
- 2026-09-04: Freshness re-run against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-09-04) and changelog v2.1.229-v2.1.260. **Three new Major anti-patterns**: (1) an injected `` !`command` `` that can exit non-zero without `|| true` or that matches an ask/deny permission rule — either aborts the **entire** invocation and Claude never sees the skill content; (2) content (blank lines/comments/UTF-8 BOM) before the opening `---` — frontmatter is parsed only when `---` is the file's first line, and a BOM silently hid the whole skill before v2.1.243; (3) broad `allowed-tools` (e.g. `Bash(*)`) in a repo-committed skill — the field is not workspace-trust-gated and applies even in untrusted `-p` runs. **One new Major**: a skill directory named `synced` (reserved, any capitalization — the skill is skipped entirely). **One new Minor**: hardcoded absolute paths to bundled files instead of `${CLAUDE_SKILL_DIR}`/`${CLAUDE_PROJECT_DIR}` in body + `allowed-tools`. **Assessor-note update**: overriding a bundled skill does NOT capture its aliases (a local `code-review` never receives `/review`; v2.1.248 fixed alias-keyed `skillOverrides`) — extend the 2026-06-26 naming-collision note accordingly. Diagnostic: `claude plugin validate <skills-dir>` (v2.1.233+) finds unparseable frontmatter. last_updated bumped to 2026-09-04.
- 2026-08-12: Freshness re-run against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-08-12) and changelog v2.1.219-v2.1.228. No new anti-patterns; catalog re-verified current. **New assessor note**: do **not** treat Claude Code-only frontmatter fields as an anti-pattern in Claude Code-only skills. They break only on the claude.ai upload / Skills API / `package_skill.py` paths, where the Agent Skills spec permits just `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` and an extra key is a hard error. **De-flag**: plugin/org skills named after terminal built-ins are invocable again (v2.1.221), so such a name is no longer a discoverability trap outside the still-reserved terminal-only built-ins. last_updated bumped to 2026-08-12.

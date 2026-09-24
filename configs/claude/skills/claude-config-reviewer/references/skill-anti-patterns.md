# SKILL.md Anti-Pattern Catalog

> Referenced during Phase 2, criterion G (Anti-patterns) for SKILL.md reviews.
> Each pattern has a severity: Critical / Major / Minor.

last_updated: 2026-09-24

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
> Now also `[official]` (added 2026-09-16): "Explain the why. Reasoning-based instructions ('Do X because Y tends to cause Z') work better than rigid directives ('ALWAYS do X, NEVER do Y'). Models follow instructions more reliably when they understand the purpose." — https://agentskills.io/skill-creation/evaluating-skills (linked from code.claude.com/docs/en/skills; retrieved 2026-09-16). Net rule: mandatory steps must be imperative and unhedged, but should carry a one-clause reason rather than bare ALL-CAPS.

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

### Injected Command That Aborts the Invocation `[official]` (added 2026-09-04, updated 2026-09-16)
A `` !`command` `` (or ` ```! ` block) that can exit non-zero without `|| true`, or that matches an **ask or deny** permission rule. "A failed command aborts the entire skill invocation, not just its own placeholder. Claude never sees the skill content for that invocation." Injected commands never prompt: a rule that would normally ask you aborts instead, **regardless of `allowed-tools`**. Only exit code 1 from the search/comparison carveout (e.g. `grep`, `git diff`) is tolerated; exit ≥2 always fails. Symptom strings: `Shell command failed for pattern "..."` / `Shell command permission check failed for pattern "..."`. Auto-mode nuance (2026-09-16): an ask-rule match doesn't abort in auto mode (the skill loads with a run-first instruction; v2.1.271), but does "in a forked skill that sets `agent`, and in a session where Claude doesn't have the shell tool"; a deny match aborts everywhere — severity unchanged.
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

### Unscoped `hooks:` in a Repo-Committed Skill `[official]` (added 2026-09-16)
A project skill checked into a shared repository whose frontmatter `hooks:` block runs an unreviewed `command` on a wide matcher (e.g. `PreToolUse` on `Bash` or `*`). "Skill hooks: Claude Code registers them when you or Claude invoke the skill and keeps running them for the rest of the session, on turns after the skill's own turn as well." and "Frontmatter hooks in a project skill follow the same workspace trust rule as hooks in settings files. Claude Code registers them when you or Claude invoke the skill, including in a `-p` run in a folder you haven't trusted." — https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents (retrieved 2026-09-16). The hook is executable code that outlives the skill's turn and bypasses the trust dialog.
**Fix:** Narrow the `matcher`; reference the script via `${CLAUDE_SKILL_DIR}`; set `once: true` on setup-style hooks so Claude Code removes the hook "after its first successful run"; review before running Claude Code in the repo. Presence of `hooks:` alone is not a finding.

### Backgrounded `context: fork` Skill Needing an Excluded Tool `[official]` (added 2026-07-25)
A `context: fork` skill that leaves `background` at its `true` default while its body depends on a tool outside the narrower background-subagent tool set. The forked skill runs as a regular agent type, so the fork exemption does not cover it (v2.1.218).
**Fix:** Set `background: false` so the fork waits in the invoking turn and keeps the full tool set. Flag Major only when the body's core workflow provably needs an excluded tool — see cross-artifact-checks.md Check 9 for the single severity threshold.

### Instruction to Reproduce Reasoning in the Response `[official]` (added 2026-09-24)
A skill step telling Claude to echo, transcribe, or "show" its internal reasoning/thinking in the response text ("write out your chain of thought before the verdict", "show your thinking in a <reasoning> block"). "Prompts, skills, or harness instructions that tell the model to echo, transcribe, or explain its internal reasoning as response text can trigger the `reasoning_extraction` refusal category on Claude Fable 5 … Audit existing skills and system prompts for reflection or show-your-thinking instructions when migrating." — platform.claude.com/…/prompting-claude-fable-5 (retrieved 2026-09-24); Opus 5.5 (default Opus since v2.1.280) adds the same category. A forked or preloaded skill carrying this line can make the whole invocation refuse.
**Fix:** Ask for the result plus its evidence/justification ("state the reason for each finding", "quote the failing line") instead of a reasoning transcript. Not a finding: rationale-for-result asks, or a skill that has Claude *write a plan file* as a deliverable.

---

## Minor -- Recommended to Improve

### Instructing Claude to Run `/verify` or `/code-review` `[official]` (added 2026-07-25)
As of v2.1.215 the **bundled** `/verify` and `/code-review` run only when the user invokes them, so an instruction to run them, or an agent `skills:` entry preloading them, silently never fires.
**Fix:** Inline the steps, or have the user invoke the command. Carve-out: if a local or enabled-plugin skill of the same name overrides the bundled one, it is model-invocable again — check before flagging (cross-artifact-checks.md Checks 8 and 11).

### Spec-Invalid `name` in an Export-Targeted Skill `[official]` (added 2026-09-16)
A skill explicitly meant for claude.ai upload, the Skills API, `package_skill.py`, or Cowork/cloud enablement whose `name` differs from its directory, or starts/ends with a hyphen, or contains `--`. The Agent Skills spec (https://agentskills.io/specification, retrieved 2026-09-16) requires `name` to "Must match the parent directory name", "Must not start or end with a hyphen (`-`)", "Must not contain consecutive hyphens (`--`)". Claude Code itself treats `name` as a display label in personal/project skills, so this is **not** a finding for Claude Code-only skills (see the 2026-07-25 de-escalation) — escalate to the criterion-A 4-pt band only when export is the stated target.
**Fix:** Make `name` equal the directory name and hyphen-clean; validate with `skills-ref validate ./my-skill`.

### Inert `name` / `paths` in a `.claude/commands/*.md` File `[official]` (added 2026-09-16)
Legacy command files accept "the same frontmatter except `name` and `paths`" (code.claude.com/docs/en/skills, retrieved 2026-09-16), so either field there does nothing.
**Fix:** Move the command to `.claude/skills/<name>/SKILL.md`, where both fields work and supporting files are allowed.

### Missing `once: true` on a One-Shot Frontmatter Hook `[official]` (added 2026-09-16)
The body describes the hook as initial setup ("install deps", "warm the cache") but the `hooks:` entry lacks `once: true`, so it re-fires on every matching event for the rest of the session.
**Fix:** Add `once: true`; Claude Code then removes the hook after its first successful run. Escalate to Major when the hook has side effects (writes, network, commits).

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
Now also `[official]` (2026-09-24): "Think of skills as lightweight guides to let Claude find information when needed. Avoid making them overconstrained, except in highly important areas." (Anthropic blog, claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models) and "Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality." (prompting-claude-fable-5).

### Generic Self-Verification Steps `[official]` (added 2026-09-24)
Steps like "double-check your work before responding", "add a final verification step", "spawn a subagent to verify your output" with **no concrete check** behind them. Opus 5: "If your prompt contains explicit verification instructions ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality. The same applies to legacy harness scaffolding that adds separate verification steps." — platform.claude.com/…/prompting-claude-opus-5 (retrieved 2026-09-24). Opus 5.5: "Existing Claude Opus 5 prompts should perform well without changes".
**Not a finding:** a validator/test/script run in a feedback loop (official platform pattern), or an explicit evaluator stage whose independence is the point of the skill (e.g. a review skill that dispatches a separate scorer). **Fix:** delete the generic line, or replace it with the concrete command that produces a pass/fail.

---

## Changelog

- 2026-03-29: Initial version. Derived from skill-reviewer agent check items. All items tagged `[custom:derived-from-skill-reviewer]` pending Phase 0 research.
- 2026-05-30: Minor refresh. Added one Minor anti-pattern: `@`-import syntax in SKILL.md references (`@` imports only work in CLAUDE.md; SKILL.md references are Read-tool instructions) `[community:high]`. Re-verified all existing Critical/Major/Minor patterns against 2026-05 official + community sources — no severity changes, no removals.
- 2026-04-17: Major expansion against 2026-04 official docs. Added Critical tier (3 items: first/second-person description, >1024-char description, missing `disable-model-invocation` on side-effect skills). Promoted Windows-style paths, option listing without default, and oversized SKILL.md from `[custom:...]` to `[official]` with source quotes. Added 7 new patterns: nested references, reference file >100 lines without TOC, README/CHANGELOG in skill dir, time-sensitive content in body, voodoo constants, unqualified MCP tool refs, punting to Claude in scripts. Added minor patterns: overfitting descriptions, vague names, missing Gotchas, railroaded prescriptive steps. Added a counter-note about not over-using ALL-CAPS MUST/NEVER (skill-creator guidance).
- 2026-06-10: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-06-10). No new anti-patterns; severities re-verified. Note: 2026 frontmatter fields (`when_to_use`, `arguments`, `disallowed-tools`, `effort`, `paths`, `shell`, `hooks`) are official — do not flag as unknown.
- 2026-06-26: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-06-26). No new anti-patterns; catalog re-verified. Assessor notes (negative findings worth flagging): (1) **Frontmatter keys** are case-tolerant (kebab/snake/camelCase all accepted as of changelog v2.1.186) — do NOT flag camelCase variants. (2) **Malformed YAML** still loads the skill body with empty metadata, so a "missing description" can be a YAML parse failure rather than an author omission — recommend running with `--debug` to disambiguate. (3) **Naming collision with bundled skills**: if a project/personal/plugin skill shares a name with a bundled skill (e.g. `code-review`, `debug`, `loop`), it silently replaces the bundled one — surface as advisory NOTE so authors realize they're overriding `/code-review`.
- 2026-07-25: Freshness re-run against code.claude.com/docs/en/skills (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **One new Major anti-pattern**: a `context: fork` skill that leaves `background` at its `true` default while its body depends on a tool outside the **narrower background-subagent tool set** - the forked skill runs as a regular agent type, so the fork exemption does not cover it; the fix is `background: false` (v2.1.218). **One new Minor**: instructing Claude to run `/verify` or `/code-review` itself, or preloading them into a subagent - as of v2.1.215 only the user can invoke them, so the instruction silently never fires. **One de-escalation**: a `name` that differs from the skill's directory is **not** a defect in a personal or project skill - `name` sets only the display label there and the command comes from the directory name; keep the flag only for plugin skills, where `name` forms the command's last segment. **One tolerance note**: boolean frontmatter values `yes`/`no`/`on`/`off`/`1`/`0` in any case are valid as of v2.1.218 - do not flag them as malformed. last_updated bumped to 2026-07-25.
- 2026-09-04: Freshness re-run against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-09-04) and changelog v2.1.229-v2.1.260. **Three new Major anti-patterns**: (1) an injected `` !`command` `` that can exit non-zero without `|| true` or that matches an ask/deny permission rule — either aborts the **entire** invocation and Claude never sees the skill content; (2) content (blank lines/comments/UTF-8 BOM) before the opening `---` — frontmatter is parsed only when `---` is the file's first line, and a BOM silently hid the whole skill before v2.1.243; (3) broad `allowed-tools` (e.g. `Bash(*)`) in a repo-committed skill — the field is not workspace-trust-gated and applies even in untrusted `-p` runs. **One new Major**: a skill directory named `synced` (reserved, any capitalization — the skill is skipped entirely). **One new Minor**: hardcoded absolute paths to bundled files instead of `${CLAUDE_SKILL_DIR}`/`${CLAUDE_PROJECT_DIR}` in body + `allowed-tools`. **Assessor-note update**: overriding a bundled skill does NOT capture its aliases (a local `code-review` never receives `/review`; v2.1.248 fixed alias-keyed `skillOverrides`) — extend the 2026-06-26 naming-collision note accordingly. Diagnostic: `claude plugin validate <skills-dir>` (v2.1.233+) finds unparseable frontmatter. last_updated bumped to 2026-09-04.
- 2026-09-16: Freshness re-run against code.claude.com/docs/en/skills, docs/en/hooks (Hooks in skills and agents), agentskills.io/specification and evaluating-skills (all retrieved 2026-09-16) and changelog v2.1.261-v2.1.273 (newest v2.1.273, 2026-09-15). **One new Major**: an unscoped/unreviewed `hooks:` block in a repo-committed skill — frontmatter hooks persist "for the rest of the session" and, in project skills, are **not workspace-trust-gated** (apply in untrusted `-p` runs), the same gap as broad `allowed-tools`. **Three new Minor**: (1) spec-invalid `name` (≠ directory, leading/trailing/double hyphen) in an **export-targeted** skill — Agent Skills spec requires the match; Claude Code-only skills keep the 2026-07-25 de-escalation; (2) inert `name`/`paths` in a `.claude/commands/*.md` file; (3) missing `once: true` on a one-shot frontmatter hook (Major if side-effectful). **Updates**: injected-command entry gains the auto-mode nuance (ask-rule matches don't abort in auto mode per v2.1.271, but still abort in forked skills with `agent`/no shell tool; deny aborts everywhere — severity unchanged) and the error strings; the hedging counter-note is now `[official]`-backed ("Reasoning-based instructions … work better than rigid directives ('ALWAYS do X, NEVER do Y')", agentskills.io). **Assessor notes**: a local skill clashing with a claude.ai-synced short name no longer causes a skip — the synced one becomes `/anthropic-skills:<name>` (v2.1.269); `/skill-doctor` (v2.1.261; docs v2.1.252+) is the official diagnostic for "skill never triggers / costs too much context" complaints — suggest it before proposing description rewrites; `claude plugin validate <skills-dir>` text was not surfaced on the skills page this run (command still exists per plugins-reference, `--strict` added) — keep recommending, lower confidence on the skills-dir form. last_updated bumped to 2026-09-16.
- 2026-08-12: Freshness re-run against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-08-12) and changelog v2.1.219-v2.1.228. No new anti-patterns; catalog re-verified current. **New assessor note**: do **not** treat Claude Code-only frontmatter fields as an anti-pattern in Claude Code-only skills. They break only on the claude.ai upload / Skills API / `package_skill.py` paths, where the Agent Skills spec permits just `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` and an extra key is a hard error. **De-flag**: plugin/org skills named after terminal built-ins are invocable again (v2.1.221), so such a name is no longer a discoverability trap outside the still-reserved terminal-only built-ins. last_updated bumped to 2026-08-12.
- 2026-09-24: Freshness re-run against code.claude.com/docs/en/skills, the per-model prompting pages (Fable 5, Opus 5, Opus 5.5) and the Anthropic "new rules of context engineering for Claude 5" blog (all retrieved 2026-09-24) + changelog v2.1.274–v2.1.281. **One new Major**: "Instruction to Reproduce Reasoning in the Response" — show-your-thinking steps can trigger `reasoning_extraction` refusals on Fable 5/5.1 and Opus 5.5 (default Opus since v2.1.280); rationale-for-result asks exempt. **One new Minor**: "Generic Self-Verification Steps" — official Opus 5 guidance to remove "double-check / final verification step / subagent to verify" prose; runnable validator loops and deliberate independent-evaluator stages exempt. **Railroaded Prescriptive Steps** gains official backing (blog: "Avoid making them overconstrained, except in highly important areas"; Fable 5: "often too prescriptive") — tag stays `[community:high]` + noted `[official]`. Assessor note: editing files under `~/.claude/skills/synced/` is overwritten by the ~10-minute terminal sync (docs v2.1.273; v2.1.275 prints a "not saved to your account" notice). last_updated bumped to 2026-09-24.

# SKILL.md Quality Criteria

> Referenced during Phase 2 (Quality Assessment) for SKILL.md reviews.
> Derived from the skill-reviewer agent's check items A-J, updated with 2026-04 official guidance.
>
> **Source tags:**
> - `[official]` = Anthropic official documentation
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[custom]` = Derived from this repo's own practice
> - `[custom:derived-from-skill-reviewer]` = Extracted from skill-reviewer agent

last_updated: 2026-09-24

---

## Contents

Criteria & Scoring (100 points total):
- A. Frontmatter Correctness (15)
- B. Conciseness & Token Cost (15)
- C. Degrees of Freedom (10)
- D. Structure & Progressive Disclosure (15)
- E. Content Quality (15)
- F. Workflows & Error Handling (10)
- G. Anti-patterns (10)
- H. Behavioral Impact (10)

Plus: Supplementary Checks (advisory), Grading Scale

## Criteria & Scoring (100 points total)

### A. Frontmatter Correctness (15 points)

`[official]` YAML frontmatter is the skill's identity and trigger mechanism.

**name** `[official]`: max 64 chars, lowercase/numbers/hyphens only, no reserved words ("anthropic", "claude"), no XML tags. Gerund form preferred (`processing-pdfs`, `analyzing-spreadsheets`). If omitted, defaults to directory name.

**name does NOT set the command for personal/project skills (added 2026-07-25)** `[official]`: for a skill under `~/.claude/skills/` or `.claude/skills/`, the frontmatter `name` sets **only the display label** in skill listings — the command you type comes from the **directory name**. `name` supplies part of the command only for plugin skills (`my-plugin/skills/review/SKILL.md` with `name: fancy` → `/my-plugin:fancy`) and plugin-root `SKILL.md`. Consequence for scoring: a `name` ↔ directory mismatch in a personal/project skill is a **maintainability/advisory note, not a functional break** — do NOT apply the 4-pt "name-folder mismatch" band to personal/project skills; reserve it for plugin skills where the mismatch actually changes the invocation path.

**Export-targeted skills follow the Agent Skills spec `name` rules (added 2026-09-16)** `[official]`: agentskills.io/specification (retrieved 2026-09-16) requires `name` to "Must match the parent directory name", "Must not start or end with a hyphen (`-`)", and "Must not contain consecutive hyphens (`--`)". When a skill is **explicitly** intended for claude.ai upload, the Skills API, `package_skill.py`, or Cowork/cloud enablement (which "is an upload, so the same rules apply"), a `name` ↔ directory mismatch or a leading/trailing/double hyphen **does** take the 4-pt band. For Claude Code-only skills these remain advisory. `.claude/commands/*.md` files ignore `name` and `paths` entirely — flag either field there as inert (Minor).

**description** `[official]`: non-empty, no XML tags, **third person** (not "I" / "You"). Must cover: `[What] + [When/triggers]`. Slight "pushiness" recommended to combat undertriggering. **Cap (revised 2026-07-25):** the current docs state only that the combined `description` + `when_to_use` text is **truncated at 1,536 characters in the skill listing**. The previously-recorded 1024-char hard validation cap is no longer restated in official docs — treat **1,536 combined** as the operative limit and front-load triggers; do not deduct on the 1024 figure alone.

**when_to_use** `[official]` (new field, 2026): optional; appended to `description` in listing. Combined (`description` + `when_to_use`) truncated at **1,536 chars** in the listing — front-load key triggers.

**Other**: no README.md / CHANGELOG.md in skill dir `[community:high]` (wastes tokens). Optional fields validated if present: `allowed-tools`, `disallowed-tools` (new 2026), `arguments` (new 2026; named positional args for `$name`), `paths`, `context`, `agent`, `effort`, `hooks`, `shell`, `model`, `argument-hint`, `disable-model-invocation`, `user-invocable` — all official as of 2026-06; plus `background` (only alongside `context: fork` — see below), `metadata`, `license`, and `compatibility` (`compatibility` capped at 500 chars) as of 2026-08. Do NOT flag any of these as unknown fields. **Key-case (added 2026-06-26):** kebab-case, snake_case, and camelCase variants of each key are all accepted (changelog v2.1.186, 2026-06-22) — do NOT deduct for `whenToUse` vs `when_to_use` vs `when-to-use`. **Malformed YAML (added 2026-06-26):** invalid frontmatter still loads the skill body with **empty metadata**, so `/skill-name` works manually but auto-triggering is impossible — if the agent reviewer can't see a description, flag a possible YAML parse issue and suggest `--debug` to confirm. **`metadata` block (added 2026-07-13):** `gh skill install` (gh CLI 2.96+ preview) injects a `metadata:` block containing `github-repo`, `github-ref`, `github-tree-sha`, `github-path` for provenance tracking (used by `gh skill update`). **Updated 2026-08-12:** `metadata` is now a recognized field in its own right — it must be a **map** (a non-map value is dropped silently) and does not affect runtime. Never flag it as unknown, whether the skill is gh-managed or hand-written.

**Boolean value tolerance (added 2026-07-25)** `[official]`: as of changelog v2.1.218, boolean frontmatter fields accept `yes`, `no`, `on`, `off`, `1`, and `0` in **any letter case**, in addition to `true`/`false`. Do NOT flag `disable-model-invocation: yes` or `user-invocable: Off` as invalid.

**Frontmatter must open the file (added 2026-09-04)** `[official]`: frontmatter is parsed only when the opening `---` is the file's **first line**; otherwise the whole file (markers included) is treated as body — flag leading blank lines/comments before `---` as a Major correctness issue. A UTF-8 BOM made the whole skill silently ignored before v2.1.243. Diagnostic to recommend: `claude plugin validate .claude/skills` (or `~/.claude/skills`), v2.1.233+, finds SKILL.md files whose frontmatter doesn't parse.

**`allowed-tools` scope (clarified 2026-09-04)** `[official]`: the grant is **turn-scoped** — it clears when the user sends their next message, even though skill content persists in context. It pre-approves but does not restrict (restriction is `disallowed-tools` or permission deny rules) — flag skill bodies that rely on `allowed-tools` to "block" tools. `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` (and in plugin skills `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`) are substituted inside `allowed-tools` Bash rules; pairing the same variable in the rule and the body step is the official "run bundled script without a prompt" pattern — positive signal. **Security check**: `allowed-tools` is NOT gated by workspace trust — a repo-committed project skill's grants apply even in untrusted `-p` runs, so an overly-broad grant (e.g. `Bash(*)`) in a shared repo is a **Major** finding.

**Reserved directory name `synced` (added 2026-09-04)** `[official]`: the folder name `synced` (any capitalization) is reserved in enterprise/personal/project skill locations for claude.ai-synced skills; a skill authored at that name is skipped. Flag as a Major functional issue.

**Frontmatter `hooks` are session-persistent and not trust-gated (added 2026-09-16)** `[official]`: "Skill hooks: Claude Code registers them when you or Claude invoke the skill and keeps running them for the rest of the session, on turns after the skill's own turn as well. To have Claude Code remove a hook after its first successful run instead, set `once: true` on it." And: "Frontmatter hooks in a project skill follow the same workspace trust rule as hooks in settings files. Claude Code registers them when you or Claude invoke the skill, including in a `-p` run in a folder you haven't trusted." (https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents, retrieved 2026-09-16). Checks: (a) a hook meant as one-shot setup should carry `once: true`; (b) a `hooks:` block in a **repo-committed** skill with a wide matcher (e.g. `PreToolUse` on `Bash` / `*`) running an unreviewed `command` is a **Major** security finding on the same footing as broad `allowed-tools`; (c) a hook whose `command` uses a relative path should prefer `${CLAUDE_SKILL_DIR}` — the session shell's cwd moves with `cd`. Do not flag the mere presence of `hooks:`.

**`paths` scoping (clarified 2026-07-25)** `[official]`: `paths` glob patterns limit **automatic** activation — with `paths` set, Claude loads the skill on its own only when working with matching files. It does not block `/skill-name` invocation. Same glob format as path-specific rules. Advisory positive signal for narrowly-scoped skills; its absence is not a deduction.

**`context: fork` + `background` (added 2026-07-25)** `[official]`: `background` applies only alongside `context: fork` and requires v2.1.218+. A backgrounded fork runs with the **narrower background-subagent tool set**; if the skill's steps need a tool outside that set, `background: false` is required. Flag as a **Major** correctness issue when a `context: fork` skill's body depends on tools outside the background set without setting `background: false`. **Added 2026-09-16:** Claude Code forces the foreground anyway in `-p`/SDK runs, with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, when the same forked skill is already running, and when a scheduled task fires the skill — so a skill that *only* ever runs from a routine is not exposed, but the body must still not assume background execution. Advisory: "A forked skill that runs in the background applies its edits outside your session's checkpoints, so `/rewind` doesn't undo them; use git to revert them" — a backgrounded fork that edits files should say so, or commit/branch first.

- **15 pts**: All valid, description covers four components, no README.md
- **12 pts**: Valid but description missing one component
- **8 pts**: Missing 2+ description components, triggering risk (under/over-trigger), or a Major frontmatter correctness issue (`context: fork` + `background: true` with a body needing an excluded tool; broad `allowed-tools` or unscoped `hooks:` in a repo-committed skill)
- **4 pts**: Name format violation, or plugin-skill `name` ↔ command mismatch, or (export-targeted skill only) `name` ↔ directory mismatch / hyphen-rule violation per the Agent Skills spec (personal/project Claude Code-only `name`↔directory mismatch is advisory only — see above)
- **0 pts**: Broken YAML or README.md present alongside SKILL.md

### B. Conciseness & Token Cost (15 points)

`[custom:derived-from-skill-reviewer]` Skills load on demand but still consume context.

Flag: content Claude already knows, verbose explanations where a brief statement suffices, redundant information, prose where bullets would work.

- **15 pts**: Every paragraph justifies its token cost, no inferable content
- **12 pts**: 1-2 instances of inferable content
- **8 pts**: 3-4 instances or noticeable redundancy
- **4 pts**: Significant bloat (multiple paragraphs of known content)
- **0 pts**: Majority of content is inferable or redundant

### C. Degrees of Freedom (10 points)

`[custom:derived-from-skill-reviewer]` Constraint level must match task fragility.

High freedom for creative tasks, medium for technical, low for safety-critical/exact-format.

- **10 pts**: Well-matched constraint level
- **7 pts**: Slightly mismatched but unlikely to cause issues
- **4 pts**: Noticeably mismatched (creative locked down, or safety task left open)
- **0 pts**: Severely mismatched, likely to produce wrong behavior

**Claude 5-generation calibration (added 2026-09-24)** `[official]`: official guidance now leans the default toward *less* constraint — "Avoid making them overconstrained, except in highly important areas" (Anthropic blog, claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models) and "Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality" (prompting-claude-fable-5). When deciding between 7 and 10 for a non-fragile task, micro-step scripting of what Claude would do anyway (tactical choices, enumerated cases a one-line goal covers) counts as over-constraint. Fragile/safety/exact-format tasks keep low freedom — the blog's "except in highly important areas" is the carve-out. Scoring bands unchanged.

### D. Structure & Progressive Disclosure (15 points)

`[official]` Large skills must split content into referenced files.

**Size** `[official]`: SKILL.md under **500 lines**; SKILL.md body under 5,000 tokens recommended (Anthropic's own `plugin-dev/skill-development` skill targets a tighter **1,500-2,000 words** for the body `[semi-official]`); references **one level deep only** (no nested links from a reference into another reference).

**File references** `[official]`: references are Read-tool instructions (Claude reads them on demand), **not `@` imports** (those only work in CLAUDE.md). Each reference should be named by explicit path in the step that needs it — vague/buried references cause "missed connections" where Claude never reads the file.

**Table of contents** `[official]`: reference files longer than **100 lines** must include a TOC at the top so Claude can see full scope when previewing with partial reads.

**Progressive disclosure** `[official]`: three tiers — metadata (always loaded) → SKILL.md body (on trigger) → bundled resources (on demand). Over 300 lines without `references/` is a yellow flag.

**Recommended sections**: title/overview, workflow/instructions, output format/examples, error handling/troubleshooting.

- **15 pts**: Under 500 lines, logical structure, all sections, proper splitting
- **12 pts**: Under 500 lines, missing one recommended section
- **8 pts**: Under 500 lines but missing 2+ sections, or >300 lines without references/
- **4 pts**: Over 500 lines, or nested file references
- **0 pts**: Over 500 lines with no splitting, or incoherent structure

### E. Content Quality (15 points)

`[custom:derived-from-skill-reviewer]` Instructions must be timeless, consistent, specific, and actionable.

**Time-sensitive info**: flag "before/after/as of [date]", "currently", "recently", "deprecated since".

**Terminology**: same concept must use the same term throughout.

**Actionability**: flag vague directives ("validate the data", "review carefully") without concrete criteria.

- **15 pts**: No time-sensitive info, consistent terms, all instructions actionable
- **12 pts**: One vague directive or minor terminology inconsistency
- **8 pts**: 2-3 vague directives or time-sensitive content
- **4 pts**: Multiple inconsistencies and vague directives
- **0 pts**: Time-sensitive content in critical instructions, pervasive vagueness

### F. Workflows & Error Handling (10 points)

`[custom:derived-from-skill-reviewer]` Multi-step tasks need checklists; errors need concrete solutions.

**Workflows**: checklist-style for complex tasks, validation/verification for quality-critical tasks, feedback loops, recoverable on failure.
**Verification must be concrete (clarified 2026-09-24)** `[official]`: award the "validation" credit for a runnable check (script, test, validator, diff against fixture). Generic prose ("double-check your work", "add a final verification step", "use a subagent to verify") earns no credit and is the Minor anti-pattern "Generic Self-Verification Steps" under G — Opus 5 guidance says such instructions "cause over-verification … with no loss in quality" when removed. Do not deduct under F for its *absence*.

**Error handling**: concrete solutions required (not "handle errors gracefully"). All bundled resources (scripts/, references/, assets/) must be explicitly referenced with paths.

**Injected commands (added 2026-09-04)** `[official]`: a failed `` !`command` `` aborts the **entire skill invocation** — Claude never sees the content. Check that (a) commands that can legitimately exit non-zero (check scripts, greps expected to miss under `bash`'s exit≥2, diffs) end with `|| true` unless covered by the exit-1 search/comparison carveout, and (b) commands are pre-approved via `allowed-tools` or match allow rules — injected commands never prompt, and a matching **ask or deny** rule aborts the invocation regardless of `allowed-tools`. Flag violations as **Major** (see skill-anti-patterns.md). **Auto-mode caveat (added 2026-09-16):** in auto mode an ask-rule match no longer aborts (the skill "loads with an instruction telling Claude to run the command first"; changelog v2.1.271), but the abort still applies "in a forked skill that sets `agent`, and in a session where Claude doesn't have the shell tool", and a deny match aborts in every mode — keep the Major; the author's own permission mode is not a mitigation.

- **10 pts**: Complete workflows, concrete error handling, all resources referenced
- **7 pts**: Workflows present but missing validation or feedback loops
- **4 pts**: Generic error handling or unreferenced resources
- **0 pts**: No workflows for multi-step tasks, or no error handling

### G. Anti-patterns (10 points)

`[custom:derived-from-skill-reviewer]` See [skill-anti-patterns.md](skill-anti-patterns.md) for the full catalog.

Check for: Windows-style paths, option listing without defaults, critical instructions past line 200, hedging language for required actions, >500 lines without splitting, >3,000 words unstructured prose, ambiguous instructions. Added 2026-09-24: reasoning-reproduction instructions (**Major** — `reasoning_extraction` refusal risk on Fable 5/5.1 and Opus 5.5) and generic self-verification steps (Minor).

- **10 pts**: No anti-patterns
- **7 pts**: 1-2 Minor
- **4 pts**: Major present
- **0 pts**: Multiple Major or any Critical

### H. Behavioral Impact (10 points)

`[custom:derived-from-skill-reviewer]` Every section must change Claude's decisions.

Per section: **High** = changes decisions, **Medium** = clarifies ambiguity, **Low/None** = inferable or no decision impact. Deduct when Low/None exceeds 30%.

- **10 pts**: All sections High/Medium
- **7 pts**: Low/None under 20%
- **4 pts**: Low/None 30-50%
- **0 pts**: Low/None over 50%

---

## Supplementary Checks (advisory, not scored)

**Script Quality** `[custom:derived-from-skill-reviewer]`: scripts handle own errors, no unexplained magic numbers, clear execute-vs-read intent, non-standard dependencies listed.

**MCP Tool References** `[custom:derived-from-skill-reviewer]`: fully qualified format (`ServerName:tool_name`), no ambiguous references.

**Testing** `[official]`: test across model tiers (Haiku, Sonnet, Opus) — what works for Opus may need more detail for Haiku. Build ≥3 evals BEFORE writing extensive content (evaluation-driven development). skill-creator's eval pipeline uses 20 realistic trigger/non-trigger queries × up to 5 rounds of description optimization `[semi-official]`.

**"Pushy" descriptions** `[semi-official]`: combat undertriggering by making descriptions slightly assertive — include explicit trigger phrases beyond the bare "what" statement. **Tempered 2026-09-24 (official conflict):** the platform prompting guide says current models "may now overtrigger" on prompts written to fix undertriggering and that "Instructions like 'If in doubt, use [tool]' will cause overtriggering". Advisory reading: explicit *trigger contexts* remain a positive signal; blanket pushiness ("use whenever…", "even if they don't ask", "if in doubt") is not — flag it only when it widens the trigger beyond the skill's real domain. Never deduct for its absence.

**"Use when..." phrasing + examples (measured)** `[community:mid]`: a 200+ prompt benchmark reports optimized descriptions lift activation ~20%→50%, and adding concrete examples lifts it ~72%→90%; "Use when..." is the recommended trigger-clause template (https://gist.github.com/mellanon/50816550ecb5f3b239aa77eef7b8ed8d, retrieved 2026-06-10). Directional evidence supporting the existing trigger-clause requirement in criterion A — no scoring-band change.

**"Old patterns" archival** `[official]`: deprecated info should move into a collapsed `<details>` section titled "Old patterns" rather than being deleted or flagged with dates.

**Skill stacking** `[official]` (added 2026-07-25): as of v2.1.199 a user can stack up to six inline user-invocable skills in one message (`/write-tests /fix-issue 123`), with the trailing text passed as `$ARGUMENTS` to each. Expansion **stops** at the first token that isn't an inline user-invocable skill — a `context: fork` skill (e.g. `/code-review`) or one whose args may start with a slash (e.g. `/loop`) ends the run there. Advisory: skills designed to compose with others should avoid `context: fork` unless forking is essential.

**Bundled-skill invocation control** `[official]` (added 2026-07-25): as of v2.1.215 `/verify` and `/code-review` run **only when the user invokes them** — Claude cannot auto-run them, and they cannot be preloaded into subagents via the agent `skills` field. Flag any skill or agent that instructs Claude to "run `/code-review`" or preloads it as a broken instruction.

**Bundled-skill override does not cover aliases** `[official]` (added 2026-09-04): a personal/project/plugin skill named after a bundled skill replaces it, "but not the bundled skill's aliases" — e.g. a local `code-review` skill never receives `/review`, which still runs the bundled one. When reviewing a skill that overrides a bundled name, note the alias gap. Similarly, Cowork/cloud sessions and routines don't read `~/.claude/skills/` — a personal-only skill referenced by a routine will report "not found" there (enable on claude.ai, commit to repo `.claude/skills/`, or ship it in a plugin declared in the repo's `.claude/settings.json`; Desktop scheduled tasks run locally and do load `~/.claude/skills/` — clarified 2026-09-16). **Synced-name clash (updated 2026-09-16, v2.1.269):** a local skill sharing a short name with a claude.ai-synced skill keeps `/<name>`; the synced one runs as `/anthropic-skills:<name>` instead of being skipped — advisory only.

**`/skill-doctor` and portfolio pruning** `[official]` (added 2026-09-16): `/skill-doctor` (changelog v2.1.261; docs say v2.1.252+, feature-flag-gated, not over Remote Control) reports each non-bundled, non-enterprise skill's context cost and invocation count and flags never-invoked skills. When a review covers a whole skills directory, or a skill's description is long relative to its use, recommend running `/skill-doctor` and either tightening the description, adding `disable-model-invocation: true`, or setting `"name-only"` / `"user-invocable-only"` / `"off"` in `skillOverrides` (`skillOverrides` doesn't reach plugin skills; alias-keyed entries work only in managed settings / `--settings` files and can only restrict). Advisory; never a deduction on its own.

**Frontmatter `hooks` `once` option** `[official]` (added 2026-09-16): see criterion A. A skill whose hook is described in the body as "run once at start" but lacks `once: true` will fire on every matching event for the rest of the session — Minor unless the hook has side effects (then Major).

**String substitutions** `[official]` (added 2026-07-25, extended 2026-09-04): `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name` (from the `arguments` field), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}` (v2.1.196+), and in plugin skills `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`. Positive signal: a skill that references bundled files should use `${CLAUDE_SKILL_DIR}` (or `${CLAUDE_PROJECT_DIR}` for project-local files) in bash-injection commands rather than a hardcoded absolute path, so it survives relocation and the session shell's `cd` drift. Escaping: `\$1.00` keeps a literal `$1`; argument values containing placeholder text are inserted literally, never re-expanded.

**Eval artifacts (`evals/evals.json`)** `[official]` (added 2026-06-26, extended 2026-09-16): presence of `evals/`, `evals/evals.json`, `grading.json`, or `benchmark.json` in the skill directory is a positive signal — produced by the official `skill-creator` plugin (`anthropics/claude-plugins-official`) and indicates evaluation-driven authoring. Advisory bonus only; absence is not penalized (most skills are not yet eval-instrumented). The official format reference is now https://agentskills.io/skill-creation/evaluating-skills (retrieved 2026-09-16): `evals/evals.json` holds `skill_name` and an `evals` array of `{id, prompt, expected_output, files, assertions}`; "Start with 2-3 test cases" and "Cover edge cases. Include at least one prompt that tests a boundary condition". For skills shipped in a plugin, `claude plugin eval` (v2.1.269) gives CI-gateable with/without scoring; its format and skill-creator's "aren't interchangeable" — don't flag a plugin that has one but not the other. Docs also state triggering and output quality must be measured **separately** ("Seeing a skill trigger tells you Claude found it, not that it did what you intended") — an eval set that only checks activation is incomplete (advisory).

**Reasoned instructions over ALWAYS/NEVER — now official-backed** `[official]` (upgraded 2026-09-16 from `[community:mid]`): agentskills.io evaluating-skills guidance: "Reasoning-based instructions ('Do X because Y tends to cause Z') work better than rigid directives ('ALWAYS do X, NEVER do Y'). Models follow instructions more reliably when they understand the purpose." and "If pass rates plateau despite adding more rules, the skill may be over-constrained — try removing instructions". Feeds criteria C (degrees of freedom) and G (hedging counter-note); no band change.

---

## Grading Scale

| Grade | Score | Meaning |
|-------|-------|---------|
| S | 95-100 | Exemplary |
| A | 85-94 | Excellent |
| B | 70-84 | Good |
| C | 50-69 | Needs improvement |
| D | 30-49 | Insufficient |
| F | 0-29 | Not functioning |

---

## Changelog

- 2026-03-29: Initial version. Derived from skill-reviewer agent check items A-J. All items tagged `[custom:derived-from-skill-reviewer]` pending Phase 0 research to update with official sources.
- 2026-04-17: Upgraded tags from `[custom:derived-from-skill-reviewer]` to `[official]` / `[semi-official]` / `[community:high]` where Phase 0 research confirmed. Added `when_to_use` frontmatter field (new 2026). Clarified description caps: 1024-char hard validation + 1,536-char listing truncation (combined with `when_to_use`). Added "no README/CHANGELOG in skill dir" rule (community consensus). Strengthened structure criterion D with one-level-deep + 100-line TOC rules (now `[official]`). Added "pushy" description guidance, evaluation-driven development, and "Old patterns" archival pattern to supplementary checks.
- 2026-05-30: Minor refresh. Criterion A: added new 2026 frontmatter fields `arguments` / `disallowed-tools` to the validated-optional-fields list. Criterion D: added file-reference clarification (Read-tool instructions, not `@` imports — only CLAUDE.md supports `@`) and noted Anthropic's tighter 1,500-2,000-word body target `[semi-official]`. No scoring-band or criteria-weight changes; all `[custom]` items preserved.
- 2026-06-10: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-10). Criterion A: expanded the recognized-optional-fields list (`hooks`, `shell`, `agent`, `model`, etc.) so assessors don't flag official 2026 fields as invalid. Supplementary checks: added measured "Use when..." + examples activation data (mellanon 200+ prompt benchmark, `[community:mid]`, advisory only). Core caps re-verified unchanged (1024 hard / 1,536 combined listing, 500-line SKILL.md). No scoring-band or weight changes; all `[custom]` items preserved.
- 2026-06-26: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-26) and changelog v2.1.186 (2026-06-22). **Material advisory updates (no scoring weights changed)**: Criterion A — recognized-optional-fields list still current; **add note that frontmatter keys now accept kebab/snake/camelCase (changelog v2.1.186)** so assessors do not flag `whenToUse` / `disallowedTools` (camel) as invalid; **add note that malformed YAML still loads the skill body with empty metadata** — a skill that works via `/name` but never auto-triggers may have invalid YAML, check with `--debug`. Supplementary checks — add advisory positive signal: presence of `evals/evals.json` indicates evaluation-driven authoring (skill-creator plugin output). Core thresholds and band rubrics unchanged. last_updated bumped to 2026-06-26.
- 2026-07-13: Allow-list `metadata` frontmatter block for gh-managed skills. `gh skill install` (gh CLI 2.96+ preview) injects a `metadata:` block containing `github-repo` / `github-ref` / `github-tree-sha` / `github-path` for provenance tracking; used by `gh skill update` to detect upstream drift. Not part of Claude Code's schema, does not affect runtime. Do NOT flag as unknown when reviewing gh-managed skills (e.g. `configs/claude/skills/{grill-me,grilling}/`). No scoring-band or weight changes. last_updated bumped to 2026-07-13.
- 2026-07-25: Refresh against code.claude.com/docs/en/skills (retrieved 2026-07-25) and changelog v2.1.196–v2.1.218. **Two material scoring changes**: (1) **`name` ↔ directory mismatch downgraded to advisory for personal/project skills** — the docs now state explicitly that in a personal or project skill `name` sets only the display label and the command comes from the directory name; the 4-pt band now applies only to plugin skills, where `name` really does form the command's last segment. (2) **1024-char description hard cap removed** — current docs state only the 1,536-char combined `description`+`when_to_use` listing truncation; do not deduct on the 1024 figure. **Advisory additions**: boolean fields accept `yes`/`no`/`on`/`off`/`1`/`0` in any case (v2.1.218); `paths` scopes automatic activation only; `context: fork` + `background: true` runs with the narrower background-subagent tool set and needs `background: false` when the body depends on tools outside it (v2.1.218) — new Major check; skill stacking up to six, expansion stops at a forked or slash-arg skill (v2.1.199); `/verify` and `/code-review` are user-invoke-only and cannot be preloaded (v2.1.215); `${CLAUDE_SKILL_DIR}` preferred over hardcoded paths for bundled-file references. last_updated bumped to 2026-07-25.
- 2026-08-12: Refreshed against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-08-12) and changelog v2.1.219-v2.1.228. **No scoring-weight changes.** **Advisory updates**:
  - **A. Frontmatter**: `background`, `metadata`, `license`, and `compatibility` are valid fields - do not flag as unknown. `metadata` must be a **map** (a non-map value is dropped silently); `compatibility` is capped at 500 characters.
  - **Portability caveat (new)**: Claude Code-only fields (`when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`) are a **hard error** only on claude.ai upload / Skills API / `package_skill.py` paths. For Claude Code-only skills they are correct - **never deduct**. Raise a Minor note only when the skill is explicitly meant to be exported.
  - **A. Frontmatter (`model`)**: a value blocked by an org `availableModels` allowlist is ignored and the session keeps its current model - not a validity failure.
  last_updated bumped to 2026-08-12.
- 2026-09-16: Refreshed against code.claude.com/docs/en/skills, docs/en/hooks (Hooks in skills and agents), settings-reference, agentskills.io/specification, agentskills.io/skill-creation/evaluating-skills (all retrieved 2026-09-16) and changelog v2.1.261-v2.1.273 (newest v2.1.273, 2026-09-15). **No criterion weights changed; two band-text edits and several advisory checks**:
  - **A. Frontmatter (new Major check)**: frontmatter `hooks` are registered on invoke and kept "for the rest of the session" (not lifecycle-scoped as previously assumed) and, in project skills, are **not workspace-trust-gated** — an unscoped/unreviewed `hooks:` block in a repo-committed skill joins broad `allowed-tools` in the 8-pt band; `once: true` expected on one-shot hooks.
  - **A. Frontmatter (4-pt band extended)**: for **export-targeted** skills (claude.ai upload / Skills API / `package_skill.py` / Cowork-cloud enablement) the Agent Skills spec's `name` rules apply — must match the parent directory, no leading/trailing/consecutive hyphens. Claude Code-only skills keep the 2026-07-25 advisory treatment. `name`/`paths` in `.claude/commands/*.md` are inert (Minor).
  - **A. `context: fork`**: forced-foreground cases recorded (`-p`/SDK, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, same skill already running, scheduled task); background-fork edits bypass `/rewind` (advisory).
  - **F. Injected commands**: auto-mode caveat — ask-rule matches no longer abort in auto mode (v2.1.271 follows default-mode rules), but still abort in forked skills with `agent` and without a shell tool; deny aborts everywhere; Major retained.
  - **Supplementary**: `/skill-doctor` (v2.1.261; docs v2.1.252+) recorded as the official pruning tool with `skillOverrides` semantics (plugin skills excluded; alias keys only in managed/`--settings`, restrict-only); synced-name clash now yields `/anthropic-skills:<name>` instead of skipping (v2.1.269); cloud sessions load repo `.claude/skills/` and repo-declared plugins, Desktop scheduled tasks load `~/.claude/skills/`; eval-artifact note extended with the agentskills.io `evals.json` schema, `claude plugin eval` (v2.1.269), and "measure triggering and output separately"; "reasoned instructions over ALWAYS/NEVER" upgraded to `[official]` (agentskills.io).
  last_updated bumped to 2026-09-16.
- 2026-09-04: Refreshed against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-09-04) and changelog v2.1.229-v2.1.260. **No scoring-weight changes; new Major-severity checks added as advisory notes within existing criteria**:
  - **A. Frontmatter**: frontmatter parsed only when `---` is the file's first line (leading blank lines/BOM = Major; BOM silently hid skills before v2.1.243); `claude plugin validate <skills-dir>` (v2.1.233+) recommended as the parse diagnostic; `allowed-tools` is turn-scoped, pre-approves without restricting, substitutes `${CLAUDE_SKILL_DIR}`/`${CLAUDE_PROJECT_DIR}`/plugin vars in Bash rules (paired rule+body variable = positive signal), and is **not workspace-trust-gated** — broad grants in repo-committed skills are a Major security finding; skill directory named `synced` (any case) is reserved and skipped = Major.
  - **F. Workflows & Error Handling**: injected `` !`command` `` failure aborts the whole invocation — expect `|| true` on commands that can exit non-zero (exit-1 search/comparison carveout aside) and `allowed-tools` pre-approval, since ask/deny rules abort regardless = Major.
  - **Supplementary**: substitution list extended (`${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`); bundled-skill override doesn't capture aliases (`/review` vs local `code-review`); Cowork/cloud/routines don't read `~/.claude/skills/`. Note: frontmatter `model:` was ignored in interactive sessions until fixed in v2.1.248 — not an authoring defect.
  last_updated bumped to 2026-09-04.
- 2026-09-24: Refreshed against code.claude.com/docs/en/skills, the per-model prompting pages (Fable 5, Opus 5, Opus 5.5) and the Anthropic "new rules of context engineering for Claude 5" blog (retrieved 2026-09-24) + changelog v2.1.274–v2.1.281. **No weight or band changes.** (1) **C. Degrees of Freedom** — calibration note: official guidance now defaults toward less constraint ("Avoid making them overconstrained, except in highly important areas"; Fable 5 "often too prescriptive"); micro-scripting of non-fragile tasks counts as mismatch at the 7-vs-10 boundary. (2) **F. Workflows** — validation credit requires a runnable check; generic "double-check / verify" prose earns nothing and is a G Minor. (3) **G. Anti-patterns** — new Major (reasoning-reproduction instruction, `reasoning_extraction` refusal risk) and new Minor (generic self-verification steps) added to the check list. Advisory: synced claude.ai skills now also sync into signed-in terminal sessions (docs v2.1.273 / changelog v2.1.275); edits under `~/.claude/skills/synced/` don't persist. last_updated bumped to 2026-09-24.
  - Also 2026-09-24 (Supplementary): "Pushy" descriptions note tempered by the official overtriggering warning — trigger contexts stay a positive signal, blanket pushiness is flagged only when it widens scope; never deducted for absence.

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

last_updated: 2026-09-04

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

**description** `[official]`: non-empty, no XML tags, **third person** (not "I" / "You"). Must cover: `[What] + [When/triggers]`. Slight "pushiness" recommended to combat undertriggering. **Cap (revised 2026-07-25):** the current docs state only that the combined `description` + `when_to_use` text is **truncated at 1,536 characters in the skill listing**. The previously-recorded 1024-char hard validation cap is no longer restated in official docs — treat **1,536 combined** as the operative limit and front-load triggers; do not deduct on the 1024 figure alone.

**when_to_use** `[official]` (new field, 2026): optional; appended to `description` in listing. Combined (`description` + `when_to_use`) truncated at **1,536 chars** in the listing — front-load key triggers.

**Other**: no README.md / CHANGELOG.md in skill dir `[community:high]` (wastes tokens). Optional fields validated if present: `allowed-tools`, `disallowed-tools` (new 2026), `arguments` (new 2026; named positional args for `$name`), `paths`, `context`, `agent`, `effort`, `hooks`, `shell`, `model`, `argument-hint`, `disable-model-invocation`, `user-invocable` — all official as of 2026-06; plus `background` (only alongside `context: fork` — see below), `metadata`, `license`, and `compatibility` (`compatibility` capped at 500 chars) as of 2026-08. Do NOT flag any of these as unknown fields. **Key-case (added 2026-06-26):** kebab-case, snake_case, and camelCase variants of each key are all accepted (changelog v2.1.186, 2026-06-22) — do NOT deduct for `whenToUse` vs `when_to_use` vs `when-to-use`. **Malformed YAML (added 2026-06-26):** invalid frontmatter still loads the skill body with **empty metadata**, so `/skill-name` works manually but auto-triggering is impossible — if the agent reviewer can't see a description, flag a possible YAML parse issue and suggest `--debug` to confirm. **`metadata` block (added 2026-07-13):** `gh skill install` (gh CLI 2.96+ preview) injects a `metadata:` block containing `github-repo`, `github-ref`, `github-tree-sha`, `github-path` for provenance tracking (used by `gh skill update`). **Updated 2026-08-12:** `metadata` is now a recognized field in its own right — it must be a **map** (a non-map value is dropped silently) and does not affect runtime. Never flag it as unknown, whether the skill is gh-managed or hand-written.

**Boolean value tolerance (added 2026-07-25)** `[official]`: as of changelog v2.1.218, boolean frontmatter fields accept `yes`, `no`, `on`, `off`, `1`, and `0` in **any letter case**, in addition to `true`/`false`. Do NOT flag `disable-model-invocation: yes` or `user-invocable: Off` as invalid.

**Frontmatter must open the file (added 2026-09-04)** `[official]`: frontmatter is parsed only when the opening `---` is the file's **first line**; otherwise the whole file (markers included) is treated as body — flag leading blank lines/comments before `---` as a Major correctness issue. A UTF-8 BOM made the whole skill silently ignored before v2.1.243. Diagnostic to recommend: `claude plugin validate .claude/skills` (or `~/.claude/skills`), v2.1.233+, finds SKILL.md files whose frontmatter doesn't parse.

**`allowed-tools` scope (clarified 2026-09-04)** `[official]`: the grant is **turn-scoped** — it clears when the user sends their next message, even though skill content persists in context. It pre-approves but does not restrict (restriction is `disallowed-tools` or permission deny rules) — flag skill bodies that rely on `allowed-tools` to "block" tools. `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` (and in plugin skills `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`) are substituted inside `allowed-tools` Bash rules; pairing the same variable in the rule and the body step is the official "run bundled script without a prompt" pattern — positive signal. **Security check**: `allowed-tools` is NOT gated by workspace trust — a repo-committed project skill's grants apply even in untrusted `-p` runs, so an overly-broad grant (e.g. `Bash(*)`) in a shared repo is a **Major** finding.

**Reserved directory name `synced` (added 2026-09-04)** `[official]`: the folder name `synced` (any capitalization) is reserved in enterprise/personal/project skill locations for claude.ai-synced skills; a skill authored at that name is skipped. Flag as a Major functional issue.

**`paths` scoping (clarified 2026-07-25)** `[official]`: `paths` glob patterns limit **automatic** activation — with `paths` set, Claude loads the skill on its own only when working with matching files. It does not block `/skill-name` invocation. Same glob format as path-specific rules. Advisory positive signal for narrowly-scoped skills; its absence is not a deduction.

**`context: fork` + `background` (added 2026-07-25)** `[official]`: `background` applies only alongside `context: fork` and requires v2.1.218+. A backgrounded fork runs with the **narrower background-subagent tool set**; if the skill's steps need a tool outside that set, `background: false` is required. Flag as a **Major** correctness issue when a `context: fork` skill's body depends on tools outside the background set without setting `background: false`.

- **15 pts**: All valid, description covers four components, no README.md
- **12 pts**: Valid but description missing one component
- **8 pts**: Missing 2+ description components, triggering risk (under/over-trigger), or a Major frontmatter correctness issue (`context: fork` + `background: true` with a body needing an excluded tool)
- **4 pts**: Name format violation, or plugin-skill `name` ↔ command mismatch (personal/project `name`↔directory mismatch is advisory only — see above)
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

**Error handling**: concrete solutions required (not "handle errors gracefully"). All bundled resources (scripts/, references/, assets/) must be explicitly referenced with paths.

**Injected commands (added 2026-09-04)** `[official]`: a failed `` !`command` `` aborts the **entire skill invocation** — Claude never sees the content. Check that (a) commands that can legitimately exit non-zero (check scripts, greps expected to miss under `bash`'s exit≥2, diffs) end with `|| true` unless covered by the exit-1 search/comparison carveout, and (b) commands are pre-approved via `allowed-tools` or match allow rules — injected commands never prompt, and a matching **ask or deny** rule aborts the invocation regardless of `allowed-tools`. Flag violations as **Major** (see skill-anti-patterns.md).

- **10 pts**: Complete workflows, concrete error handling, all resources referenced
- **7 pts**: Workflows present but missing validation or feedback loops
- **4 pts**: Generic error handling or unreferenced resources
- **0 pts**: No workflows for multi-step tasks, or no error handling

### G. Anti-patterns (10 points)

`[custom:derived-from-skill-reviewer]` See [skill-anti-patterns.md](skill-anti-patterns.md) for the full catalog.

Check for: Windows-style paths, option listing without defaults, critical instructions past line 200, hedging language for required actions, >500 lines without splitting, >3,000 words unstructured prose, ambiguous instructions.

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

**"Pushy" descriptions** `[semi-official]`: combat undertriggering by making descriptions slightly assertive — include explicit trigger phrases beyond the bare "what" statement.

**"Use when..." phrasing + examples (measured)** `[community:mid]`: a 200+ prompt benchmark reports optimized descriptions lift activation ~20%→50%, and adding concrete examples lifts it ~72%→90%; "Use when..." is the recommended trigger-clause template (https://gist.github.com/mellanon/50816550ecb5f3b239aa77eef7b8ed8d, retrieved 2026-06-10). Directional evidence supporting the existing trigger-clause requirement in criterion A — no scoring-band change.

**"Old patterns" archival** `[official]`: deprecated info should move into a collapsed `<details>` section titled "Old patterns" rather than being deleted or flagged with dates.

**Skill stacking** `[official]` (added 2026-07-25): as of v2.1.199 a user can stack up to six inline user-invocable skills in one message (`/write-tests /fix-issue 123`), with the trailing text passed as `$ARGUMENTS` to each. Expansion **stops** at the first token that isn't an inline user-invocable skill — a `context: fork` skill (e.g. `/code-review`) or one whose args may start with a slash (e.g. `/loop`) ends the run there. Advisory: skills designed to compose with others should avoid `context: fork` unless forking is essential.

**Bundled-skill invocation control** `[official]` (added 2026-07-25): as of v2.1.215 `/verify` and `/code-review` run **only when the user invokes them** — Claude cannot auto-run them, and they cannot be preloaded into subagents via the agent `skills` field. Flag any skill or agent that instructs Claude to "run `/code-review`" or preloads it as a broken instruction.

**Bundled-skill override does not cover aliases** `[official]` (added 2026-09-04): a personal/project/plugin skill named after a bundled skill replaces it, "but not the bundled skill's aliases" — e.g. a local `code-review` skill never receives `/review`, which still runs the bundled one. When reviewing a skill that overrides a bundled name, note the alias gap. Similarly, Cowork/cloud sessions and routines don't read `~/.claude/skills/` — a personal-only skill referenced by a routine will report "not found" there (enable on claude.ai or commit to repo `.claude/skills/`).

**String substitutions** `[official]` (added 2026-07-25, extended 2026-09-04): `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name` (from the `arguments` field), `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}` (v2.1.196+), and in plugin skills `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`. Positive signal: a skill that references bundled files should use `${CLAUDE_SKILL_DIR}` (or `${CLAUDE_PROJECT_DIR}` for project-local files) in bash-injection commands rather than a hardcoded absolute path, so it survives relocation and the session shell's `cd` drift. Escaping: `\$1.00` keeps a literal `$1`; argument values containing placeholder text are inserted literally, never re-expanded.

**Eval artifacts (`evals/evals.json`)** `[official]` (added 2026-06-26): presence of `evals/`, `evals/evals.json`, `grading.json`, or `benchmark.json` in the skill directory is a positive signal — produced by the official `skill-creator` plugin (`anthropics/claude-plugins-official`) and indicates evaluation-driven authoring. Advisory bonus only; absence is not penalized (most skills are not yet eval-instrumented).

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
- 2026-09-04: Refreshed against code.claude.com/docs/en/skills + platform best-practices (retrieved 2026-09-04) and changelog v2.1.229-v2.1.260. **No scoring-weight changes; new Major-severity checks added as advisory notes within existing criteria**:
  - **A. Frontmatter**: frontmatter parsed only when `---` is the file's first line (leading blank lines/BOM = Major; BOM silently hid skills before v2.1.243); `claude plugin validate <skills-dir>` (v2.1.233+) recommended as the parse diagnostic; `allowed-tools` is turn-scoped, pre-approves without restricting, substitutes `${CLAUDE_SKILL_DIR}`/`${CLAUDE_PROJECT_DIR}`/plugin vars in Bash rules (paired rule+body variable = positive signal), and is **not workspace-trust-gated** — broad grants in repo-committed skills are a Major security finding; skill directory named `synced` (any case) is reserved and skipped = Major.
  - **F. Workflows & Error Handling**: injected `` !`command` `` failure aborts the whole invocation — expect `|| true` on commands that can exit non-zero (exit-1 search/comparison carveout aside) and `allowed-tools` pre-approval, since ask/deny rules abort regardless = Major.
  - **Supplementary**: substitution list extended (`${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`); bundled-skill override doesn't capture aliases (`/review` vs local `code-review`); Cowork/cloud/routines don't read `~/.claude/skills/`. Note: frontmatter `model:` was ignored in interactive sessions until fixed in v2.1.248 — not an authoring defect.
  last_updated bumped to 2026-09-04.

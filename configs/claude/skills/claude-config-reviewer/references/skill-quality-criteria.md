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

last_updated: 2026-06-26

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

**description** `[official]`: non-empty, max **1024 chars** (hard cap, truncated beyond), no XML tags, **third person** (not "I" / "You"). Must cover: `[What] + [When/triggers]`. Slight "pushiness" recommended to combat undertriggering.

**when_to_use** `[official]` (new field, 2026): optional; appended to `description` in listing. Combined (`description` + `when_to_use`) truncated at **1,536 chars** in the listing — front-load key triggers.

**Other**: no README.md / CHANGELOG.md in skill dir `[community:high]` (wastes tokens). Optional fields validated if present: `allowed-tools`, `disallowed-tools` (new 2026), `arguments` (new 2026; named positional args for `$name`), `paths`, `context`, `agent`, `effort`, `hooks`, `shell`, `model`, `argument-hint`, `disable-model-invocation`, `user-invocable` — all official as of 2026-06; do NOT flag these as unknown fields. **Key-case (added 2026-06-26):** kebab-case, snake_case, and camelCase variants of each key are all accepted (changelog v2.1.186, 2026-06-22) — do NOT deduct for `whenToUse` vs `when_to_use` vs `when-to-use`. **Malformed YAML (added 2026-06-26):** invalid frontmatter still loads the skill body with **empty metadata**, so `/skill-name` works manually but auto-triggering is impossible — if the agent reviewer can't see a description, flag a possible YAML parse issue and suggest `--debug` to confirm.

- **15 pts**: All valid, description covers four components, name-folder match, no README.md
- **12 pts**: Valid but description missing one component
- **8 pts**: Missing 2+ description components or triggering risk (under/over-trigger)
- **4 pts**: Name format violation or name-folder mismatch
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
- 2026-05-30: Minor refresh. Criterion A: added new 2026 frontmatter fields `arguments` / `disallowed-tools` to the validated-optional-fields list. Criterion D: added file-reference clarification (Read-tool instructions, not `@` imports — only CLAUDE.md supports `@`) and noted Anthropic's tighter 1,500-2,000-word body target `[semi-official]`. No scoring-band or criteria-weight changes; all `[custom]` items preserved.
- 2026-04-17: Upgraded tags from `[custom:derived-from-skill-reviewer]` to `[official]` / `[semi-official]` / `[community:high]` where Phase 0 research confirmed. Added `when_to_use` frontmatter field (new 2026). Clarified description caps: 1024-char hard validation + 1,536-char listing truncation (combined with `when_to_use`). Added "no README/CHANGELOG in skill dir" rule (community consensus). Strengthened structure criterion D with one-level-deep + 100-line TOC rules (now `[official]`). Added "pushy" description guidance, evaluation-driven development, and "Old patterns" archival pattern to supplementary checks.
- 2026-06-10: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-10). Criterion A: expanded the recognized-optional-fields list (`hooks`, `shell`, `agent`, `model`, etc.) so assessors don't flag official 2026 fields as invalid. Supplementary checks: added measured "Use when..." + examples activation data (mellanon 200+ prompt benchmark, `[community:mid]`, advisory only). Core caps re-verified unchanged (1024 hard / 1,536 combined listing, 500-line SKILL.md). No scoring-band or weight changes; all `[custom]` items preserved.
- 2026-06-26: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-26) and changelog v2.1.186 (2026-06-22). **Material advisory updates (no scoring weights changed)**: Criterion A — recognized-optional-fields list still current; **add note that frontmatter keys now accept kebab/snake/camelCase (changelog v2.1.186)** so assessors do not flag `whenToUse` / `disallowedTools` (camel) as invalid; **add note that malformed YAML still loads the skill body with empty metadata** — a skill that works via `/name` but never auto-triggers may have invalid YAML, check with `--debug`. Supplementary checks — add advisory positive signal: presence of `evals/evals.json` indicates evaluation-driven authoring (skill-creator plugin output). Core thresholds and band rubrics unchanged. last_updated bumped to 2026-06-26.

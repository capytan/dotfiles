# SKILL.md Quality Criteria

> Referenced during Phase 2 (Quality Assessment) for SKILL.md reviews.
> Derived from the skill-reviewer agent's check items A-J.
>
> **Source tags:**
> - `[official]` = Anthropic official documentation
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[custom]` = Derived from this repo's own practice
> - `[custom:derived-from-skill-reviewer]` = Extracted from skill-reviewer agent; Phase 0 research will update to official sources when found

---

## Criteria & Scoring (100 points total)

### A. Frontmatter Correctness (15 points)

`[custom:derived-from-skill-reviewer]` YAML frontmatter is the skill's identity and trigger mechanism.

**name**: max 64 chars, lowercase/numbers/hyphens only, no reserved words ("anthropic", "claude"), no XML tags, gerund form preferred, must match folder name.

**description**: non-empty, max 1024 chars, no XML tags, third person. Must cover: `[What] + [When/triggers] + [Capabilities] + [Negative triggers]`.

**Other**: no README.md in skill dir. Optional fields (compatibility, metadata, license) validated if present.

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

`[custom:derived-from-skill-reviewer]` Large skills must split content into referenced files.

**Size**: SKILL.md under 500 lines; total words (SKILL.md + refs) under 5,000; references one level deep only.

**Progressive disclosure**: over 300 lines without `references/` triggers a warning.

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

**Testing** `[custom:derived-from-skill-reviewer]`: recommend testing across model tiers (Haiku, Sonnet, Opus).

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

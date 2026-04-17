# Official Best Practices for SKILL.md

> This file is auto-updated in Phase 0 (Research).
> Manual edits are fine but may be overwritten on next research run.
> Items tagged `[custom]` are protected from overwrite.
>
> **Source tags:**
> - `[official]` = Anthropic official documentation
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[custom]` = Derived from this repo's own practice

last_updated: 2026-04-17
sources:
  - https://code.claude.com/docs/en/skills
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
  - https://agentskills.io

---

## Summary from Official Documentation

### What Skills Are `[official]`

> "Skills extend what Claude can do. Create a SKILL.md file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with /skill-name."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> "Create a skill when you keep pasting the same playbook, checklist, or multi-step procedure into chat, or when a section of CLAUDE.md has grown into a procedure rather than a fact. Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing until you need it."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> "Custom commands have been merged into skills. A file at .claude/commands/deploy.md and a skill at .claude/skills/deploy/SKILL.md both create /deploy and work the same way."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

- Skills follow the [Agent Skills](https://agentskills.io) open standard
- Claude Code extends the standard with invocation control, subagent execution, and dynamic context injection

### SKILL.md Structure `[official]`

> "Every skill needs a SKILL.md file with two parts: YAML frontmatter (between --- markers) that tells Claude when to use the skill, and markdown content with instructions Claude follows when the skill is invoked."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

Skill directory structure:
```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output showing expected format
└── scripts/
    └── validate.sh    # Script Claude can execute
```

### Where Skills Live `[official]`

| Location | Path | Applies to |
|----------|------|------------|
| Enterprise | Managed settings | All users in organization |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

> "When skills share the same name across levels, higher-priority locations win: enterprise > personal > project."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

- Live change detection: Claude Code watches skill directories; adding/editing/removing under `~/.claude/skills/`, project `.claude/skills/`, or `--add-dir` skills directories takes effect within the session without restart (new top-level directories still require restart). `[official]`
- Automatic discovery from nested `.claude/skills/` under the current working tree (monorepo support). `[official]`

### Frontmatter Reference `[official]`

> "All fields are optional. Only description is recommended so Claude knows when to use the skill."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name. Lowercase letters, numbers, hyphens only (max 64 chars). If omitted, uses directory name. Cannot contain XML tags. Cannot contain reserved words: `anthropic`, `claude`. |
| `description` | Recommended | What the skill does and when to use it. Max 1024 characters (hard cap — content is truncated). If omitted, uses the first paragraph of markdown. |
| `when_to_use` | No | Additional trigger phrases/example requests. Appended to `description` in the skill listing. **NEW 2026.** |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`). |
| `disable-model-invocation` | No | `true` prevents Claude from auto-loading. Default: `false`. |
| `user-invocable` | No | `false` hides from `/` menu. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without asking permission when skill is active. Space-separated string or YAML list. |
| `model` | No | Model to use when skill is active. |
| `effort` | No | Effort level: `low`, `medium`, `high`, `xhigh`, `max` (availability depends on model). Overrides session effort. |
| `context` | No | Set to `fork` to run in a forked subagent context. |
| `agent` | No | Subagent type when `context: fork`. Built-in (`Explore`, `Plan`, `general-purpose`) or custom. Defaults to `general-purpose`. |
| `hooks` | No | Hooks scoped to this skill's lifecycle. |
| `paths` | No | Glob patterns limiting when skill activates. Comma-separated string or YAML list. |
| `shell` | No | Shell for `!command` blocks. `bash` (default) or `powershell` (requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`). |

### Description: Length Limits & Truncation `[official]`

Two separate limits apply — do not confuse them:

1. **Hard validation cap: 1024 characters** for the `description` field itself.
   > "Must be non-empty, Maximum 1024 characters, Cannot contain XML tags"
   > — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

2. **Skill-listing truncation cap: 1,536 characters** for combined `description` + `when_to_use`, applied when the skill appears in the system-prompt listing.
   > "Front-load the key use case: the combined description and when_to_use text is truncated at 1,536 characters in the skill listing to reduce context usage."
   > — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> **Note on historical guidance**: The previous documented limit of "250 characters per entry" has been superseded. The 2026-04 docs specify 1,536 characters as the per-entry cap in listings (combined `description` + `when_to_use`), with the 1024-char field-level cap unchanged.

- Overall skill-listing budget scales at 1% of context window (fallback 8,000 chars)
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var raises the listing budget

### Description Writing Rules `[official]`

> "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems. Good: 'Processes Excel files and generates reports'. Avoid: 'I can help you...', 'You can use this to...'"
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

> "Be specific and include key terms. Include both what the Skill does and specific triggers/contexts for when to use it."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

`[semi-official]` Make descriptions slightly "pushy" to combat undertriggering:
> "currently Claude has a tendency to 'undertrigger' skills -- to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit 'pushy'."
> — https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md (retrieved 2026-04-17)

Description-optimization constraints from skill-creator's `improve_description.py`:
- Imperative phrasing ("Use this skill for..." over "This skill does...")
- Focus on user intent, not implementation
- Hard limit 1024 chars (truncated beyond)
- No overfitting: generalize to categories of intent, don't list specific queries

### Naming Conventions `[official]`

> "Consider using gerund form (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

Good: `processing-pdfs`, `analyzing-spreadsheets`, `testing-code`.
Acceptable alternatives: noun phrases (`pdf-processing`), action-oriented (`process-pdfs`).
Avoid: `helper`, `utils`, `tools`, reserved words (`anthropic`, `claude`), inconsistent patterns within a collection.

### Types of Skill Content `[official]`

**Reference content**: conventions, style guides, domain knowledge. Runs inline.
**Task content**: step-by-step procedures. Often `disable-model-invocation: true`.

> "Your SKILL.md can contain anything, but thinking through how you want the skill invoked (by you, by Claude, or both) and where you want it to run (inline or in a subagent) helps guide what to include."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

### Progressive Disclosure `[official]`

> "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

Three-tier loading model:
1. **Metadata** (name + description/when_to_use): always in context, ~80 tokens median per skill (range ~55-235 across Anthropic's official skills)
2. **SKILL.md body**: loads when skill triggers (<500 lines ideal, <5,000 tokens recommended)
3. **Bundled resources** (scripts/, references/, assets/): loaded or executed on demand

> "Reference supporting files from SKILL.md so Claude knows what each file contains and when to load it."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

### References: One Level Deep `[official]`

> "Keep references one level deep from SKILL.md. All reference files should link directly from SKILL.md to ensure Claude reads complete files when needed."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

> "Claude may partially read files when they're referenced from other referenced files. When encountering nested references, Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

### Table of Contents for Long Reference Files `[official]`

> "For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

### Degrees of Freedom `[official]`

Match specificity to task fragility:
- **High freedom** (text-based): multiple valid approaches, context-dependent decisions (e.g., code review)
- **Medium freedom** (pseudocode, parameterized scripts): preferred pattern with acceptable variation
- **Low freedom** (specific scripts, few parameters): fragile/consistency-critical operations (e.g., DB migration)

> "Think of Claude as a robot exploring a path: Narrow bridge with cliffs on both sides → low freedom; Open field with no hazards → high freedom."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

### Invocation Control `[official]`

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|----------------|-------------------|------------------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

> "The `user-invocable` field only controls menu visibility, not Skill tool access. Use `disable-model-invocation: true` to block programmatic invocation."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

### Skill Content Lifecycle `[official]` (NEW)

> "When you or Claude invoke a skill, the rendered SKILL.md content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> "Auto-compaction carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

### Running Skills in Subagents `[official]`

> "context: fork only makes sense for skills with explicit instructions. If your skill contains guidelines like 'use these API conventions' without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

| Approach | System prompt | Task | Also loads |
|----------|--------------|------|------------|
| Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

### String Substitutions `[official]`

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md |

Indexed arguments use shell-style quoting; multi-word values need quotes.

### Dynamic Context Injection `[official]`

> "The !`<command>` syntax runs shell commands before the skill content is sent to Claude."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

Multi-line: use fenced block opened with ` ```! `. Disable via `"disableSkillShellExecution": true` in settings.

### Workflows & Feedback Loops `[official]`

> "Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

Feedback-loop pattern: run validator → fix errors → repeat. Applies to both code (validate scripts) and prose (style-guide checklists).

### Content Guidelines `[official]`

- **Avoid time-sensitive info**: do not embed "after August 2025 use new API"; move deprecated info into an "Old patterns" section.
- **Consistent terminology**: pick one term per concept and use it throughout.
- **Template pattern**: provide strict templates for data formats; flexible defaults for analysis reports.
- **Examples pattern**: input/output pairs beat pure description for quality-sensitive outputs.
- **Avoid offering too many options**: pick a default, mark escape hatches.

### Evaluation-Driven Development `[official]` (NEW)

> "Create evaluations BEFORE writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined ones."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

Steps: identify gaps → create ≥3 eval scenarios → baseline without skill → write minimal instructions → iterate.

Recommended eval format:
```json
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF...",
  "files": ["test-files/document.pdf"],
  "expected_behavior": ["Successfully reads PDF...", "Extracts text from all pages...", "..."]
}
```

skill-creator 2026-04 supports 4 modes: Create, Eval, Improve, Benchmark. Tests 20 realistic trigger/non-trigger queries across up to 5 rounds of description optimization.

### CLAUDE.md vs Skills `[official]`

> "CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-04-17)

### Anti-patterns (Official) `[official]`

- **Windows-style paths**: always use forward slashes (`scripts/helper.py`, not `scripts\helper.py`)
- **Too many options without defaults**: pick a primary, name escape hatches
- **Punting to Claude in scripts**: handle errors explicitly
- **Voodoo constants**: document magic numbers ("30s timeout accounts for slow connections")
- **Assuming tools are installed**: state dependencies explicitly
- **Unqualified MCP tool names**: use `ServerName:tool_name` format

### Testing `[official]`

> "Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the models you plan to use it with."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-04-17)

Per-model considerations: Haiku (does the skill give enough guidance?), Sonnet (is it clear and efficient?), Opus (does it avoid over-explaining?).

### Troubleshooting `[official]`

**Skill not triggering:**
1. Description includes keywords users would naturally say
2. Verify skill in `What skills are available?`
3. Rephrase request to match description
4. Invoke directly with `/skill-name`

**Skill triggers too often:**
1. Make description more specific
2. Add `disable-model-invocation: true`

**Skill descriptions cut short:**
- Budget scales at 1% of context window (fallback 8,000 chars)
- Front-load key use case (1,536-char per-entry cap in listing)
- Set `SLASH_COMMAND_TOOL_CHAR_BUDGET` to raise budget

### Checklist for Effective Skills `[official]`

**Core quality:**
- Description specific and includes key terms (what + when)
- SKILL.md body under 500 lines
- Additional details in separate files (if needed)
- No time-sensitive info (or in "old patterns" section)
- Consistent terminology
- Examples are concrete, not abstract
- File references are one level deep
- Progressive disclosure used appropriately
- Workflows have clear steps

**Code and scripts:**
- Scripts solve problems rather than punt
- Error handling explicit and helpful
- No voodoo constants
- Required packages listed and verified
- No Windows-style paths
- Validation/verification steps for critical operations

**Testing:**
- ≥3 evaluations created
- Tested with Haiku, Sonnet, Opus
- Real-usage testing
- Team feedback incorporated

---

## Changelog

- 2026-03-29: Initial skeleton
- 2026-03-30: Populated with official documentation from code.claude.com/docs/en/skills. Added: skill structure, frontmatter reference, 250-char truncation, invocation control, supporting files (500-line limit), subagent execution, string substitutions, dynamic context injection, CLAUDE.md vs skills, troubleshooting.
- 2026-04-17: Major refresh against latest docs. Corrected description limits: hard cap is 1024 chars (field), truncation is 1,536 chars (combined `description` + `when_to_use` in listings) — previous 250-char figure was outdated. Added new frontmatter field `when_to_use`. Added `xhigh` effort level. Added skill content lifecycle section (session-wide persistence, compaction budgets: 5k tokens per skill, 25k combined). Added third-person rule, "pushy" description guidance, gerund naming, one-level-deep references rule, 100-line TOC rule, evaluation-driven development, degrees-of-freedom framing, workflows/feedback-loops, content guidelines, anti-patterns (official), per-model testing, explicit checklist. Added sources: platform.claude.com best-practices, skill-creator repo.

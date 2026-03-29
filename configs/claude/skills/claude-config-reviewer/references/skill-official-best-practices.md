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

last_updated: 2026-03-30
sources:
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/best-practices
  - https://agentskills.io

---

## Summary from Official Documentation

### What Skills Are `[official]`

> "Skills extend what Claude can do. Create a SKILL.md file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with /skill-name."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

> "Custom commands have been merged into skills. A file at .claude/commands/deploy.md and a skill at .claude/skills/deploy/SKILL.md both create /deploy and work the same way."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

- Skills follow the [Agent Skills](https://agentskills.io) open standard
- Claude Code extends the standard with invocation control, subagent execution, and dynamic context injection

### SKILL.md Structure `[official]`

> "Every skill needs a SKILL.md file with two parts: YAML frontmatter (between --- markers) that tells Claude when to use the skill, and markdown content with instructions Claude follows when the skill is invoked."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

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
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

### Frontmatter Reference `[official]`

> "All fields are optional. Only description is recommended so Claude knows when to use the skill."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name. Lowercase letters, numbers, hyphens only (max 64 chars). If omitted, uses directory name. |
| `description` | Recommended | What the skill does and when to use it. Front-load the key use case: descriptions longer than 250 characters are truncated. |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`). |
| `disable-model-invocation` | No | `true` prevents Claude from auto-loading. Default: `false`. |
| `user-invocable` | No | `false` hides from `/` menu. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without asking permission when skill is active. |
| `model` | No | Model to use when skill is active. |
| `effort` | No | Effort level. Options: `low`, `medium`, `high`, `max` (Opus 4.6 only). |
| `context` | No | Set to `fork` to run in a forked subagent context. |
| `agent` | No | Subagent type when `context: fork`. Options: built-in (`Explore`, `Plan`, `general-purpose`) or custom. |
| `hooks` | No | Hooks scoped to this skill's lifecycle. |
| `paths` | No | Glob patterns limiting when skill is activated. |
| `shell` | No | Shell for `!command` blocks. `bash` (default) or `powershell`. |

### Types of Skill Content `[official]`

**Reference content**: Conventions, patterns, style guides, domain knowledge. Runs inline.

**Task content**: Step-by-step instructions for specific actions. Often `disable-model-invocation: true`.

> "Your SKILL.md can contain anything, but thinking through how you want the skill invoked (by you, by Claude, or both) and where you want it to run (inline or in a subagent) helps guide what to include."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

### Description Best Practices `[official]`

> "The name field becomes the /slash-command, and the description helps Claude decide when to load it automatically."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

> "Front-load the key use case: descriptions longer than 250 characters are truncated in the skill listing to reduce context usage."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

- Budget scales at 1% of context window, with fallback of 8,000 chars
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var can raise limit
- Each entry capped at 250 chars regardless of budget

### Invocation Control `[official]`

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|----------------|-------------------|------------------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

### Supporting Files `[official]`

> "Keep SKILL.md under 500 lines. Move detailed reference material to separate files."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

> "Reference supporting files from SKILL.md so Claude knows what each file contains and when to load it."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

### Running Skills in Subagents `[official]`

> "context: fork only makes sense for skills with explicit instructions. If your skill contains guidelines like 'use these API conventions' without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

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

### Dynamic Context Injection `[official]`

> "The !`<command>` syntax runs shell commands before the skill content is sent to Claude."
> — https://code.claude.com/docs/en/skills (retrieved 2026-03-30)

### CLAUDE.md vs Skills `[official]`

> "CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-30)

### Troubleshooting `[official]`

**Skill not triggering:**
1. Check description includes keywords users would naturally say
2. Verify the skill appears in `What skills are available?`
3. Try rephrasing to match description more closely
4. Invoke directly with `/skill-name`

**Skill triggers too often:**
1. Make description more specific
2. Add `disable-model-invocation: true`

**Skill descriptions cut short:**
- Budget scales at 1% of context window (fallback 8,000 chars)
- Front-load the key use case (250 char cap per entry)
- Set `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var to raise limit

---

## Changelog

- 2026-03-29: Initial skeleton
- 2026-03-30: Populated with official documentation from code.claude.com/docs/en/skills. Added: skill structure, frontmatter reference (all fields), types of content, description best practices (250-char truncation, budget scaling), invocation control matrix, supporting files guidance (500-line limit), subagent execution (context:fork), string substitutions, dynamic context injection, CLAUDE.md vs skills distinction, troubleshooting section.

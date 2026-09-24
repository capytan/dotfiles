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

last_updated: 2026-09-24
sources:
  - https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/changelog
  - https://code.claude.com/docs/en/hooks (Hooks in skills and agents)
  - https://code.claude.com/docs/en/settings-reference (skill* settings)
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
  - https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
  - https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator
  - https://agentskills.io/specification
  - https://agentskills.io/skill-creation/evaluating-skills

---

## Contents

Summary from Official Documentation:
- What Skills Are
- SKILL.md Structure
- Where Skills Live
- Frontmatter Reference
- Portability: Frontmatter Outside Claude Code
- Description: Length Limits & Truncation
- Description Writing Rules
- Naming Conventions
- Types of Skill Content
- Progressive Disclosure
- References: One Level Deep
- Table of Contents for Long Reference Files
- Degrees of Freedom
- Invocation Control
- Pre-approved Tools Are Turn-Scoped & Not Trust-Gated
- Skill Content Lifecycle
- Running Skills in Subagents
- String Substitutions
- Dynamic Context Injection
- Injected-Command Failure Semantics
- Skills Synced from claude.ai & the Reserved `synced` Name
- Skill Visibility: `skillOverrides`, Aliases & `Skill()` Rules
- Finding Unused Skills: `/skill-doctor`
- Workflows & Feedback Loops
- Content Guidelines
- Claude 5-Generation Skill Authoring
- Evaluation-Driven Development
- CLAUDE.md vs Skills
- Anti-patterns (Official)
- Testing
- Troubleshooting
- Checklist for Effective Skills

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

**Bundled skills `[official]` (2026-06):**
> "Claude Code includes a set of bundled skills that are available in every session unless disabled with the `disableBundledSkills` setting, including `/code-review`, `/batch`, `/debug`, `/loop`, and `/claude-api`."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-10)

Three bundled skills work together to launch the app and confirm changes against the running app: `/run` (launch and drive the app), `/verify` (build and run to confirm a change), `/run-skill-generator` (records the build/launch recipe as a per-project skill at `.claude/skills/run-<name>/`). All three require Claude Code v2.1.145+.

**A skill at any scope (personal/project/plugin) overrides a bundled skill with the same name `[official]` (added 2026-06-26).** For example, a `code-review` skill in your project's `.claude/skills/` replaces the bundled `/code-review`. Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels. — https://code.claude.com/docs/en/skills (retrieved 2026-06-26)

**…but NOT the bundled skill's aliases `[official]` (added 2026-09-04, re-verified 2026-09-16):** "Your skill replaces the bundled command, but not its aliases. A project `code-review` skill replaces `/code-review`, and the bundled alias `/review` never runs your skill" — https://code.claude.com/docs/en/skills (retrieved 2026-09-16). Alias-keyed `skillOverrides` and `Skill()` deny semantics are detailed in "Skill Visibility" below; the docs now date both fixes to **v2.1.260** (the 2026-09-04 entry cited changelog v2.1.248 — docs win, conflict noted). Note `/doctor` itself is a bundled skill as of v2.1.205 (alias `checkup`) and is exempt from `disableBundledSkills`; per the commands reference (retrieved 2026-09-16) `/doctor` also "Finds unused skills, MCP servers, and plugins versus their context cost" and "migrates the always-loaded guidance that remains into skills and nested `CLAUDE.md` files that load on demand". Also listed as bundled: `/workflow-authoring` ("available only when dynamic workflows are enabled").

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
- **Plugin-skill folders `[official]` (added 2026-06-26):** "Add a `.claude-plugin/plugin.json` to a skill folder and it loads as a plugin named `<name>@skills-dir`, so it can bundle agents, hooks, and MCP servers." (project skills require accepting the workspace-trust dialog first.) — https://code.claude.com/docs/en/skills (retrieved 2026-06-26)
- Automatic discovery from nested `.claude/skills/` under the current working tree (monorepo support). `[official]`
- **Symlinked skill directories `[official]` (added 2026-09-04):** "A `<skill-name>` entry in the enterprise, personal, or project locations can be a symlink to a directory elsewhere on disk. Claude Code follows the symlink and reads `SKILL.md` from the target directory, and if the same target is reachable from more than one location, Claude Code loads the skill once." — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)
- **`/cd` picks up the new directory's project skills** on v2.1.246+. `[official]` (retrieved 2026-09-04)
- **Live change detection scope `[official]` (clarified 2026-06-26):** covers `SKILL.md` text only; for a skill folder that is also a plugin, edits to `hooks/`, `.mcp.json`, `agents/`, and `output-styles/` need `/reload-plugins` to take effect. Watching is off "in bare mode"; an `--add-dir` directory's `.claude/skills/` is watched but its `.claude/commands/` and `.claude/agents/` are not (added 2026-09-16, retrieved 2026-09-16).
- **Nested skills load lazily `[official]` (added 2026-09-16):** "Skills in a `.claude/skills/` directory below where you started don't load at startup. They load the first time Claude reads or edits a file in that subdirectory and stay available for the rest of the session. Until then they don't appear in the `/` menu and you can't invoke them by name. To load them sooner, run `/add-dir` with the subdirectory's path, which requires Claude Code v2.1.257 or later." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)
- **Legacy command files `[official]` (added 2026-09-16):** "a Markdown file in `.claude/commands/` is the older format and still works. It supports the same frontmatter except `name` and `paths`." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16). Reviewer implication: `name:` or `paths:` in a `.claude/commands/*.md` file is inert — advise migrating to a skill directory.
- **Cowork / cloud / Desktop scheduled tasks `[official]` (clarified 2026-09-16):** Cowork and cloud sessions (incl. routines) "don't read `~/.claude/skills/` on your machine"; "Cloud sessions additionally load project skills committed to the cloned repository's `.claude/skills/`", or a plugin "declared in the repository's `.claude/settings.json`" (user-level plugins don't transfer). "Desktop scheduled tasks run locally on your machine, so they do load `~/.claude/skills/`." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)

### Frontmatter Reference `[official]`

> "All fields are optional. Only description is recommended so Claude knows when to use the skill."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name. Lowercase letters, numbers, hyphens only (max 64 chars). If omitted, uses directory name. Cannot contain XML tags. Cannot contain reserved words: `anthropic`, `claude`. |
| `description` | Recommended | What the skill does and when to use it. Truncated at 1,536 chars combined with `when_to_use` in the skill listing. If omitted, "uses the first non-empty line of the markdown content" (wording updated 2026-09-16; previously recorded as "first paragraph"). |
| `when_to_use` | No | Additional trigger phrases/example requests. Appended to `description` in the skill listing. **NEW 2026.** |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`). |
| `arguments` | No | Named positional arguments for `$name` substitution. Space-separated string or YAML list; names map to positions in order. **NEW 2026.** |
| `disable-model-invocation` | No | `true` prevents Claude from auto-loading. Also prevents the skill from being preloaded into subagents. Default: `false`. |
| `user-invocable` | No | `false` hides from `/` menu. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without asking permission **during the turn that invokes the skill; the grant clears when you send your next message** (clarified 2026-09-04 — persistence applies to the skill's instructions, not its permissions). Space- or comma-separated string or YAML list. `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` (and, in plugin skills, `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`) are substituted in Bash rules here as well as in the body. |
| `disallowed-tools` | No | Tools removed from Claude's pool while the skill is active (e.g., block `AskUserQuestion` in a background loop). Restriction clears on the next user message. Like deny rules, cannot remove `EndConversation` while any other tool remains. **NEW 2026.** |
| `model` | No | Model to use when skill is active. Turn-scoped: "The override applies for the rest of the current turn and is not saved to settings; the session model resumes on your next prompt." Accepts same values as `/model`, or `inherit`. Also silently not used (added 2026-09-16): "In auto mode, and in plan mode while the classifier reviews commands, a model that auto mode doesn't support also isn't used, and the session keeps its current model." |
| `effort` | No | Effort level: `low`, `medium`, `high`, `xhigh`, `max` (availability depends on model). Overrides session effort. Changelog v2.1.267 (2026-09-09): "Fixed `effort:` frontmatter on custom commands, skills, and subagents being ignored on models whose default effort is still pinned (Opus 4.7, Opus 4.8, Fable 5)" — not an authoring defect on older versions. |
| `context` | No | Set to `fork` to run in a forked subagent context. |
| `agent` | No | Subagent type when `context: fork`. Built-in (`Explore`, `Plan`, `general-purpose`) or custom. Defaults to `general-purpose`. |
| `hooks` | No | **Corrected 2026-09-16** — not lifecycle-scoped: "Hooks that Claude Code registers when the skill is invoked and keeps running for the rest of the session." Same config format as settings hooks; set `once: true` on a hook to remove it "after its first successful run". **Not workspace-trust-gated for project skills** (see "Pre-approved Tools…" below). — https://code.claude.com/docs/en/skills and https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents (retrieved 2026-09-16) |
| `paths` | No | Glob patterns limiting when skill activates. Comma-separated string or YAML list. |
| `shell` | No | Shell for `!command` blocks. `bash` (default) or `powershell` (requires `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`). |
| `background` | No | Only with `context: fork`. `false` waits for the fork's result in the invoking turn instead of backgrounding it. Default: `true`. Requires v2.1.218+. |
| `metadata` | No | Free-form YAML **map** for your own tooling. "Claude Code doesn't act on its contents, and drops a value that isn't a map. Don't reuse frontmatter field names such as `paths` as keys." |
| `license` | No | License covering the skill. Agent Skills spec field; Claude Code accepts but doesn't act on it. |
| `compatibility` | No | Environment requirements per the Agent Skills spec. "Accepts a string of up to 500 characters. Claude Code accepts the field but doesn't act on it." |

**`model` and org allowlists (added 2026-08-12) `[official]`:** "A value excluded by your organization's `availableModels` allowlist is not used and the session keeps its current model. With `context: fork`, the value sets the forked subagent's model instead, and an excluded value follows the same rules as a subagent model override." — https://code.claude.com/docs/en/skills (retrieved 2026-08-12). Blocked values degrade silently; never score a `model:` value as a hard failure on allowlist grounds.

### Portability: Frontmatter Outside Claude Code `[official]` (added 2026-08-12)

Claude Code accepts every field in the table above. Other distribution paths do not:

| Distribution path | Fields allowed |
|---|---|
| Claude Code skills at any level, including plugin skills | Every field in the table above |
| claude.ai skill uploads, the Skills API, `package_skill.py` from `anthropics/skills` | `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` |

> "If you include any field the spec doesn't allow, packaging or upload fails with a hard error instead of ignoring the field:
> `Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed properties are: allowed-tools, compatibility, description, license, metadata, name`"
> — https://code.claude.com/docs/en/skills (retrieved 2026-08-12)

**Scoring implication:** Claude Code-only fields (`when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`) are **correct and expected** in a Claude Code-only skill — never deduct for them. Flag them only when the skill is explicitly intended for claude.ai upload, the Skills API, or `package_skill.py` packaging, where they are a hard error. The same applies to Claude Code-only body features such as dynamic context injection (`` !`command` ``), which "don't function in claude.ai chat or through the API." Enabling a personal skill for Cowork/cloud sessions is an upload, "so the same rules apply" (retrieved 2026-09-16).

**Agent Skills spec constraints on the six portable fields `[official]` (added 2026-09-16, https://agentskills.io/specification, retrieved 2026-09-16):**
- `name` (required in the spec): "Must be 1-64 characters", "May only contain unicode lowercase alphanumeric characters (`a-z`, `0-9`) and hyphens (`-`)", "Must not start or end with a hyphen (`-`)", "Must not contain consecutive hyphens (`--`)", "**Must match the parent directory name**".
- `description` (required in the spec): "Must be 1-1024 characters".
- `compatibility`: "Must be 1-500 characters if provided"; "Most skills do not need the `compatibility` field."
- `metadata`: "A map from string keys to string values".
- `allowed-tools`: "A space-separated string of tools that are pre-approved to run", "Experimental. Support for this field may vary between agent implementations."
- Validator: `skills-ref validate ./my-skill` (github.com/agentskills/agentskills/tree/main/skills-ref).

Conflict with Claude Code: in a personal/project skill Claude Code treats `name` as a display label only (see command-name resolution), so a `name` ≠ directory mismatch is harmless **locally** but is a **spec violation** on every export path. Same for the 1,024-char `description` cap: still stated by the spec and by platform best-practices, absent from code.claude.com. Apply both only to export-targeted skills.

### Description: Length Limits & Truncation `[official]`

One operative limit applies as of 2026-07-25:

1. ~~**Hard validation cap: 1024 characters** for the `description` field itself.~~ **Retracted 2026-07-25** — current docs no longer state a field-level cap. Do not deduct on the 1024 figure alone. (Historic quote, 2026-04-17: "Must be non-empty, Maximum 1024 characters, Cannot contain XML tags".)

2. **Skill-listing truncation cap: 1,536 characters** for combined `description` + `when_to_use`, applied when the skill appears in the system-prompt listing. **This is the operative limit.**
   > "Front-load the key use case: the combined description and when_to_use text is truncated at 1,536 characters in the skill listing to reduce context usage."
   > — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> **Note on historical guidance**: Both the "250 characters per entry" limit and the 1024-char field-level cap have been superseded. Current docs specify only 1,536 characters as the per-entry cap in listings (combined `description` + `when_to_use`). `[official]` (2026-07-25) **Setting name corrected 2026-09-04**: the cap "is configurable with `skillListingMaxDescChars`" — the previously-recorded name `maxSkillDescriptionChars` no longer appears in the docs.

- Overall skill-listing budget scales at 1% of context window. When the budget overflows, descriptions for the **least-invoked** skills are dropped first, so skills you actually use keep their full text — names are always listed. `[official]` (updated 2026-05)
- Raise the budget with the `skillListingBudgetFraction` setting (e.g. `0.02` = 2%) or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var (fixed char count). Free budget for other skills by setting low-priority entries to `"name-only"` in `skillOverrides`.
- Run `/doctor` to see whether the budget is overflowing and which skills are affected. `[official]` (2026-05)
- **Freshness note (2026-09-16):** the 2026-09-16 extraction of code.claude.com/docs/en/skills did not surface the `skillListingBudgetFraction` / `SLASH_COMMAND_TOOL_CHAR_BUDGET` / "1%" text, but the settings reference (retrieved 2026-09-16) still lists `skillListingMaxDescChars` — "Cap each skill's description length in the skill listing" — and `skillListingBudgetFraction` — "Reserve more or less context for the skill listing" — both linking to the skills page anchor `#skill-descriptions-are-cut-short`. Treat the mechanics above as current; re-verify the env-var name on the next run.

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
- Listing limit 1,536 chars combined with `when_to_use` (truncated beyond)
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

**File references are Read-tool instructions, not `@` imports** `[official]` (clarified 2026-05). Unlike CLAUDE.md (which supports `@path` imports), references in SKILL.md are plain paths that Claude reads on demand via the Read/bash tools — they consume zero context tokens until read. Name the file path explicitly in the relevant step so Claude knows to read it. From the official runtime-environment guidance: "Claude uses bash Read tools to access SKILL.md and other files from the filesystem when needed... No context penalty for large files." (platform.claude.com best-practices, retrieved 2026-05-30)

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

**Permission rules for skills `[official]` (2026-06):** specific skills can be allowed/denied via permission rules — `Skill(name)` for exact match, `Skill(name *)` for prefix match with any arguments; denying `Skill` itself disables all skills. `disable-model-invocation: true` "removes the skill from Claude's context entirely."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-10)

### Pre-approved Tools Are Turn-Scoped & Not Trust-Gated `[official]` (added 2026-09-04)

> "The `allowed-tools` field grants permission for the listed tools during the turn that invokes the skill... The grant clears when you send your next message, even though the skill content stays in context; invoking the skill again re-applies it for that turn."
> — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)

It does not restrict availability — every tool remains callable under normal permission settings. For session-wide pre-approval, use permission allow rules instead.

> "Workspace trust doesn't gate this field. Claude Code applies a project skill's `allowed-tools` whenever you or Claude invoke the skill, including in a `-p` run in a folder you've never trusted. A skill can grant itself broad tool access, so review the `allowed-tools` of skills checked into a repository before you run Claude Code there."

Reviewer implication: overly-broad `allowed-tools` (e.g. `Bash(*)`) in a repo-committed skill is a security finding, not just style.

**Frontmatter `hooks` share the same trust gap and outlive the turn `[official]` (added 2026-09-16):**
> "Skill hooks: Claude Code registers them when you or Claude invoke the skill and keeps running them for the rest of the session, on turns after the skill's own turn as well. To have Claude Code remove a hook after its first successful run instead, set `once: true` on it."
> "Frontmatter hooks in a project skill follow the same workspace trust rule as hooks in settings files. Claude Code registers them when you or Claude invoke the skill, including in a `-p` run in a folder you haven't trusted."
> — https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents (retrieved 2026-09-16)

Contrast: subagent frontmatter hooks run only while the subagent runs and, for project subagents, only after the trust dialog is accepted (v2.1.218+). Reviewer implication: a repo-committed skill's `hooks:` block is executable code that persists for the session — review its `command` and `matcher` like `allowed-tools`, and expect `once: true` on one-shot setup hooks.

### Skill Content Lifecycle `[official]` (NEW)

> "When you or Claude invoke a skill, the rendered SKILL.md content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task as standing instructions rather than one-time steps."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

> "Auto-compaction carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first 5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens. Claude Code fills this budget starting from the most recently invoked skill, so older skills can be dropped entirely after compaction if you have invoked many in one session."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-10)

> "Keep the body itself concise. Once a skill loads, its content stays in context across turns, so every line is a recurring token cost. State what to do rather than narrating how or why."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-10)

**Re-invocation dedup `[official]` (added 2026-09-04):** "When Claude re-invokes a skill whose rendered content is identical to the copy already in context, Claude Code adds a short note that the skill is already loaded rather than a second copy of the content. When the rendered content differs, because the arguments changed or a dynamic context command produced new output, Claude Code appends the full content again." — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)

**"Skill stopped working" diagnosis `[official]` (added 2026-09-16):** "If a skill seems to stop influencing behavior after the first response, the content is usually still present and the model is choosing other tools or approaches. Strengthen the skill's `description` and instructions so the model keeps preferring it, or use hooks to enforce behavior deterministically. If the skill is large or you invoked several others after it, re-invoke it after compaction to restore the full content." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)

### Running Skills in Subagents `[official]`

> "context: fork only makes sense for skills with explicit instructions. If your skill contains guidelines like 'use these API conventions' without a task, the subagent receives the guidelines but no actionable prompt, and returns without meaningful output."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

| Approach | System prompt | Task | Also loads |
|----------|--------------|------|------------|
| Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md, **except when the agent is Explore or Plan** |
| Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md |

> "The built-in Explore and Plan agents skip CLAUDE.md and git status to keep their context small, so a forked skill using `agent: Explore` sees only the SKILL.md content and the agent's own system prompt."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-10)

**Forced-foreground cases and `/rewind` `[official]` (added 2026-09-16):** Claude Code waits for the fork "even when the skill doesn't set `background: false`" in non-interactive mode (`-p` / Agent SDK), when `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, "When you invoke a forked skill while an earlier invocation of the same skill is still running", and "When a scheduled task fires with the skill as its prompt". Also: "A forked skill that runs in the background applies its edits outside your session's checkpoints, so `/rewind` doesn't undo them; use git to revert them." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16). Changelog v2.1.265 fixed forked skills "not streaming their kickoff prompt and, with `--forward-subagent-text`, their text turns as progress events in stream-json".

### String Substitutions `[official]`

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking. If absent from content, args are appended as `ARGUMENTS: <value>`. |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `$name` | Named argument declared in the `arguments` frontmatter list; maps to positions in order. **NEW 2026.** |
| `${CLAUDE_SESSION_ID}` | Current session ID |
| `${CLAUDE_EFFORT}` | Current effort level (`low`/`medium`/`high`/`xhigh`/`max`; ultracode reports `xhigh`). **NEW 2026.** |
| `${CLAUDE_SKILL_DIR}` | Directory containing the skill's SKILL.md (for plugin skills, the skill's subdirectory, not the plugin root) |
| `${CLAUDE_PROJECT_DIR}` | The project root directory — same path hooks/MCP servers receive as `CLAUDE_PROJECT_DIR`. Requires v2.1.196+. **NEW 2026-09.** |
| `${CLAUDE_PLUGIN_ROOT}` | The plugin's installation directory. Substituted only in plugin skills. **NEW 2026-09.** |
| `${CLAUDE_PLUGIN_DATA}` | The plugin's persistent data directory, survives plugin updates. Substituted only in plugin skills. **NEW 2026-09.** |

Indexed arguments use shell-style quoting; multi-word values need quotes.

**Substitution also runs in `allowed-tools` `[official]` (added 2026-09-04):** "Claude Code substitutes `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` in two places: the skill's markdown content, and Bash rules in the `allowed-tools` frontmatter... Using the same variable in both places lets a skill run a bundled script without a permission prompt." (e.g. `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)` matching a body step that runs the same script.) — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)

**Argument literalness & escaping `[official]` (added 2026-09-04):** an indexed placeholder with no corresponding argument stays as literal text; a named placeholder with no matching argument expands to empty string. An argument value containing `$1`/`$ARGUMENTS` is inserted literally, never re-expanded. Escape a literal `$` before a digit/`ARGUMENTS`/declared name with a single backslash (`\$1.00`); the escape does not apply to `${CLAUDE_*}` variables. — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)

### Dynamic Context Injection `[official]`

> "The !`<command>` syntax runs shell commands before the skill content is sent to Claude."
> — https://code.claude.com/docs/en/skills (retrieved 2026-04-17)

Multi-line: use fenced block opened with ` ```! `. Disable via `"disableSkillShellExecution": true` in settings (each command replaced with `[shell command execution disabled by policy]`; bundled/managed skills unaffected).

Recognition rules `[official]` (added 2026-09-04): the inline form is only recognized when `!` appears at the start of a line or immediately after whitespace — `` KEY=!`cmd` `` stays literal. Substitution runs once over the original file; command output is not re-scanned for further placeholders.

### Injected-Command Failure Semantics `[official]` (added 2026-09-04)

Execution: commands run through the Bash tool (or PowerShell per `shell:`), in the session shell's current working directory (which moves with `cd` — use `${CLAUDE_SKILL_DIR}`/`${CLAUDE_PROJECT_DIR}` for stable paths), stderr merged into stdout, under the Bash tool's default 2-minute timeout (auto-backgroundable commands are moved to background and the skill still renders; others are killed and the invocation aborts). `shell: bash` on Windows without Git Bash fails the invocation outright.

> "A failed command aborts the entire skill invocation, not just its own placeholder. Claude never sees the skill content for that invocation."
> — https://code.claude.com/docs/en/skills (retrieved 2026-09-04)

- Any non-zero exit fails, except exit code 1 from the search/comparison command carveout list (e.g. `grep`, `git diff`); exit ≥2 fails even for those.
- "With the default `bash` shell, append `|| true` to any other command you expect to exit non-zero. A check script that exits 1 when it finds problems is one example."
- "Injected commands never prompt for permission. When a command's permission check returns anything other than allow, Claude Code aborts the invocation. This includes a rule that would normally ask you." Pre-approve unmatched commands with `allowed-tools`; **a matching ask or deny rule still aborts the invocation regardless of `allowed-tools`** ("Deny and ask rules still override `allowed-tools`", retrieved 2026-09-16).
- Error strings (added 2026-09-16): a failed command shows `Shell command failed for pattern "..."` with the command output under `[stderr]`; a permission failure shows `Shell command permission check failed for pattern "..."`.
- **Auto-mode exception `[official]` (added 2026-09-16):** "In auto mode, a command that would otherwise need your approval doesn't abort the invocation. The skill loads with an instruction telling Claude to run the command first, and Claude's own call then goes through auto mode's usual checks. The invocation still aborts in a forked skill that sets `agent`, and in a session where Claude doesn't have the shell tool that runs injected commands." — https://code.claude.com/docs/en/skills (retrieved 2026-09-16). Changelog v2.1.271 (2026-09-14): "Changed auto mode so that a skill's or slash command's inline `!` shell commands follow default-mode permission rules instead of the classifier; a command no rule decides runs as a reviewed tool call". A deny-rule match still aborts in every mode.

Reviewer implication: a `` !`command` `` that can legitimately exit non-zero without `|| true`, or that matches an ask/deny permission rule, silently breaks the whole skill. Do not relax the finding because the author uses auto mode — the skill must also work in default mode, in `-p`, and in forked skills with `agent` set.

### Skills Synced from claude.ai & the Reserved `synced` Name `[official]` (added 2026-09-04)

- The folder name `synced` is **reserved** in the enterprise, personal, and project skills locations, in any capitalization: Claude Code downloads claude.ai-enabled skills into `~/.claude/skills/synced/` (via `CLAUDE_CODE_SYNC_SKILLS=1` in a `-p` run) "and skips a skill you author at that name."
- **Name collisions no longer skip the synced skill — corrected 2026-09-16 (v2.1.269):** synced skills now get a namespaced command. "You can invoke a synced skill by its full name, `/anthropic-skills:<name>`, or by its short name, `/<name>`. When another command uses that short name, `/<name>` runs the other command, and the synced skill runs only as `/anthropic-skills:<name>`. With a local `deploy` skill and a synced `deploy`, `/deploy` runs the local skill and `/anthropic-skills:deploy` runs the synced one. Before v2.1.269, a synced skill had only its short name." Changelog v2.1.269 (2026-09-11): "Changed skills synced from claude.ai in cloud sessions to be named `anthropic-skills:<name>`, matching Claude Desktop; the bare name still works when nothing else uses it". The name comparison still ignores case, spacing, invisible characters, and compatibility forms (v2.1.228+). The `/skills` menu and `/context` group synced skills under `claude.ai sync`.
- Synced-skill frontmatter is honored but display text is sanitized (control characters removed, angle brackets escaped). In regular local sessions the synced body's `` !` `` commands do not run, `@` references are not attached, and `${CLAUDE_PROJECT_DIR}`/`${CLAUDE_SESSION_ID}` reach Claude as literal text.
- Cowork and cloud sessions (including routines) **don't read `~/.claude/skills/`** — a personal-only skill "was not found" there; enable it on claude.ai or commit it to the repo's `.claude/skills/`.
- Housekeeping (changelog, 2026-09): synced copies "not refreshed within `cleanupPeriodDays` now move to the recoverable trash at the next launch" after sign-out (v2.1.271); synced skills also move to the trash when "your organization turns Skills off" (v2.1.273).
- **Terminal sync (added 2026-09-24)**: "In your terminal, Claude Code syncs those skills in sessions where you sign in with your claude.ai account. When the session starts, Claude Code downloads your account's skills into `~/.claude/skills/synced/` in the background, then checks claude.ai for changes about every 10 minutes while the session runs. … Syncing in terminal sessions requires Claude Code v2.1.273 or later." Opt-out: "set `syncClaudeAiSkills` to `false` in your user settings. Claude Code stops downloading, and the next time it starts it moves the skills it already synced to `~/.claude/skills/.trash/` and no longer loads them." Changelog v2.1.275 (2026-09-17): "Added syncing of the skills and plugins enabled on your claude.ai account to terminal sessions signed in with it; opt out with `syncClaudeAiSkills: false` or `syncClaudeAiPlugins: false`". v2.1.275: Write/Edit results on files in the synced folder "now say the change is not saved to your account and how to save it". v2.1.280: fixed hand-authored skills in `~/.claude/skills/` being moved to `.trash/` "when a `manifest.json` in that folder listed their names". v2.1.281: synced skills shown "by their short name when no other command uses it, not `anthropic-skills:<name>`" in `/`, `/skills`, `/context`, `/plugin`. — https://code.claude.com/docs/en/skills + changelog (retrieved 2026-09-24)
- Reviewer implication: a personal skill whose name matches a claude.ai-enabled skill now coexists with a synced copy in every signed-in terminal session (local wins the short name). Editing files under `~/.claude/skills/synced/` is lost on the next sync — flag any workflow/instruction that edits synced skills in place.

> — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)

### Skill Visibility: `skillOverrides`, Aliases & `Skill()` Rules `[official]` (added 2026-09-16)

`skillOverrides` states: `"on"` (name + description listed, in `/` menu), `"name-only"` (name only), `"user-invocable-only"` (hidden from Claude, in menu; the `/skills` menu labels it `user-only`), `"off"` (hidden everywhere; "As of v2.1.199, `"off"` also hides the skill from the command lists advertised to Remote Control clients and to Agent SDK callers"). Absent = `"on"`. "Plugin skills are not affected by `skillOverrides`. Manage those through `/plugin` instead." The `/skills` menu writes the setting to `.claude/settings.local.json` (Space cycles, Esc saves).

> "Some bundled skills have aliases, such as `checkup` for `/doctor`. If you set a `skillOverrides` entry under an alias in managed settings or in a file you pass with the `--settings` flag, Claude Code applies it to the skill behind the alias. You can only restrict a skill further through an alias, never make it more visible, and if you also set an entry under the skill's own name in managed settings, that entry takes precedence. Before v2.1.260, Claude Code didn't apply an entry under an alias to the skill in any settings source."
> "In user, project, and local settings, Claude Code matches entries against skill names only. If you set an entry for `review` there, it applies to a skill named `review`, not to the bundled `/code-review` through its `/review` alias."
> — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)

Permission rules: `Skill(name)` exact, `Skill(name *)` prefix with args. "If your `deny` rule names an alias or an unqualified name rather than the skill's own name, Claude Code still blocks the skill: with `Skill(review)` it blocks the bundled `/code-review` through its `/review` alias, and with `Skill(deploy)` it blocks a nested skill listed as `apps/web:deploy` through its unqualified name. Before v2.1.260, Claude Code didn't block a nested skill listed under its qualified name when the deny rule named only the unqualified name." "Claude Code matches an `allow` rule only against the skill's own name and the name in Claude's invocation." (retrieved 2026-09-16)

### Finding Unused Skills: `/skill-doctor` `[official]` (added 2026-09-16)

Changelog v2.1.261 (2026-09-04): "Added `/skill-doctor` to show which loaded skills go unused and what they cost in context, so you can prune them".

> "Run `/skill-doctor` to see what each of your skills costs and how often it gets used, so you can decide which ones to turn off. In an interactive session, the report opens in the `/plugin` manager's **Stats** tab. In non-interactive mode with `-p`, Claude Code prints it as text."
> "The report covers the skills in your session other than bundled skills and enterprise skills. It flags skills in the listing that have never been invoked and says where to turn them off. Of the skills it tells you where to turn them off, start with the ones that have the highest context cost. The report also lists plugins you haven't used recently."
> "`/skill-doctor` requires Claude Code v2.1.252 or later and isn't available in sessions that skip feature-flag fetching. If you run `/skill-doctor` over Remote Control from your phone or browser, Claude Code replies `Skill usage reports are not available on this connection.`"
> — https://code.claude.com/docs/en/skills (retrieved 2026-09-16)

Version note: docs say v2.1.252+ (feature-flagged); the changelog announces it in v2.1.261. Reviewer implication: `/skill-doctor` is the official tool for the "monthly audit / prune untriggered skills" practice recorded in the community file; recommend it (or `/doctor`) when a skill portfolio is large. To keep a skill but stop auto-invocation, docs suggest `disable-model-invocation: true` or `"user-invocable-only"` in `skillOverrides`.

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

### Claude 5-Generation Skill Authoring `[official]` (added 2026-09-24)

> "Overall, we found that we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills."
> "Think of skills as lightweight guides to let Claude find information when needed. Avoid making them overconstrained, except in highly important areas."
> "It's best when skills encode particular opinions, knowledge, or best practices that are particular to you, your team, or product."
> "Instead of using examples, think more about the design of your tools, scripts and files- what parameters does Claude have and how can they be more expressive?"
> — Anthropic blog, Thariq Shihipar, 2026-07-24: https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/ (retrieved 2026-09-24)

> "Refactor existing prompts and skills. Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality. Review and consider removing older instructions if default performance is better."
> "Don't instruct Claude to reproduce its reasoning in the response. Prompts, skills, or harness instructions that tell the model to echo, transcribe, or explain its internal reasoning as response text can trigger the `reasoning_extraction` refusal category … Audit existing skills and system prompts for reflection or show-your-thinking instructions when migrating."
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 (retrieved 2026-09-24)

> "If your prompt contains explicit verification instructions ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), remove them: instructions like these cause over-verification on Claude Opus 5" and "Avoid instructing re-checks it already performs ('double-check your answer,' 're-verify before responding')"
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 (retrieved 2026-09-24). Opus 5.5 (default Opus since Claude Code v2.1.280): "Existing Claude Opus 5 prompts should perform well without changes" and also flags reasoning-in-response instructions (`reasoning_extraction`, new vs Opus 5).

Reconciling with existing official guidance: the platform best-practices "feedback loop" (run validator → fix → repeat) and "provide a checklist" remain valid — they are *concrete* checks. What the Claude 5 pages flag is *generic* self-verification prose ("double-check your work", "add a final verification step", "spawn a subagent to verify") with no runnable check behind it. The blog's "Instead of using examples" is about tool-usage examples vs expressive tool/script design; the platform "Examples pattern" (input/output pairs for quality-sensitive output formats) and Fable 5.1's "add one complete example of a correct response" for quoting remain official — no conflict for output-format examples.

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

**`skill-creator` is now an officially-distributed plugin `[official]` (updated 2026-06-26).** Install with `/plugin install skill-creator@claude-plugins-official`; if not found, refresh marketplaces with `/plugin marketplace update claude-plugins-official` or `/plugin marketplace add anthropics/claude-plugins-official`. Then `/reload-plugins`. The plugin produces these artifacts in the skill directory:
- `evals/evals.json` — test prompts, input files, expected behavior
- `grading.json` — pass/fail per assertion with evidence
- `benchmark.json` — pass rate, time, tokens for with-skill vs without-skill
- HTML report viewer for qualitative review
- Blind A/B between two skill versions ("confirm an edit is an improvement before committing it")
- Description tuning measures should-trigger / should-not-trigger hit rate and proposes edits

> — https://code.claude.com/docs/en/skills (retrieved 2026-06-26)
> Implication: when reviewing skills, check for `evals/evals.json` as a positive signal of evaluation-driven authoring.

**Baseline comparison rule `[official]` (clarified 2026-06-26):**
> "A fresh session matters because leftover context from authoring the skill will mask gaps in the written instructions."
> — https://code.claude.com/docs/en/skills (retrieved 2026-06-26)

Run the same prompt in a fresh session with the skill available and again with it disabled (via `skillOverrides: "off"` or `Skill(name)` deny); compare results.

**Measure triggering and output separately; `claude plugin eval` `[official]` (added 2026-09-16):**
> "Seeing a skill trigger tells you Claude found it, not that it did what you intended. To know a skill is working, measure separately whether Claude invokes it on the prompts it should, and whether the output matches what you expect when it does."
> "Two tools automate that comparison. For a skill that ships in a plugin, `claude plugin eval` runs each prompt in an isolated session with and without the plugin, scores it with graders you define or that it writes for you, and exits non-zero below a threshold so you can gate CI on it. For iterating on a single skill inside a Claude Code conversation, the skill-creator plugin below runs a similar loop with its own `evals/evals.json` format. The two formats aren't interchangeable."
> — https://code.claude.com/docs/en/skills (retrieved 2026-09-16); changelog v2.1.269 (2026-09-11): "Added `claude plugin eval`: run a plugin's eval suite against Claude Code and get scored, reproducible results (JSON + HTML report)".

The docs now point to agentskills.io for the eval file format: https://agentskills.io/skill-creation/evaluating-skills (retrieved 2026-09-16). Key facts from that page: `evals/evals.json` = `{ "skill_name", "evals": [ { "id", "prompt", "expected_output", "files", "assertions" } ] }`; "Start with 2-3 test cases. Don't over-invest before you've seen your first round of results"; "Cover edge cases. Include at least one prompt that tests a boundary condition"; run each case "once with the skill and once without it (or with a previous version)"; results in `grading.json` / `timing.json` / `benchmark.json` per `iteration-N/`. Iteration guidance that is authoring-relevant: "Keep the skill lean. Fewer, better instructions often outperform exhaustive rules… If pass rates plateau despite adding more rules, the skill may be over-constrained"; "**Explain the why.** Reasoning-based instructions ('Do X because Y tends to cause Z') work better than rigid directives ('ALWAYS do X, NEVER do Y')"; "Bundle repeated work" into `scripts/` when every run writes the same helper. Conflict note: platform best-practices says "Build three scenarios"; agentskills.io says start with 2-3 — treat "≥3" as the target, 2 as acceptable for a first iteration.

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
- Budget scales at 1% of context window; least-invoked skills' descriptions are dropped first when it overflows (names always kept)
- Front-load key use case (1,536-char per-entry cap in listing; configurable via `skillListingMaxDescChars`)
- Raise budget with `skillListingBudgetFraction` setting or `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var; run `/doctor` to diagnose overflow; set low-priority entries to `"name-only"` in `skillOverrides`

**Malformed YAML frontmatter `[official]` (added 2026-06-26):** "If the frontmatter YAML is malformed, Claude Code loads the skill body with empty metadata, so `/skill-name` still works but Claude has no `description` to match against. Run with `--debug` to see the parse error." — https://code.claude.com/docs/en/skills (retrieved 2026-06-26). Implication for reviewers: a skill whose `/name` works manually but never auto-triggers may have invalid YAML — check the description field exists.

**`claude plugin validate` on skills directories `[official]` (added 2026-09-04, v2.1.233+):** "To find SKILL.md files whose frontmatter doesn't parse, run `claude plugin validate` on the skills directory, for example `claude plugin validate .claude/skills` for project skills or `claude plugin validate ~/.claude/skills` for personal skills." **Freshness note (2026-09-16):** this sentence was not surfaced on the skills page in the 2026-09-16 extraction; plugins-reference (retrieved 2026-09-16) documents the same command for a plugin's `agents/` directory ("A plugin without a manifest: `claude plugin validate ./my-plugin/agents`. Requires Claude Code v2.1.233 or later"), notes it "reports unrecognized fields as warnings, not errors", and adds `--strict` to "treat warnings as errors" for CI. Keep recommending the command; re-verify the skills-directory form next run.

**Frontmatter must open the file `[official]` (added 2026-09-04, re-verified 2026-09-16):** "Claude Code reads the frontmatter only when the opening `---` is the file's first line. Otherwise it treats the whole file, `---` markers included, as skill content." Also v2.1.243 fixed `.md` files starting with a UTF-8 BOM being **silently ignored** — on older versions a BOM makes the whole skill disappear (BOM/malformed-YAML/`--debug` text no longer surfaced on the skills page as of 2026-09-16; retained from changelog v2.1.186 / v2.1.243).

**Frontmatter key-case tolerance `[official]` (added 2026-06-26, changelog v2.1.186, 2026-06-22):** SKILL.md frontmatter now accepts kebab-case, snake_case, and camelCase keys equivalently (e.g. `when_to_use`, `whenToUse`, `when-to-use` all work). Keeps loading even when the SKILL.md YAML is otherwise malformed — loads with empty metadata.

**`/reload-skills` command `[official]` (added 2026-06-26, late-June 2026):** force-reload skill definitions in the current session without restarting Claude Code (useful when editing nested skills below the start directory, since those load on demand). Still present as of v2.1.271 (2026-09-14): "Fixed `/reload-skills` reporting a skill count that disagreed with the slash menu after `/cd`". Related invocation fixes: the Skill tool's "Unknown skill" error now names a plugin skill's full name when a bare name matches exactly one plugin skill (v2.1.269); slash commands typed mid-prompt find a plugin skill by its bare name (v2.1.265); `--plugin-dir` may point at a folder of plugins, each child with a manifest loading and hot-added/removed (v2.1.265).

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
- 2026-05-30: Minor refresh against code.claude.com/docs/en/skills + platform.claude.com best-practices. Added new 2026 frontmatter fields `arguments` and `disallowed-tools`. Added new substitutions `$name` and `${CLAUDE_EFFORT}`. Updated description-budget behavior: least-invoked descriptions dropped first on overflow; new settings `skillListingBudgetFraction`, `maxSkillDescriptionChars`; `/doctor` diagnostics; `skillOverrides` (on/name-only/user-invocable-only/off). Clarified file references are Read-tool instructions, not `@` imports. `disable-model-invocation` also blocks subagent preload. No conflicts with prior content; core rules (1024/1,536 caps, 500-line, one-level-deep, TOC>100 lines, third-person, pushy, gerund, degrees-of-freedom) unchanged.
- 2026-04-17: Major refresh against latest docs. Corrected description limits: hard cap is 1024 chars (field), truncation is 1,536 chars (combined `description` + `when_to_use` in listings) — previous 250-char figure was outdated. Added new frontmatter field `when_to_use`. Added `xhigh` effort level. Added skill content lifecycle section (session-wide persistence, compaction budgets: 5k tokens per skill, 25k combined). Added third-person rule, "pushy" description guidance, gerund naming, one-level-deep references rule, 100-line TOC rule, evaluation-driven development, degrees-of-freedom framing, workflows/feedback-loops, content guidelines, anti-patterns (official), per-model testing, explicit checklist. Added sources: platform.claude.com best-practices, skill-creator repo.
- 2026-06-10: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-10). Added: bundled skills (`/run`, `/verify`, `/run-skill-generator` v2.1.145+, `disableBundledSkills`); compaction detail that the 25k budget fills from the most recently invoked skill so **oldest skills can be dropped entirely**; "keep the body concise — recurring token cost" quote; `context: fork` correction — CLAUDE.md is loaded **except** when the agent is Explore or Plan; `model` field is turn-scoped (not saved to settings); `Skill(name)` / `Skill(name *)` permission-rule syntax. Core scoring facts re-verified unchanged: 1,536-char combined cap (`maxSkillDescriptionChars` configurable), 1% listing budget (`skillListingBudgetFraction` / `SLASH_COMMAND_TOOL_CHAR_BUDGET`, `/doctor` diagnostics), 500-line SKILL.md guidance, all 2026 frontmatter fields (`when_to_use`, `arguments`, `disallowed-tools`, `effort`, `paths`, `shell`, `hooks`), `skillOverrides` states, live change detection, `disable-model-invocation` removing description from context and blocking subagent preload.
- 2026-06-26: Refresh against code.claude.com/docs/en/skills (retrieved 2026-06-26) and changelog v2.1.181–v2.1.193. **Material additions**: (1) **Project/personal/plugin skills override bundled skills with the same name** — e.g. a `code-review` skill in `.claude/skills/` replaces the bundled `/code-review`. (2) **Plugin-skill folders**: adding `.claude-plugin/plugin.json` to a skill folder turns it into a plugin (`<name>@skills-dir`) that can bundle agents, hooks, MCP servers; trust-gated for project skills. (3) **Live change detection scope clarified**: covers SKILL.md text only; plugin extras (hooks/, .mcp.json, agents/, output-styles/) need `/reload-plugins`. (4) **Malformed YAML behavior**: invalid frontmatter still loads the skill body with empty metadata; use `--debug` to see parse errors (changelog v2.1.186, 2026-06-22). (5) **Frontmatter key-case tolerance**: kebab/snake/camelCase keys all accepted (v2.1.186). (6) **`/reload-skills` command** to force-reload definitions without restarting. (7) **`skill-creator` is now an officially-distributed plugin** at `anthropics/claude-plugins-official` — produces `evals/evals.json`, `grading.json`, `benchmark.json`, plus HTML report viewer and blind A/B version comparison. (8) **Baseline comparison rule**: fresh session matters because authoring-session context masks gaps. Core scoring facts unchanged. last_updated bumped to 2026-06-26.
- 2026-07-25: Refreshed against code.claude.com/docs/en/skills (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **Material additions**: (1) **Command-name resolution table** - in a personal or project skill the frontmatter `name` sets only the display label and the command comes from the **directory name**; `name` forms the command's last segment only for plugin skills and plugin-root SKILL.md (fallback: the plugin directory name). Nested `.claude/skills/` that clash get a path-prefixed command (`/apps/web:deploy`). Before v2.1.216 a plugin skill's `name` replaced the whole command, dropping the plugin prefix. (2) **Description cap restated as 1,536 characters** for the combined `description` + `when_to_use` text in the skill listing; the previously-recorded 1024-char hard cap is no longer stated. (3) **Boolean tolerance** - `yes`/`no`/`on`/`off`/`1`/`0` in any case (v2.1.218). (4) **`background` frontmatter field** for `context: fork` skills (v2.1.218): default `true` runs the fork in the background with the **narrower background-subagent tool set**; `background: false` waits in the invoking turn and keeps the full tool set. (5) **Skill stacking** (v2.1.199): the first skill plus up to five more, trailing text passed as `$ARGUMENTS` to each; expansion stops at the first token that is not an inline user-invocable skill, including a forked skill such as `/code-review` (forked from v2.1.218) or `/loop`. (6) **`/verify` and `/code-review` are user-invoke-only** (v2.1.215) and therefore cannot be preloaded into subagents. (7) **`disable-model-invocation: true` also blocks scheduled-task firing** (v2.1.196). (8) Full substitution list re-verified: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}` (ultracode reports as `xhigh`), `${CLAUDE_SKILL_DIR}`. (9) `paths` frontmatter scopes **automatic** activation only, using the path-specific-rules glob format. Frontmatter table otherwise re-verified in full. last_updated bumped to 2026-07-25.
- 2026-09-04: Refreshed against code.claude.com/docs/en/skills and platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (both retrieved 2026-09-04) + changelog v2.1.229-v2.1.260. **Material additions**: (1) **Three new substitutions** — `${CLAUDE_PROJECT_DIR}` (v2.1.196+), and plugin-skill-only `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}`; substitution of `${CLAUDE_SKILL_DIR}` / `${CLAUDE_PROJECT_DIR}` (and plugin vars) also runs in `allowed-tools` Bash rules, enabling the "bundled script without permission prompt" pattern. Argument escaping rules (`\$1.00`; argument values containing `$1`/`$ARGUMENTS` inserted literally). (2) **`allowed-tools` is turn-scoped** — the grant clears on the next user message even though content persists — **and not gated by workspace trust**: a repo-committed skill's `allowed-tools` applies even in untrusted `-p` runs, so broad grants are a security finding. (3) **Injected-command failure semantics** — a failed `` !`command` `` aborts the entire invocation (Claude never sees the content); non-zero exit fails except the exit-1 search/comparison carveout; `|| true` advised for checks; injected commands never prompt — an ask **or** deny rule aborts regardless of `allowed-tools`; inline `!` recognized only at line start/after whitespace; output not re-scanned; cwd follows the session shell; 2-min timeout; `shell: bash` without Git Bash fails outright. (4) **Synced-skills rules** — `synced` is a reserved folder name in any capitalization; a synced skill is skipped when its name matches any other command (case/spacing/fullwidth-insensitive); synced bodies lose `!` execution and `@`/`${CLAUDE_*}` substitution in regular local sessions; Cowork/cloud sessions don't read `~/.claude/skills/`. (5) **Bundled-skill override does not cover aliases** (`/review` still runs bundled `code-review`); v2.1.248 fixed alias-keyed `skillOverrides` and `Skill(name)` deny for nested `<dir>:name`; `/doctor` is a bundled skill (v2.1.205, alias `checkup`) exempt from `disableBundledSkills`. (6) **Re-invocation dedup** — identical rendered content re-invoked adds an "already loaded" note instead of a second copy. (7) **Diagnostics** — `claude plugin validate <skills-dir>` (v2.1.233+) finds unparseable frontmatter; frontmatter only parsed when `---` is the file's first line; UTF-8 BOM silently hid skills before v2.1.243. (8) **Setting-name correction** — the 1,536 listing cap is configured by `skillListingMaxDescChars`, not the previously-recorded `maxSkillDescriptionChars`. (9) Symlinked skill directories officially supported (deduped); `/cd` loads the new directory's project skills (v2.1.246); plugin `name` carrying its own `<plugin>:` prefix no longer doubles (v2.1.246+, doubled v2.1.216-245); frontmatter `model:` on skills was **ignored in interactive sessions until fixed in v2.1.248**; `disallowed-tools` can't remove `EndConversation`. Platform best-practices page re-verified unchanged (1,024-char field cap still stated there, 500-line body, gerund naming, one-level-deep, TOC>100, eval-driven development). last_updated bumped to 2026-09-04.
- 2026-09-16: Refreshed against code.claude.com/docs/en/skills, code.claude.com/docs/en/hooks (Hooks in skills and agents), settings-reference, plugins-reference, platform best-practices, agentskills.io/specification, agentskills.io/skill-creation/evaluating-skills (all retrieved 2026-09-16) + changelog v2.1.261-v2.1.273 (newest v2.1.273, 2026-09-15; v2.1.262/v2.1.264 absent). **Material additions/corrections**: (1) **`/skill-doctor`** (changelog v2.1.261; docs: requires v2.1.252+, feature-flag-gated, not over Remote Control; report excludes bundled/enterprise skills, flags never-invoked skills with context cost, opens in `/plugin` Stats tab or prints in `-p`) — new section. (2) **Frontmatter `hooks` corrected**: not lifecycle-scoped — registered on invoke and kept "for the rest of the session"; `once: true` removes after first successful run; project-skill frontmatter hooks are **not workspace-trust-gated** (run in untrusted `-p`), same gap as `allowed-tools` — security finding for repo-committed skills. (3) **Synced-skill collision corrected (v2.1.269)**: synced skills are `/anthropic-skills:<name>`; on a short-name clash the synced skill is no longer skipped, it runs only under the full name. (4) **`skillOverrides` / `Skill()` alias semantics**: alias-keyed entries apply only in managed settings or `--settings` files, restrict-only, own-name entry wins; user/project/local settings match names only; `Skill(alias)` / `Skill(unqualified)` deny rules block through alias/qualified names; allow rules match own name only; docs date both fixes to **v2.1.260** (2026-09-04 entry said v2.1.248 — docs win). (5) **Injected commands in auto mode** don't abort on an ask-rule match (skill loads with a run-first instruction; v2.1.271 makes them follow default-mode rules rather than the classifier), but still abort in forked skills with `agent` and in sessions without a shell tool; deny still aborts everywhere; error strings recorded. (6) **Eval guidance**: measure triggering vs output separately; `claude plugin eval` (v2.1.269) for plugin skills with CI gating; official pointer to agentskills.io eval format (`evals/evals.json` with `skill_name`/`evals[]{id,prompt,expected_output,files,assertions}`, "start with 2-3 test cases"); agentskills.io states "Reasoning-based instructions … work better than rigid directives ('ALWAYS do X, NEVER do Y')" and "if pass rates plateau … the skill may be over-constrained". (7) **Agent Skills spec `name` constraints** recorded (no leading/trailing/consecutive hyphens, **must match parent directory name**) — a local no-op in Claude Code but a spec violation on export paths. (8) Smaller: `background` forced-foreground cases (`-p`/SDK, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, same skill already running, scheduled task) and background-fork edits bypassing `/rewind`; `.claude/commands/*.md` accepts all frontmatter except `name`/`paths`; nested skills load lazily on first file access or `/add-dir <subdir>` (v2.1.257+); live detection off in bare mode; cloud sessions load repo `.claude/skills/` and repo-declared plugins, Desktop scheduled tasks do load `~/.claude/skills/`; `model` also ignored when auto/plan-mode classifier doesn't support it; `effort:` frontmatter ignored on pinned-effort models until v2.1.267; `description` fallback wording is "first non-empty line"; `/doctor` now reports unused skills and migrates CLAUDE.md guidance into skills; `/workflow-authoring` is a feature-gated bundled skill. (9) **Doc drift flagged, nothing retracted**: `claude plugin validate <skills-dir>`, malformed-YAML/`--debug`, kebab/camel key tolerance, `/reload-skills`, and the listing-budget setting names were not surfaced on the skills page in this extraction; settings-reference still documents `skillListingMaxDescChars` / `skillListingBudgetFraction` (linking to `#skill-descriptions-are-cut-short`), plugins-reference documents `claude plugin validate` for `agents/` (+ `--strict`), and v2.1.271 references `/reload-skills`. Platform best-practices page and agentskills.io spec re-verified unchanged (1,024-char `description` cap still stated on both; 500-line body; gerund naming; one-level-deep; TOC>100; ≥3 evals; Haiku/Sonnet/Opus). last_updated bumped to 2026-09-16.
- 2026-08-12: Refreshed against code.claude.com/docs/en/skills and platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (both retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. **Material additions**: (1) New **Portability** section - the Agent Skills spec permits only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` for claude.ai uploads / the Skills API / `package_skill.py`, and an out-of-spec key is a **hard error**, not an ignored field. Claude Code-only fields are correct in Claude Code-only skills and must not be deducted; flag only when the skill targets those export paths. (2) Frontmatter table completed with `background` (v2.1.218), `metadata` (must be a map; non-map values dropped; don't reuse field names like `paths` as keys), `license`, and `compatibility` (max 500 characters). (3) **`model` + `availableModels`**: an org-excluded value is not used and the session keeps its current model; with `context: fork` it sets the fork's model and follows subagent-override rules. (4) Platform best-practices page re-verified unchanged: 64-char/lowercase-hyphen `name` with reserved words `anthropic`/`claude` barred, 1,024-char `description` cap at the field level, third-person voice, gerund naming, 500-line body target, one-level-deep references, 100-line TOC rule, degrees-of-freedom framing, evaluation-driven development (3+ evals, test on Haiku/Sonnet/Opus), and the full authoring checklist. (5) Changelog notes: skills synced from claude.ai no longer shadow local commands or MCP prompts (v2.1.228); plugin/org skills named after terminal built-ins are invocable again (v2.1.221); plugins accept `.` as a `skills` path (v2.1.221); refusal message improved when Claude invokes a `disable-model-invocation` skill (v2.1.222); `/review` is now an alias of `/code-review` (v2.1.223). Description caps (1,536 combined listing / 1,024 field), listing budget, command-name resolution, substitutions, stacking, and lifecycle all re-verified unchanged. last_updated bumped to 2026-08-12.
- 2026-09-24: Refreshed against code.claude.com/docs/en/skills (retrieved 2026-09-24; no sentence cites a version above v2.1.273), the per-model prompting pages (Fable 5, Opus 5, Opus 5.5), the Anthropic "new rules of context engineering for Claude 5" blog, and changelog v2.1.274–v2.1.281 (newest v2.1.281, 2026-09-23). **Material additions**: (1) **New section "Claude 5-Generation Skill Authoring"** — official quotes: skills are "lightweight guides … Avoid making them overconstrained, except in highly important areas"; best when they "encode particular opinions, knowledge, or best practices that are particular to you, your team, or product"; "Skills developed for prior models are often too prescriptive"; don't instruct reasoning reproduction (`reasoning_extraction` refusals on Fable 5/5.1 and Opus 5.5); remove generic verification/double-check instructions (Opus 5). Reconciled with the existing feedback-loop and examples guidance (concrete checks and output-format examples stay valid). (2) **Synced skills — terminal sync** (docs v2.1.273, changelog v2.1.275): signed-in terminal sessions download claude.ai skills to `~/.claude/skills/synced/` and re-check every ~10 minutes; `syncClaudeAiSkills: false` opts out and trashes existing copies; v2.1.281 short-name display, v2.1.280 `.trash` manifest.json bug fix, and v2.1.275 "not saved to your account" notice for edits in the synced folder. last_updated bumped to 2026-09-24.

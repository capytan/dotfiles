# Modularization Guide

last_updated: 2026-11-19

> Referenced in Phase 4 when proposing CLAUDE.md splits.

---

## Contents

- When to Consider Splitting
- Method 1: .claude/rules/*.md (Auto-Loaded)
- Method 2: @path/to/file.md (Explicit Reference)
- Detailed References
- Method 3: Subdirectory CLAUDE.md (Scoped Context)
- Method 4: CLAUDE.local.md (Personal Settings)
- Method 5: Skills (SKILL.md) for On-Demand Knowledge
- Method 5b: agent_docs/ with file:line pointers
- Method 6: Hooks for Deterministic Enforcement
- Splitting Procedure

## When to Consider Splitting

- CLAUDE.md exceeds 200 lines (official target: "under 200 lines per CLAUDE.md file")
- A single section is over 30 lines
- Frequently-changing sections mixed with stable ones
- Monorepo with multiple packages
- Team-shared info mixed with personal settings
- Task-specific instructions that don't need to load every session (move to skills)
- Hard enforcement rules that must always execute (move to hooks)

---

## Method 1: `.claude/rules/*.md` (Auto-Loaded)

Files in `.claude/rules/` are loaded automatically.
No reference needed in CLAUDE.md.

**Best for:**
- Rules that should always apply (code style, PR conventions, etc.)
- Self-contained topics
- Team-wide shared rules

**Naming example:**
```
.claude/rules/
├── code-style.md
├── testing.md
├── pr-conventions.md
└── security.md
```

**Path-specific rules** (new in 2026):
Rules can be scoped using YAML frontmatter with the `paths` field:
```yaml
---
paths:
  - "src/api/**/*.ts"
---
```
These rules only load when Claude reads files matching the pattern.

**Caveats:**
- Too many files increases token consumption (keep each file concise too)
- Load order is not guaranteed — avoid inter-file dependencies
- Supports symlinks for sharing rules across projects
- User-level rules in `~/.claude/rules/` apply to every project
- To exclude a symlinked rules file via `claudeMdExcludes`, a pattern matching **either** the `.claude/rules/` path or the link target works (v2.1.239–v2.1.243; previously only the link target matched)
- Cowork desktop sessions skip a symlinked `~/.claude/rules/` directory or rule file pointing outside the session's working directory (retrieved 2026-09-04)
- **Symlinks whose target is outside the working directory are external imports (official, retrieved 2026-09-16)**: "The linked rules don't load until you approve external imports for the project, and after that only the ones without a `paths` field load. Claude Code asks for that approval only when a project memory file imports a file outside the working directory with `@path`, not for symlinks alone. To load shared rules without that approval, keep them in `~/.claude/rules/`." So a project-level symlink to a rules repo elsewhere on disk (a) silently never loads unless some CLAUDE.md in the project also `@path`-imports an outside file, and (b) never loads its path-scoped rules at all. Use `~/.claude/rules/` for personal sharing or a plugin for team sharing; a symlink to a target *inside* the working directory is unaffected
  - **Correction (official, retrieved 2026-10-28; changelog v2.1.284 fixed outside-symlinked rules "being skipped without ever showing" the dialog)**: symlinks alone now trigger the approval — "Claude Code asks for that approval once per project, in a dialog at the start of an interactive session. The dialog lists the linked rule files alongside any external `@path` imports." Point (a) above no longer holds on v2.1.284+; point (b) (path-scoped linked rules never load) still holds. Symlinks to network paths (UNC, `/net`, `/Network`) never load
- **Rule frontmatter (official, retrieved 2026-10-28)**: "`paths` is the only field Claude Code reads from a rule; any other field is ignored without an error." Cursor-style `globs:` / `description:` / `alwaysApply:` do nothing — a rule with only `globs:` loads unconditionally. If the YAML doesn't parse, the rule loads "as if it had no `paths`". Verify with `claude --debug`
- **Per-file size limit for on-demand rules (official, v2.1.309)**: a path-scoped rule (project or `~/.claude/rules/`) or a rule in a subdirectory's `.claude/rules/` over 40,000 characters (200K window) / 150,000 characters (1M window, post-4.6 models) loads only its start. When splitting, keep each on-demand rules file under 40,000 characters (`wc -m`); each file counts separately
- **User vs project rules don't override each other (official, retrieved 2026-10-28)**: "if a user rule and a project rule conflict, Claude may follow either one, so keep the two consistent." Don't rely on a project rule to "override" a `~/.claude/rules/` rule
- **Sibling worktrees (official, retrieved 2026-11-19)**: "To have path-scoped rules load for files in a sibling git worktree, start Claude Code in that worktree or move the session there with `/cd`." A session in worktree A editing files in worktree B doesn't fire A's or B's `paths:` rules
- **Literal `[` in a pattern (official, retrieved 2026-11-19)**: "escape it inside single quotes, as in `'photos \[2024/**'`" — an unparseable bracket expression makes only that pattern match nothing
- **Compaction**: unscoped rules are re-injected from disk after `/compact`; rules with `paths:` are summarized away and only reload when a matching file is read again. Official rule: "If a rule must persist across compaction, drop the `paths:` frontmatter or move it to the project-root CLAUDE.md." (https://code.claude.com/docs/en/context-window, retrieved 2026-09-16)
- **Verify user-level path-scoped rules**: a closed GitHub issue (#21858) reported `paths:` rules in `~/.claude/rules/` never loading while the same file under `./.claude/rules/` did; no fix version is stated. Confirm with the `InstructionsLoaded` hook before relying on them. (2026-10-28: the memory page now documents user-level path-scoped rules explicitly — their patterns are relative to "the session's primary working directory" — so a user-level `paths:` rule written relative to `~` or a repo root other than the cwd won't match)
- **Choose between per-directory CLAUDE.md and a path-scoped rule (official table, retrieved 2026-09-16)**: per-directory `CLAUDE.md` when "Directory owners maintain their own conventions; instructions are versioned with the code"; path-scoped rule when "You want all conventions in one place, or the same rule applies to many scattered paths" (https://code.claude.com/docs/en/large-codebases)

## Method 2: `@path/to/file.md` (Explicit Reference)

Use `@` prefix in CLAUDE.md to reference a file.
Referenced content is expanded and loaded into context at launch (not on demand).

**Best for:**
- Organizing related instructions into separate files for human maintainability
- Pulling in existing files (README, package.json, AGENTS.md) so content lives in one place
- Cases where you want an explicit link from CLAUDE.md

> **AGENTS.md update (official, retrieved 2026-09-24):** since v2.1.277 Claude Code reads AGENTS.md natively when no `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` exists on the path, so a repo whose instructions are fully shared across tools may need **no CLAUDE.md at all**. Keep `@AGENTS.md` + Claude-specific lines below it when you need Claude-only content, when a `CLAUDE.local.md` would otherwise suppress AGENTS.md, or on Bedrock/Vertex/Foundry. "Keeping the import never makes Claude read `AGENTS.md` twice." A *prose* pointer ("read AGENTS.md") is not a substitute for the import — "Claude sees `AGENTS.md` only if it decides to open the file." — https://code.claude.com/docs/en/memory#agents-md

> **Important (official, retrieved 2026-05-30):** Imports do **not** reduce context — imported files load in full at launch. "Splitting into @path imports helps organization but does not reduce context, since imported files load at launch." For actual context savings, prefer path-scoped `.claude/rules/` (Method 1) or skills (Method 5). Do not use `@path` for large reference material you only need during specific tasks.

**Example:**
```markdown
## Detailed References

@docs/claude/architecture.md
@docs/claude/api-conventions.md
```

**Caveats:**
- The `@path` line must remain in CLAUDE.md (not auto-discovered)
- Relative paths resolve relative to the file containing the import, not the working directory
- Maximum depth of **four hops** for recursive imports (official docs, retrieved 2026-05-30; previously documented as "five")
- First-time external imports require an approval dialog; declining disables imports permanently and the dialog does not reappear
- Both relative and absolute paths are allowed

## Method 3: Subdirectory CLAUDE.md (Scoped Context)

Place a CLAUDE.md in each directory.
Auto-loaded when Claude operates on files in that directory.

**Best for:**
- Monorepo packages
- Independent feature domains
- Different tech stacks (frontend/ vs backend/)

**Example:**
```
monorepo/
├── CLAUDE.md              # Shared build steps, overall structure
├── packages/
│   ├── api/
│   │   └── CLAUDE.md      # API-specific rules
│   ├── web/
│   │   └── CLAUDE.md      # Frontend-specific rules
│   └── shared/
│       └── CLAUDE.md      # Shared library rules
```

**Caveats:**
- Don't copy parent CLAUDE.md content into children (parent is auto-loaded too)
- Children should contain only package-specific information
- Starting Claude from a subdirectory loads "That directory's plus every ancestor's" CLAUDE.md; starting from the root loads "Root only; subdirectory files load on demand when Claude reads there". Confirm with `/context` under **Memory files** (https://code.claude.com/docs/en/large-codebases, retrieved 2026-09-16)
- `.claude/settings.json` is *not* inherited from parent directories the way CLAUDE.md is — each subdirectory you start from needs its own self-contained settings file
- A sibling package granted via the `permissions.additionalDirectories` setting never loads its CLAUDE.md, rules, or skills; only `--add-dir` / `/add-dir` plus `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` does
- Nested CLAUDE.md files are summarized away on compaction and reload only when Claude reads a file in that directory again (same as path-scoped rules)
- **Per-file size limit (official, v2.1.309, retrieved 2026-10-28)**: a subdirectory CLAUDE.md / CLAUDE.local.md (and its `@` imports) over 40,000 characters (200K window) / 150,000 characters (1M window on post-4.6 models) loads only its start, ending with a note to Read the rest — "until Claude chooses to, the later instructions aren't in its context". Split oversized ones into rules files, which "each count against the limit on their own"
- To test a new subdirectory CLAUDE.md, "create it from your shell rather than asking Claude to write it, then ask Claude to read a file in that subdirectory" — a `Loaded` line appears in the terminal

## Method 4: `CLAUDE.local.md` (Personal Settings) `[official]`

Separate settings that shouldn't be shared with the team.

**Best for:**
- Personal editor settings and workflows
- Local-environment-specific paths (homebrew install locations, etc.)
- Experimental configurations

**Must be added to `.gitignore`.** With `CLAUDE_CODE_NEW_INIT=1` set, running `/init` and choosing the personal option does this for you (official wording, retrieved 2026-09-16); without the flag, add the entry by hand.

**Caveats (official, 2026-04-17):**
- Loads alongside `CLAUDE.md` and is appended *after* it at each directory level, so personal notes override the shared file when they conflict
- In multi-worktree workflows, a gitignored `CLAUDE.local.md` exists only in the worktree where you created it. To share across worktrees, import from your home directory: `@~/.claude/my-project-instructions.md`

---

## Method 5: Skills (`SKILL.md`) for On-Demand Knowledge `[official]`

Move domain-specific workflows and task-specific instructions to skills.
Skills only load when invoked or when Claude determines they're relevant.

**Best for:**
- Domain knowledge needed only for specific tasks
- Repeatable workflows (e.g., `/fix-issue`, `/deploy`)
- Complex instructions that would bloat CLAUDE.md
- Knowledge that only ~100 tokens of metadata scanning justifies loading

**Example:**
```
.claude/skills/
├── api-conventions/
│   └── SKILL.md
├── deployment/
│   └── SKILL.md
└── code-review/
    └── SKILL.md
```

**Caveats:**
- Skills require Claude to recognize relevance or explicit invocation
- Not suitable for rules that must apply to every session universally
- After `/compact`, invoked skill bodies are re-injected "capped at 5,000 tokens per skill and 25,000 tokens total; oldest dropped first", and "Truncation keeps the start of the file, so put the most important instructions near the top of `SKILL.md`" (https://code.claude.com/docs/en/context-window, retrieved 2026-09-16)

## Method 5b: `agent_docs/` with file:line pointers `[community:high]`

HumanLayer's progressive-disclosure pattern (Nov 2025):

```
agent_docs/
├── building_the_project.md
├── running_tests.md
└── code_conventions.md
```

From CLAUDE.md, reference these files as needed with `file:line` pointers to authoritative code instead of inlining snippets that will drift.

**Best for:**
- Supplementary documentation that would otherwise bloat CLAUDE.md
- Topics where authoritative code exists (point there rather than copying)
- Team knowledge that doesn't belong in every session context

**Caveats:**
- Not auto-loaded — Claude reads on demand when it follows pointers, like any regular file
- Prefer `.claude/rules/` with `paths:` frontmatter when the content should load automatically for specific file patterns

> Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md (retrieved 2026-04-17)

## Method 6: Hooks for Deterministic Enforcement `[official]` `[semi-official]`

Move absolute rules to hooks instead of relying on CLAUDE.md compliance.

**Best for:**
- Formatting (PostToolUse hook running Prettier/Black/etc.)
- Security restrictions (PreToolUse blocking dangerous commands)
- Linting after edits
- Branch protection rules

**Example:**
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": "prettier --write $CLAUDE_FILE_PATHS" }]
    }]
  }
}
```

**Caveats:**
- Hooks are configured in `.claude/settings.json`, not CLAUDE.md
- Keep CLAUDE.md guidance as documentation alongside the hook for context

---

## Splitting Procedure

1. Classify each section of the current CLAUDE.md:
   - **Always needed** → keep in CLAUDE.md or move to `.claude/rules/`
   - **Always needed + file-type-specific** → `.claude/rules/` with `paths:` frontmatter
   - **Task-specific only** → `@` reference to a separate file or move to a skill
   - **On-demand domain knowledge** → skill (SKILL.md)
   - **Package-specific** → subdirectory CLAUDE.md
   - **Personal settings** → `CLAUDE.local.md` (spelling corrected 2026-09-16; was the incorrect `.claude.local.md`)
   - **Must execute 100% of the time** → hook in `.claude/settings.json`
   - **Must survive `/compact` unchanged** → project-root CLAUDE.md or an *unscoped* rule (path-scoped rules and nested CLAUDE.md are summarized away)
   - **Shared with other coding agents (Codex, Cursor, Copilot…)** → `AGENTS.md` (read natively since v2.1.277 when no CLAUDE.md exists; otherwise `@AGENTS.md` from CLAUDE.md) (added 2026-09-24)
   - **Several unique verification instructions** → a verification skill referenced from CLAUDE.md — official blog: "if you have several unique instructions on how to verify your work, create a verification skill and reference it from your CLAUDE.md" (claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models, retrieved 2026-09-24)
   - **Only compensates for an older model's behavior** → delete (see Stale Information → model-era workarounds in the anti-pattern catalog), don't relocate

2. Target under 100 lines for the post-split CLAUDE.md (official: under 200; Boris's reference: ~100). Remember every non-Explore/Plan subagent re-loads the full hierarchy into its own context, so the always-on portion is paid once per subagent as well (sub-agents doc, retrieved 2026-09-16; a subagent that needs none of it can set `omitClaudeMd: true`, v2.1.271+)

3. Verify each split file is self-contained (no prerequisite knowledge from other files)

4. Use `claudeMdExcludes` in monorepos to skip irrelevant CLAUDE.md files from other teams

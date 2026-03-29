# Modularization Guide

> Referenced in Phase 4 when proposing CLAUDE.md splits.

---

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

## Method 2: `@path/to/file.md` (Explicit Reference)

Use `@` prefix in CLAUDE.md to reference a file.
Referenced content is expanded and loaded into context at launch (not on demand).

**Best for:**
- Supplemental info needed only during specific tasks
- Large reference material (API specs, design docs, etc.)
- Cases where you want an explicit link from CLAUDE.md

**Example:**
```markdown
## Detailed References

@docs/claude/architecture.md
@docs/claude/api-conventions.md
```

**Caveats:**
- The `@path` line must remain in CLAUDE.md (not auto-discovered)
- Relative paths resolve relative to the file containing the import, not the working directory
- Maximum depth of five hops for recursive imports
- First-time external imports require an approval dialog
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

## Method 4: `.claude.local.md` (Personal Settings)

Separate settings that shouldn't be shared with the team.

**Best for:**
- Personal editor settings and workflows
- Local-environment-specific paths (homebrew install locations, etc.)
- Experimental configurations

**Must be added to `.gitignore`.**

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
   - **Personal settings** → `.claude.local.md`
   - **Must execute 100% of the time** → hook in `.claude/settings.json`

2. Target under 100 lines for the post-split CLAUDE.md (official: under 200; Boris's reference: ~100)

3. Verify each split file is self-contained (no prerequisite knowledge from other files)

4. Use `claudeMdExcludes` in monorepos to skip irrelevant CLAUDE.md files from other teams

---

## Changelog

- 2025-05-01: Initial version
- 2026-03-29: Added path-specific rules (YAML frontmatter), updated @path import details (depth limit, resolution rules, approval dialog), added Method 5 (Skills) and Method 6 (Hooks) for modularization, expanded splitting procedure with skills/hooks/claudeMdExcludes options, added symlink support for rules.

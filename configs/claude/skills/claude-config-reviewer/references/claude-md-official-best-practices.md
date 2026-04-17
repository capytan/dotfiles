# Official Best Practices for CLAUDE.md

> This file is auto-updated in Phase 0 (Research).
> Manual edits are fine but may be overwritten on next research run.
> Items tagged `[custom]` are protected from overwrite.

last_updated: 2026-04-17
sources:
  - https://code.claude.com/docs/en/memory
  - https://code.claude.com/docs/en/best-practices
  - https://code.claude.com/docs/en/settings
  - https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices
  - https://www.anthropic.com/research/long-running-Claude

---

## Summary from Official Documentation

### What CLAUDE.md Is `[official]`

> "CLAUDE.md files are markdown files that give Claude persistent instructions for a project, your personal workflow, or your entire organization. You write these files in plain text; Claude reads them at the start of every session."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

> "Each Claude Code session begins with a fresh context window. Two mechanisms carry knowledge across sessions: CLAUDE.md files (instructions you write to give Claude persistent context) and Auto memory (notes Claude writes itself based on your corrections and preferences)."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

> "Claude treats them as context, not enforced configuration. The more specific and concise your instructions, the more consistently Claude follows them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Loaded into the context window at the start of every session, consuming tokens alongside conversation
- CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt itself

### Two Memory Systems `[official]`

| Aspect | CLAUDE.md files | Auto memory |
|--------|----------------|-------------|
| Who writes it | You | Claude |
| What it contains | Instructions and rules | Learnings and patterns |
| Scope | Project, user, or org | Per working tree |
| Loaded into | Every session | Every session (first 200 lines or 25KB) |
| Use for | Coding standards, workflows, project architecture | Build commands, debugging insights, preferences Claude discovers |

> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Auto memory stored in `~/.claude/projects/<project>/memory/` with `MEMORY.md` as index
- "The first 200 lines of MEMORY.md, or the first 25KB, whichever comes first, are loaded at the start of every conversation."
- All worktrees and subdirectories within the same git repository share one auto memory directory
- Subagents can also maintain their own auto memory

### File Locations and Hierarchy `[official]`

| Scope | Location | Purpose | Shared with |
|-------|----------|---------|-------------|
| Managed policy | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux/WSL: `/etc/claude-code/CLAUDE.md`; Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | All users in organization |
| Project instructions | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared instructions for the project | Team members via source control |
| User instructions | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Just you (all projects) |
| Local instructions | `./CLAUDE.local.md` | Personal project-specific preferences; add to `.gitignore` | Just you (current project) |

> — https://code.claude.com/docs/en/memory (retrieved 2026-04-17)

- "CLAUDE.md and CLAUDE.local.md files in the directory hierarchy above the working directory are loaded in full at launch. Files in subdirectories load on demand when Claude reads files in those directories."
- "Within each directory, `CLAUDE.local.md` is appended after `CLAUDE.md`, so when instructions conflict, your personal notes are the last thing Claude reads at that level."
- "All discovered files are concatenated into context rather than overriding each other."
- "Managed policy CLAUDE.md files cannot be excluded."
- **New in 2026-04**: Set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to also load `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and `CLAUDE.local.md` from directories added with `--add-dir`.

### When to Add to CLAUDE.md `[official]`

> "Treat CLAUDE.md as the place you write down what you'd otherwise re-explain. Add to it when:
> - Claude makes the same mistake a second time
> - A code review catches something Claude should have known about this codebase
> - You type the same correction or clarification into chat that you typed last session
> - A new teammate would need the same context to be productive
>
> Keep it to facts Claude should hold in every session: build commands, conventions, project layout, 'always do X' rules. If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a skill or a path-scoped rule instead."
> — https://code.claude.com/docs/en/memory (retrieved 2026-04-17)

### Writing Effective Instructions `[official]`

Quoted directly from https://code.claude.com/docs/en/memory (retrieved 2026-03-29):

1. **Size**: "Target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence. If your instructions are growing large, split them using imports or .claude/rules/ files."

2. **Structure**: "Use markdown headers and bullets to group related instructions. Claude scans structure the same way readers do: organized sections are easier to follow than dense paragraphs."

3. **Specificity**: "Write instructions that are concrete enough to verify."
   - "Use 2-space indentation" instead of "Format code properly"
   - "Run `npm test` before committing" instead of "Test your changes"
   - "API handlers live in `src/api/handlers/`" instead of "Keep files organized"

4. **Consistency**: "If two rules contradict each other, Claude may pick one arbitrarily. Review your CLAUDE.md files, nested CLAUDE.md files in subdirectories, and .claude/rules/ periodically to remove outdated or conflicting instructions."

### Recommended Content (Include / Exclude) `[official]`

From https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29):

| Include | Exclude |
|---------|---------|
| Bash commands Claude can't guess | Anything Claude can figure out by reading code |
| Code style rules that differ from defaults | Standard language conventions Claude already knows |
| Testing instructions and preferred test runners | Detailed API documentation (link to docs instead) |
| Repository etiquette (branch naming, PR conventions) | Information that changes frequently |
| Architectural decisions specific to your project | Long explanations or tutorials |
| Developer environment quirks (required env vars) | File-by-file descriptions of the codebase |
| Common gotchas or non-obvious behaviors | Self-evident practices like "write clean code" |

### Pruning Guidance `[official]`

> "Keep it concise. For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it. Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

> "If Claude keeps doing something you don't want despite having a rule against it, the file is probably too long and the rule is getting lost."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

> "If Claude asks you questions that are answered in CLAUDE.md, the phrasing might be ambiguous. Treat CLAUDE.md like code: review it when things go wrong, prune it regularly, and test changes by observing whether Claude's behavior actually shifts."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

### Emphasis for Adherence `[official]`

> "You can tune instructions by adding emphasis (e.g., 'IMPORTANT' or 'YOU MUST') to improve adherence."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

> "Check CLAUDE.md into git so your team can contribute. The file compounds in value over time."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

### `/init` Command `[official]`

> "Run `/init` to generate a starting CLAUDE.md automatically. Claude analyzes your codebase and creates a file with build commands, test instructions, and project conventions it discovers. If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting it."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- `CLAUDE_CODE_NEW_INIT=true` enables an interactive multi-phase flow: asks which artifacts to set up (CLAUDE.md files, skills, hooks), explores with a subagent, fills gaps via follow-up questions, presents a reviewable proposal before writing

### Import Syntax (`@path`) `[official]`

> "CLAUDE.md files can import additional files using @path/to/import syntax. Imported files are expanded and loaded into context at launch alongside the CLAUDE.md that references them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Both relative and absolute paths are allowed
- Relative paths resolve relative to the file containing the import, not the working directory
- Maximum depth of five hops for recursive imports
- Personal preferences can import from home directory: `@~/.claude/my-project-instructions.md`
- First-time external imports require an approval dialog

### AGENTS.md Compatibility `[official]`

> "Claude Code reads CLAUDE.md, not AGENTS.md. If your repository already uses AGENTS.md for other coding agents, create a CLAUDE.md that imports it so both tools read the same instructions without duplicating them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

### Modularization with `.claude/rules/` `[official]`

> "For larger projects, you can organize instructions into multiple files using the .claude/rules/ directory. This keeps instructions modular and easier for teams to maintain. Rules can also be scoped to specific file paths, so they only load into context when Claude works with matching files, reducing noise and saving context space."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- All `.md` files are discovered recursively; organize with subdirectories (`frontend/`, `backend/`)
- Rules without `paths` frontmatter loaded at launch with same priority as `.claude/CLAUDE.md`
- `.claude/rules/` supports symlinks for sharing rules across projects
- User-level rules in `~/.claude/rules/` apply to every project (loaded before project rules)

### Path-Specific Rules `[official]`

```yaml
---
paths:
  - "src/api/**/*.ts"
---
```

- Supports glob patterns: `**/*.ts`, `src/**/*`, `*.md`, `src/components/*.tsx`
- Multiple patterns and brace expansion: `"src/**/*.{ts,tsx}"`
- "Path-scoped rules trigger when Claude reads files matching the pattern, not on every tool use."

> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

### `claudeMdExcludes` Setting `[official]`

> "In large monorepos, ancestor CLAUDE.md files may contain instructions that aren't relevant to your work. The claudeMdExcludes setting lets you skip specific files by path or glob pattern."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Configured in `.claude/settings.local.json`
- Patterns matched against absolute file paths using glob syntax
- Can be configured at any settings layer; arrays merge across layers
- Managed policy CLAUDE.md files cannot be excluded

### HTML Comments `[official]`

> "Block-level HTML comments in CLAUDE.md files are stripped before the content is injected into Claude's context. Use them to leave notes for human maintainers without spending context tokens on them. Comments inside code blocks are preserved."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- When opened with Read tool, comments remain visible

### CLAUDE.md vs Hooks `[official]`

> "Unlike CLAUDE.md instructions which are advisory, hooks are deterministic and guarantee the action happens."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

> "Settings rules are enforced by the client regardless of what Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- CLAUDE.md = behavioral guidance (advisory)
- Hooks = deterministic enforcement (100% execution)
- Use hooks for formatting, linting, security checks that must happen every time

### CLAUDE.md vs Skills `[official]`

> "CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead. Claude loads them on demand without bloating every conversation."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

> "Rules load into context every session or when matching files are opened. For task-specific instructions that don't need to be in context all the time, use skills instead, which only load when you invoke them or when Claude determines they're relevant to your prompt."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

### Anti-Pattern: Over-Specified CLAUDE.md `[official]`

> "The over-specified CLAUDE.md. If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise. Fix: Ruthlessly prune. If Claude already does something correctly without the instruction, delete it or convert it to a hook."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

### Compaction Behavior `[official]`

> "Project-root CLAUDE.md survives compaction: after `/compact`, Claude re-reads it from disk and re-injects it into the session. Nested CLAUDE.md files in subdirectories are not re-injected automatically; they reload the next time Claude reads a file in that subdirectory."
> — https://code.claude.com/docs/en/memory (retrieved 2026-04-17)

- "If an instruction disappeared after compaction, it was either given only in conversation or lives in a nested CLAUDE.md that hasn't reloaded yet."
- Can customize: add "When compacting, always preserve the full list of modified files and any test commands" to CLAUDE.md

### Managed CLAUDE.md vs Managed Settings `[official]`

> "A managed CLAUDE.md and managed settings serve different purposes. Use settings for technical enforcement and CLAUDE.md for behavioral guidance"
> — https://code.claude.com/docs/en/memory (retrieved 2026-04-17)

| Concern | Configure in |
|---------|-------------|
| Block specific tools, commands, or file paths | Managed settings: `permissions.deny` |
| Enforce sandbox isolation | Managed settings: `sandbox.enabled` |
| Environment variables and API provider routing | Managed settings: `env` |
| Authentication method and organization lock | Managed settings: `forceLoginMethod`, `forceLoginOrgUUID` |
| Code style and quality guidelines | Managed CLAUDE.md |
| Data handling and compliance reminders | Managed CLAUDE.md |
| Behavioral instructions for Claude | Managed CLAUDE.md |

### Auto Memory Settings `[official]`

- Requires Claude Code v2.1.59 or later
- Enabled by default; toggle via `/memory` or `autoMemoryEnabled: false` in project settings
- Disable via env var: `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`
- `autoMemoryDirectory` (user/local/policy settings only, not project) redirects storage location
- Not accepted from `.claude/settings.json` — prevents shared projects from redirecting writes to sensitive locations
- Storage derives `<project>` path from git repo root; all worktrees share one directory

> — https://code.claude.com/docs/en/memory (retrieved 2026-04-17)

### Self-Editing CLAUDE.md in Long-Running Sessions `[official]`

> "Claude treats this file specially, keeping it in context and referencing it for the overall plan... Claude can edit these instructions as it works, updating them for future work as it works through issues."
> — https://www.anthropic.com/research/long-running-Claude (retrieved 2026-04-17)

For autonomous/long-running Claude sessions:
- Spend most setup time "crafting a set of instructions that clearly articulates the project's deliverables and relevant context"
- Iterate the plan locally before deploying
- Let Claude refine its own strategic approach by editing CLAUDE.md as it encounters issues
- Pair with a separate `CHANGELOG.md` (or similar) for progress tracking to avoid CLAUDE.md bloat

### Troubleshooting `[official]`

> "CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt itself."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Run `/memory` to verify CLAUDE.md files are being loaded
- Use `InstructionsLoaded` hook to log which instruction files load and when
- For system-prompt-level instructions: `--append-system-prompt` flag (better for scripts/automation)
- Check for conflicting instructions across files

### Claude 4 Prompting Practices `[official]`

> "Be explicit with instructions: Claude 4 models respond well to clear, explicit instructions."
> — https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices (retrieved 2026-03-29)

> "Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude 4 better understand your goals and deliver more targeted responses."
> — same source (retrieved 2026-03-29)

---

## Changelog

- 2025-05-01: Initial version (based on Claude Code v2.x official docs)
- 2026-03-29: Major update — rewrote from official docs at code.claude.com/docs/en/memory and code.claude.com/docs/en/best-practices. Added: two memory systems table, managed policy locations (macOS/Linux/Windows), writing effective instructions (size/structure/specificity/consistency), include/exclude table, pruning guidance with direct quotes, emphasis for adherence, /init with CLAUDE_CODE_NEW_INIT, @path import details (depth limit, approval dialog, relative resolution), AGENTS.md compatibility, path-specific rules with YAML frontmatter and glob patterns, claudeMdExcludes setting, HTML comments stripping, CLAUDE.md vs hooks distinction, CLAUDE.md vs skills distinction, over-specified anti-pattern, compaction behavior and survival, troubleshooting section (InstructionsLoaded hook, /memory, --append-system-prompt), Claude 4 prompting practices (explicit instructions, motivation/context).
- 2026-04-17: Re-read official docs. Added: `CLAUDE.local.md` as fourth scope in file-locations table (with concatenation/append-after ordering), new "When to Add to CLAUDE.md" official heuristic (4 triggers), `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` env var for `--add-dir` directories, Managed CLAUDE.md vs Managed Settings decision table, Auto Memory settings (`autoMemoryEnabled`, `autoMemoryDirectory`, v2.1.59+ requirement, `CLAUDE_CODE_DISABLE_AUTO_MEMORY`), Self-Editing CLAUDE.md guidance from long-running Claude research blog. Updated compaction behavior to clarify only project-root CLAUDE.md is re-injected after `/compact`; nested files reload lazily.

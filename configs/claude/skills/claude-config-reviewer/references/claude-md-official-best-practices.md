# Official Best Practices for CLAUDE.md

> This file is auto-updated in Phase 0 (Research).
> Manual edits are fine but may be overwritten on next research run.
> Items tagged `[custom]` are protected from overwrite.

last_updated: 2026-09-24
sources:
  - https://code.claude.com/docs/en/memory#agents-md
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
  - https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/ (claude.com/blog/… 301-redirects here)
  - https://code.claude.com/docs/en/memory
  - https://code.claude.com/docs/en/best-practices
  - https://code.claude.com/docs/en/context-window
  - https://code.claude.com/docs/en/large-codebases
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/settings
  - https://code.claude.com/docs/en/changelog
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (formerly docs.anthropic.com/.../claude-4-best-practices, which now 301-redirects here)
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
  - https://www.anthropic.com/research/long-running-Claude

---

## Contents

Summary from Official Documentation:
- What CLAUDE.md Is
- Two Memory Systems
- File Locations and Hierarchy
- When to Add to CLAUDE.md
- Writing Effective Instructions
- Recommended Content (Include / Exclude)
- Pruning Guidance
- Emphasis for Adherence
- /init Command
- Import Syntax (@path)
- AGENTS.md Compatibility
- Modularization with .claude/rules/
- Path-Specific Rules
- claudeMdExcludes Setting
- HTML Comments
- CLAUDE.md vs Hooks
- CLAUDE.md vs Skills
- Anti-Pattern: Over-Specified CLAUDE.md
- Compaction Behavior
- claudeMd Key in Managed Settings
- Managed CLAUDE.md vs Managed Settings
- Auto Memory Settings
- Subagents and CLAUDE.md
- Self-Editing CLAUDE.md in Long-Running Sessions
- Troubleshooting
- Claude 5 Prompting Practices

## Summary from Official Documentation

### What CLAUDE.md Is `[official]`

> "CLAUDE.md files are markdown files that give Claude persistent instructions for a project, your personal workflow, or your entire organization. You write these files in plain text; Claude reads them at the start of every session."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

> "Each Claude Code session begins with a fresh context window. Two mechanisms carry knowledge across sessions: CLAUDE.md files (instructions you write to give Claude persistent context) and Auto memory (notes Claude writes itself based on your corrections and preferences)."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

> "Claude treats them as context, not enforced configuration. The more specific and concise your instructions, the more consistently Claude follows them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

**Updated wording (retrieved 2026-09-16)** — the memory page now inserts the hook pointer directly into that sentence:

> "Both are loaded at the start of every conversation. Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead. The more specific and concise your instructions, the more consistently Claude follows them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-09-16)

- Loaded into the context window at the start of every session, consuming tokens alongside conversation
- CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt itself

### Two Memory Systems `[official]`

| Aspect | CLAUDE.md files | Auto memory |
|--------|----------------|-------------|
| Who writes it | You | Claude |
| What it contains | Instructions and rules | Learnings and patterns |
| Scope | Project, user, or org | Per repository, shared across worktrees |
| Loaded into | Every session | Every session (first 200 lines or 25KB) |
| Use for | Coding standards, workflows, project architecture | Your preferences, corrections you give Claude, project context Claude can't derive from the code |

> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29; "Use for" column re-worded as above per retrieval 2026-09-16 — previously "Build commands, debugging insights, preferences Claude discovers")

- Auto memory stored in `~/.claude/projects/<project>/memory/` with `MEMORY.md` as index
- "The first 200 lines of MEMORY.md, or the first 25KB, whichever comes first, are loaded at the start of every conversation."
- All worktrees and subdirectories within the same git repository share one auto memory directory
- Subagents can also maintain their own auto memory
- **Subagents do not receive the main session's auto memory (retrieved 2026-09-16)**: "The main conversation's auto memory isn't loaded into subagents; the exception is a fork, which inherits the parent conversation and system prompt. A subagent's own auto memory, enabled with the subagent `memory` field, is a separate directory." — https://code.claude.com/docs/en/memory

### File Locations and Hierarchy `[official]`

| Scope | Location | Purpose | Use case examples | Shared with |
|-------|----------|---------|-------------------|-------------|
| Managed policy | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`; Linux/WSL: `/etc/claude-code/CLAUDE.md`; Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | Company coding standards, security policies, compliance requirements | All users in organization |
| User instructions | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Code styling preferences, personal tooling shortcuts | Just you (all projects) |
| Project instructions | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared instructions for the project | Project architecture, coding standards, common workflows | Team members via source control |
| Local instructions | `./CLAUDE.local.md` | Personal project-specific preferences; add to `.gitignore` | Your sandbox URLs, preferred test data | Just you (current project) |

> — https://code.claude.com/docs/en/memory (retrieved 2026-09-16)

- **Row order corrected 2026-09-16 (User now before Project)**: "The table below lists them in load order, from broadest scope to most specific, so a project instruction appears in context after a user instruction." Earlier versions of this file listed Project above User; since later-read content wins on conflict, a project CLAUDE.md rule overrides a conflicting `~/.claude/CLAUDE.md` rule, not the reverse. — https://code.claude.com/docs/en/memory (retrieved 2026-09-16)
- "CLAUDE.md and CLAUDE.local.md files in the directory hierarchy above the working directory are loaded in full at launch. Files in subdirectories load on demand when Claude reads files in those directories."
- **Starting directory determines what loads (retrieved 2026-09-16)**: starting from the repository root loads "Root only; subdirectory files load on demand when Claude reads there"; starting from a subdirectory loads "That directory's plus every ancestor's". Also: "Project settings in `.claude/settings.json` aren't inherited from parent directories the way CLAUDE.md files are." — https://code.claude.com/docs/en/large-codebases
- **`additionalDirectories` vs `--add-dir` (retrieved 2026-09-16)**: a directory listed in the `permissions.additionalDirectories` setting *never* loads its CLAUDE.md, rules, or skills; a directory added with `--add-dir` / `/add-dir` loads skills, and loads CLAUDE.md + rules only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`. "The environment variable has no effect on directories listed in the `additionalDirectories` setting." — https://code.claude.com/docs/en/large-codebases
- "Within each directory, `CLAUDE.local.md` is appended after `CLAUDE.md`, so when instructions conflict, your personal notes are the last thing Claude reads at that level."
- "All discovered files are concatenated into context rather than overriding each other."
- "Managed policy CLAUDE.md files cannot be excluded."
- **New in 2026-04**: Set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to also load `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and `CLAUDE.local.md` from directories added with `--add-dir`.
- **New in 2026-06 (changelog v2.1.169, 2026-06-08)**: the `/cd` command moves a session to a new working directory *without* breaking the prompt cache mid-session. The new directory's CLAUDE.md is **appended as a message** rather than rebuilt into the system prompt, and the session relocates to the new directory's project storage (so `--resume`/`--continue` find it). You are prompted to trust the directory if you haven't worked in it before. (A follow-up fix, v2.1.172, corrected `/cd` and worktree moves leaving the session reporting the previous directory's git branch.)

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
   - **Updated wording (retrieved 2026-05-30)**: official guidance now steers toward path-scoped rules *first*, and explicitly warns imports do not reduce context: "If your instructions are growing large, use path-scoped rules so instructions load only when Claude works with matching files. You can also split content into imports for organization, though imported files still load and enter the context window at launch." — https://code.claude.com/docs/en/memory
   - Troubleshooting echoes this: "Splitting into @path imports helps organization but does not reduce context, since imported files load at launch."
   - **New in 2026-06 (changelog v2.1.169, 2026-06-08)**: the in-product "CLAUDE.md is too long" warning threshold now **scales with the model's context window** — the 200-line *target* is unchanged, but the surfaced warning is no longer a fixed line count. Treat under-200 as the authoring target regardless; the dynamic warning only governs when Claude Code nags about it.
   - **Hard limit (retrieved 2026-09-04)**: "Claude Code loads a CLAUDE.md file of up to 4 MiB in full and skips a larger file. Shorter files produce better adherence." — a CLAUDE.md over 4 MiB is skipped *entirely*, not truncated. — https://code.claude.com/docs/en/memory
   - **v2.1.281 (2026-09-23)**: "Improved the large CLAUDE.md startup notice to also count instruction files together, so many mid-sized files and @-imports are caught" — the notice now reflects aggregate instruction load, consistent with the docs' "imported files still load and enter the context window at launch". — https://code.claude.com/docs/en/changelog (retrieved 2026-09-24)
   - **Illustrative startup cost (new official page, retrieved 2026-09-16)**: the interactive context-window walkthrough puts representative numbers on what loads before the first prompt — system prompt ~4,200 tokens, `~/.claude/CLAUDE.md` ~320, project `CLAUDE.md` ~1,800, `MEMORY.md` ~680, skill descriptions ~450, environment info ~280, deferred MCP tool names ~120 — and labels the project file "The most important file you can create", with the tip: "Keep it under 200 lines. Move reference content to skills or path-scoped rules so it only loads when needed." Numbers are explicitly "illustrative"; the page also shows a subagent paying for its own copy of the project CLAUDE.md (~1,800 again) — https://code.claude.com/docs/en/context-window

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

**Updated wording (retrieved 2026-09-04)** — the page now explicitly warns against diluting emphasis:

> "If Claude keeps skipping one instruction, add emphasis such as 'IMPORTANT' to that line alone. If you emphasize many lines, none of them stands out."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-09-04)

> "Check CLAUDE.md into git so your team can contribute. The file compounds in value over time."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

### `/init` Command `[official]`

> "Run `/init` to generate a starting CLAUDE.md automatically. Claude analyzes your codebase and creates a file with build commands, test instructions, and project conventions it discovers. If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting it."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- `CLAUDE_CODE_NEW_INIT=1` enables an interactive multi-phase flow (docs now show `=1`; `=true` previously documented): asks which artifacts to set up (CLAUDE.md files, skills, hooks), explores with a subagent, fills gaps via follow-up questions, presents a reviewable proposal before writing
- **`.gitignore` for `CLAUDE.local.md` is only automated under the new flow (retrieved 2026-09-16)**: "With `CLAUDE_CODE_NEW_INIT=1` set, running `/init` and choosing the personal option does this for you." Without the flag, add the entry yourself. — https://code.claude.com/docs/en/memory

### Import Syntax (`@path`) `[official]`

> "CLAUDE.md files can import additional files using @path/to/import syntax. Imported files are expanded and loaded into context at launch alongside the CLAUDE.md that references them."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- Both relative and absolute paths are allowed
- Relative paths resolve relative to the file containing the import, not the working directory
- Maximum depth of **four hops** for recursive imports (changed from "five hops" — retrieved 2026-05-30: "Imported files can recursively import other files, with a maximum depth of four hops.")
- Personal preferences can import from home directory: `@~/.claude/my-project-instructions.md`
- First-time external imports require an approval dialog (declining disables imports permanently and the dialog does not reappear)
- **Trust distinction for user-scope files (retrieved 2026-09-04)**: the approval dialog applies to *project-level* memory files. "User-scope memory files, such as `~/.claude/CLAUDE.md` and `~/.claude/rules/`, are files you wrote yourself. Except in Cowork sessions on your desktop, Claude Code loads their imports without the dialog and trusts them like the rest of your personal configuration." In Cowork desktop sessions, imports in user-scope files resolving outside the session's working directory are skipped, as are a symlinked `~/.claude/CLAUDE.md` and symlinked `~/.claude/rules/` entries pointing outside the working directory. — https://code.claude.com/docs/en/memory
- Imports do not reduce context — imported files load in full at launch (use path-scoped rules to actually save context)
- **Import parsing skips fenced code blocks and code spans (added 2026-06-26 from memory docs):** "Import parsing skips Markdown code spans and fenced code blocks. To mention a path in your CLAUDE.md without importing it, wrap it in backticks: writing `` `@README` `` keeps the text literal, while `@README` outside backticks imports the file." — https://code.claude.com/docs/en/memory (retrieved 2026-06-26)

### AGENTS.md Compatibility `[official]`

> ~~"Claude Code reads CLAUDE.md, not AGENTS.md. If your repository already uses AGENTS.md for other coding agents, create a CLAUDE.md that imports it so both tools read the same instructions without duplicating them."~~
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29) — **SUPERSEDED 2026-09-24**, see native support below

**Native AGENTS.md reading (v2.1.277, 2026-09-18; retrieved 2026-09-24)** — changelog: "Added AGENTS.md support: in a project with no CLAUDE.md, Claude Code reads AGENTS.md instead; change it under "Project instructions" in `/config` (not yet on Bedrock, Vertex or Foundry)". Memory page:

> "Claude Code can read `AGENTS.md` as your project instructions, so a repository already set up for other coding agents works without adding a `CLAUDE.md`, an import, or a setting."
> "By default, Claude reads `AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it." — what counts: "a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory above it"; what doesn't: "your `~/.claude/CLAUDE.md`, your organization's managed `CLAUDE.md`, and `.claude/rules/` files"
> "Because `CLAUDE.local.md` counts, adding one to keep your own uncommitted instructions in a project that relies on `AGENTS.md` stops Claude from reading `AGENTS.md` for you."
> — https://code.claude.com/docs/en/memory#agents-md (retrieved 2026-09-24)

- **Project instructions** values (`/config`, or `pluginConfigs["agents-md@builtin"].options.instructionFiles` in user/`--settings`/managed settings — ignored in project and local settings): `claude-md-or-agents-md` (default), `claude-md-and-agents-md` ("each directory's `CLAUDE.md` files first and its `AGENTS.md` after them. Claude Code skips an `AGENTS.md` it has already loaded"), `claude-md`, `managed-only`
- Loading: every `AGENTS.md` / `.claude/AGENTS.md` from cwd upward at start; a subdirectory's `AGENTS.md` on Read when that subdirectory has no CLAUDE.md files; `@path` imports and `claudeMdExcludes` apply; subagents that skip project instructions skip these too
- Differences vs CLAUDE.md: `InstructionsLoaded` hooks "Don't fire" for a natively-read AGENTS.md; `--add-dir` + `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` doesn't load AGENTS.md
- Unavailable when the built-in `agents-md` plugin is disabled, in some first sessions after upgrading from ≤v2.1.276, and (before v2.1.281) on Bedrock / telemetry-disabled sessions — keep `@AGENTS.md` import there. Before v2.1.280, `/memory`/`/context` didn't list a natively read AGENTS.md
- **"Remove an earlier AGENTS.md workaround"** (official list): `@AGENTS.md` import — "you can leave it. Keeping the import never makes Claude read `AGENTS.md` twice"; "A `CLAUDE.md` that tells Claude in words to read `AGENTS.md`: Claude sees `AGENTS.md` only if it decides to open the file. Delete the `CLAUDE.md` … or replace the sentence with an `@AGENTS.md` import."; symlink — "nothing, or delete the symlink"; "A `SessionStart` hook that prints `AGENTS.md`: remove it … the hook adds a second copy to the context."
- Symlink editing caveat (new): "the Edit and Write tools refuse to write through a symlink, and the refusal directs Claude to edit the link's target, `AGENTS.md`, instead"

- A symlink (`ln -s AGENTS.md CLAUDE.md`) also works when no Claude-specific content is needed; on Windows use the `@AGENTS.md` import instead (symlinks need Administrator/Developer Mode)
- **Updated 2026-09-04 — `/init` tool-config reading list restructured**: "`/init` reads Cursor rules, in `.cursor/rules/` or `.cursorrules`, and Copilot rules, in `.github/copilot-instructions.md`, and incorporates the relevant parts into the generated `CLAUDE.md`. With `CLAUDE_CODE_NEW_INIT=1` set, `/init` also reads `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/` or `.windsurfrules`, and `.clinerules`." (Cursor + Copilot are now default; AGENTS.md/Devin/Windsurf/Cline require the new-init flow.) — https://code.claude.com/docs/en/memory
- **New: `/import` command (v2.1.213+, retrieved 2026-09-04)**: "You can also run `/import` to bring a supported coding agent's configuration into Claude Code, which appends a one-time copy of instruction files such as `AGENTS.md` to the matching `CLAUDE.md` and carries over MCP servers, commands, subagents, and skills." One-time *copy* (drifts afterward), unlike the `@AGENTS.md` import which stays live. — https://code.claude.com/docs/en/memory

### Modularization with `.claude/rules/` `[official]`

> "For larger projects, you can organize instructions into multiple files using the .claude/rules/ directory. This keeps instructions modular and easier for teams to maintain. Rules can also be scoped to specific file paths, so they only load into context when Claude works with matching files, reducing noise and saving context space."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

- All `.md` files are discovered recursively; organize with subdirectories (`frontend/`, `backend/`)
- Rules without `paths` frontmatter loaded at launch with same priority as `.claude/CLAUDE.md`
- `.claude/rules/` supports symlinks for sharing rules across projects
- User-level rules in `~/.claude/rules/` apply to every project (loaded before project rules)
- **Symlinks pointing outside the working directory are external imports (new, retrieved 2026-09-16)**:

  > "Claude Code treats a symlink whose target is outside your working directory like an external import. The linked rules don't load until you approve external imports for the project, and after that only the ones without a `paths` field load. Claude Code asks for that approval only when a project memory file imports a file outside the working directory with `@path`, not for symlinks alone. To load shared rules without that approval, keep them in `~/.claude/rules/`, where they apply to every project on your machine."
  > — https://code.claude.com/docs/en/memory (retrieved 2026-09-16)

  Two consequences for symlink-based sharing: (1) a project whose only outside-the-tree reference is a symlink never triggers the approval dialog, so those linked rules silently never load; (2) even after approval, a linked rule *with* `paths:` frontmatter never loads. The official fix is `~/.claude/rules/` for personal sharing, or a plugin for team sharing (https://code.claude.com/docs/en/large-codebases, "Centralize conventions when layering stops scaling").
- **Per-directory CLAUDE.md vs path-scoped rule decision table (retrieved 2026-09-16)**: per-directory `CLAUDE.md` lives "Inside the directory, alongside its code", loads "At launch when started from that directory, or on demand when Claude reads a file there", and suits "Directory owners maintain their own conventions; instructions are versioned with the code". A path-scoped rule lives in the "Central `.claude/` at the repo root", loads "When Claude works with a file matching the rule's `paths:` glob", and suits "You want all conventions in one place, or the same rule applies to many scattered paths". — https://code.claude.com/docs/en/large-codebases

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
- **Symlinked rules exclusion (fix landed v2.1.239–v2.1.243, retrieved 2026-09-04)**: "To exclude a rules file you reach through a symlink, whether the file or its directory is the link, write the pattern against either path: the file's path under `.claude/rules/` or its link target. A pattern that matches either path excludes the file." Previously only a pattern matching the link *target* worked — relevant to symlink-based dotfiles setups. (Memory doc cites v2.1.239; changelog lists the symlinked-rules-file case under v2.1.243.)
- **Pattern recipes (retrieved 2026-09-16)**: "Patterns use glob syntax matched against absolute file paths, so start relative-style patterns with `**/` to match anywhere in the tree." Examples: `"**/packages/web/**"` (skips every CLAUDE.md and rules file under that package), `"**/packages/*/CLAUDE.md"` (every package's CLAUDE.md, keeping the root), `"**/packages/legacy-*/**"`, or an absolute path to one file. "The exclusion list is static, not a per-task switch" — to focus on a different package, start Claude from that directory instead. — https://code.claude.com/docs/en/large-codebases

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
- **Updated wording (retrieved 2026-09-04)**: rules with `paths:` frontmatter behave like nested CLAUDE.md — "Nested CLAUDE.md files in subdirectories and rules with `paths:` frontmatter reload as Claude reads files they apply to." A lost instruction may also be "a path-scoped rule that hasn't matched a file since" compaction.
- Can customize: add "When compacting, always preserve the full list of modified files and any test commands" to CLAUDE.md
- **"What survives compaction" table (new official page, retrieved 2026-09-16)**: "Project-root CLAUDE.md and unscoped rules" → "Re-injected from disk"; "Auto memory" → "Re-injected from disk"; the plan written in plan mode → "Re-injected from disk"; "Rules with `paths:` frontmatter" → "Claude Code reloads them as Claude reads files they match"; "Nested CLAUDE.md in subdirectories" → reloaded as Claude reads files there; "Files Claude read or edited" → "re-reads up to five, most recently modified first" (a file over 5,000 tokens comes back as a path reference only); "Invoked skill bodies" → "Re-injected, capped at 5,000 tokens per skill and 25,000 tokens total; oldest dropped first"; "Context that hooks added earlier" → "Summarized with the rest of the conversation". Authoring rule stated explicitly: "Path-scoped rules and nested CLAUDE.md files load into message history when their trigger file is read, so compaction summarizes them away with everything else. If a rule must persist across compaction, drop the `paths:` frontmatter or move it to the project-root CLAUDE.md." — https://code.claude.com/docs/en/context-window
- **v2.1.269 (2026-09-11)**: "Fixed the git status Claude is told after a compaction: it is now the current status, not the one from the start of the session." — https://code.claude.com/docs/en/changelog
- **v2.1.273 (2026-09-15)**: fixed the context meter and auto-compact "counting advisor-tool turns at roughly twice their real context size, which made auto-compact fire at about half the real window" — https://code.claude.com/docs/en/changelog

### `claudeMd` Key in Managed Settings `[official]`

> "The `claudeMd` key lets you put managed CLAUDE.md content directly inside `managed-settings.json` instead of deploying a separate file."
> — https://code.claude.com/docs/en/memory (retrieved 2026-05-30)

```json
{
  "claudeMd": "Always run `make lint` before committing.\nNever push directly to main."
}
```

- Same precedence as a managed CLAUDE.md file (loads before user and project CLAUDE.md)
- Honored only in managed/policy settings — setting `claudeMd` in user, project, or local settings has no effect
- **New in 2026-09 (changelog v2.1.260, 2026-09-03)**: a server-managed `claudeMd` no longer triggers the security approval dialog; hooks, shell-command, sandbox, and unsafe `env` settings still require approval

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
- `autoMemoryDirectory` redirects storage location. **Updated 2026-06-10:** now "read from any settings scope: user, project, local, policy, or `--settings`" — value must be an absolute path or start with `~/`. The earlier restriction (not accepted from `.claude/settings.json`) was replaced by a trust gate: "When set in a project's `.claude/settings.json` or `.claude/settings.local.json`, the value is honored only after you accept the workspace trust dialog for that folder, the same gate that governs hooks."
- Storage derives `<project>` path from git repo root; all worktrees share one directory; machine-local (not shared across machines/cloud)
- **Four memory types documented (retrieved 2026-09-04)**: Claude records a `type` field in each memory file's frontmatter — `user` (role/expertise/preferences), `feedback` (corrections and confirmed approaches), `project` (ongoing work Claude can't derive from code or git history), `reference` (external pointers). "Claude skips anything it can derive from the codebase, such as architecture, file paths, or debugging fixes. It also skips anything your CLAUDE.md files already say."
- **New: `CLAUDE_CODE_PROJECT_DIR_NAME` (v2.1.234+, retrieved 2026-09-04)**: set beside `CLAUDE_CONFIG_DIR` to force the `<project>` directory name under `<config dir>/projects/`, so projects launched with that config dir share one auto memory directory
- `MEMORY.md` acts as an index; topic files (`debugging.md` etc.) are not loaded at startup, read on demand
- **New in 2026-06 (changelog)**: v2.1.181 (2026-06-17) — the agent is now reminded to compact its `MEMORY.md` index when nearing the size limit, keeping the auto-loaded portion within the 200-line/25KB budget. v2.1.176 (2026-06-12) — fixed memory recall not finding mounted team memory stores (`CLAUDE_MEMORY_STORES`) in remote sessions (shared/team auto-memory mounts).
- **v2.1.273 (2026-09-15)**: "Fixed `permissions.blockReadsOutsideWorkingDirectories`: a memory directory chosen by a repository's settings is no longer loaded into the prompt, recalled, indexed, or used by memory extraction" — i.e. under that permission setting, an `autoMemoryDirectory` set in a repo's `.claude/settings*.json` is ignored entirely. — https://code.claude.com/docs/en/changelog
- "Claude doesn't save something every session. It decides what's worth remembering based on whether the information would be useful in a future conversation." (retrieved 2026-09-16)

> — https://code.claude.com/docs/en/memory + changelog (retrieved 2026-09-16)

### Subagents and CLAUDE.md `[official]`

> "A non-fork subagent's initial context contains: … **CLAUDE.md files**: every level of the CLAUDE.md hierarchy the main conversation loads, including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, and managed policy files. The built-in Explore and Plan agents skip this. A subagent whose definition sets `omitClaudeMd` loads only the managed policy files, or none at all when the definition comes from managed settings."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

- **`omitClaudeMd` frontmatter (v2.1.271, 2026-09-14)**: "Set to `true` to launch this subagent without the user, project, and local CLAUDE.md files; managed policy files still load, except for managed subagents. Use it for subagents that take everything they need from the delegation prompt. Ignored when the agent runs as the main session agent via `--agent` or the `agent` setting. Requires Claude Code v2.1.271 or later." Changelog wording: "Added `omitClaudeMd` to agent frontmatter and `--agents` JSON, letting custom and plugin subagents run without user, project and local CLAUDE.md files; managed policy files still load" — https://code.claude.com/docs/en/sub-agents, https://code.claude.com/docs/en/changelog
- Every CLAUDE.md line is therefore paid again in each non-Explore/Plan subagent's context (the context-window page illustrates ~1,800 tokens for the project file per subagent) — another reason to keep the file lean
- Subagents also get "Git status: a snapshot taken at the start of the parent session" and, with `memory:` set, "the first 200 lines or 25KB of `MEMORY.md` in the memory directory" of their own agent-memory folder — the main session's auto memory is not included

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

- **Updated 2026-09-04 — `/context` is now the load-verification command**: "Run `/context` and check the list under **Memory files** to verify your CLAUDE.md and CLAUDE.local.md files loaded. If a file is missing there, Claude can't see it. Use `/memory` to open and edit the files." (`/memory` lists file locations including not-yet-created ones; `/context` shows what actually loaded this session.)
- Use `InstructionsLoaded` hook to log which instruction files load and when
- For system-prompt-level instructions: `--append-system-prompt` flag (better for scripts/automation)
- Check for conflicting instructions across files
- **New in 2026-06 (changelog v2.1.169, 2026-06-08)**: `--safe-mode` flag (and `CLAUDE_CODE_SAFE_MODE` env var) starts Claude Code with **all customizations disabled** — CLAUDE.md, plugins, skills, hooks, and MCP servers — to isolate whether a problem comes from your config. Useful for confirming a misbehavior is caused by a CLAUDE.md instruction rather than the model itself.
- **New in 2026-06 (changelog v2.1.191, 2026-06-24)**: `/rewind` resumes the conversation from before `/clear` was run. Lets you recover a session (and the CLAUDE.md/instruction state in it) if you accidentally cleared it.
- **New in 2026-06 (changelog v2.1.181, 2026-06-17)**: CLAUDE.md Write/Edit now work on network drives and cloud-synced folders (previously failed silently in some sync clients).
- **v2.1.261 (2026-09-04)**: "Changed `/context` token counting to use a local estimate when the token-counting API is unavailable, instead of extra small-model requests" — `/context` numbers may be estimates offline. Same release added `/skill-doctor` (unused skills and their context cost). — https://code.claude.com/docs/en/changelog
- **v2.1.269 (2026-09-11)**: "Fixed the attribution reminder overriding a CLAUDE.md or memory rule against commit and pull request attribution; lines set by managed settings still apply" — a CLAUDE.md rule such as "no Co-Authored-By trailer" is now honored unless managed settings force attribution. — https://code.claude.com/docs/en/changelog
- **v2.1.281 (2026-09-23)**: "Added `"attribution": false` in `settings.json` to hide all commit and PR attribution; older CLI versions skip a settings file that holds it, so keep the object form in files shared across versions" — a deterministic alternative to a CLAUDE.md "no Co-Authored-By" rule; same release: "Fixed CLAUDE.md and rules files from an `--add-dir` directory inside the working directory being sent to the model twice in headless and SDK sessions". v2.1.277: "the first turn no longer waits on the per-directory CLAUDE.md lookup" (SDK/`-p`). — https://code.claude.com/docs/en/changelog (retrieved 2026-09-24)
- **Maintenance practices (new official page, retrieved 2026-09-16)** — https://code.claude.com/docs/en/large-codebases: "Review in pull requests: treat CLAUDE.md edits like any other documentation change so conventions track the code"; "Revisit after major model releases: instructions that worked around an older model's limitation may become overhead once a newer model handles the case on its own. For example, a rule that forces single-file refactors can be deleted once the limitation is gone"; "Add a Stop hook that proposes updates: a `Stop` hook receives the path to the session transcript when Claude finishes responding, so a script can review the session and propose CLAUDE.md updates while the gap it exposed is fresh". The best-practices page now also says: "Run `/context` to confirm Claude loaded the file." and "For a checked-in CLAUDE.md, run `/doctor` and Claude proposes cuts for content it can derive from the codebase." (retrieved 2026-09-16)

### Claude 5 Prompting Practices `[official]`

The former "Claude 4 best practices" page has been replaced by a model-family-wide "Prompting best practices" page (the old docs.anthropic.com URL 301-redirects to platform.claude.com). It is "the reference for prompt engineering with current Claude models, including Claude Fable 5.1, Claude Mythos 5.1, Claude Fable 5, Claude Mythos 5, Claude Opus 5, Claude Opus 4.8, Claude Opus 4.7, Claude Opus 4.6, Claude Sonnet 5, Claude Sonnet 4.6, and Claude Haiku 4.5." (retrieved 2026-09-16)

> "Claude responds well to clear, explicit instructions. Being specific about your desired output can help enhance results."
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (retrieved 2026-09-16; was "Claude 4 models respond well to…" on the old page, retrieved 2026-03-29)

> "Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude better understand your goals and deliver more targeted responses."
> — same source (retrieved 2026-09-16)

**Dial back emphasis on newer models** — official, and directly relevant to CLAUDE.md emphasis markers:

> "Claude Opus 4.5 and Claude Opus 4.6 are also more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language. Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'."
> — same source (retrieved 2026-09-16)

> "Tune anti-laziness prompting: If your prompts previously encouraged the model to be more thorough or use tools more aggressively, dial back that guidance. Claude 4.6 models are more proactive and may overtrigger on instructions that were needed for previous models."
> — same source, Migration considerations (retrieved 2026-09-16)

**Fable 5 / 5.1 specifics** — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 (retrieved 2026-09-16):

> "Instruction-following is improved enough that you can steer most behaviors with a brief instruction rather than enumerating each behavior by name."

> "Capability improvements at this level are also a good prompt to re-evaluate which instructions, tools, and guardrails are still needed."

> "Refactor existing prompts and skills. Skills developed for prior models are often too prescriptive for Claude Fable 5 and can degrade output quality. Review and consider removing older instructions if default performance is better."

> "Give the reason, not only the request. Claude Fable 5 tends to perform better when it understands the intent behind a request"

> "Construct a memory system … Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo or chat history already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong."

- The Fable 5.1 page adds that the model "already formats less than earlier models, so on that model a block like this [an anti-markdown instruction] can suppress structure the content needs" — formatting-suppression rules copied from older CLAUDE.md files may now over-correct. — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1 (retrieved 2026-09-16)
- Implication for CLAUDE.md review: enumerated behavior lists, blanket "IMPORTANT/MUST" markers, and workaround rules written for older models are now flagged by *official* guidance, not just community consensus (see the Emphasis Overuse and Stale Information entries in the anti-pattern catalog)

**Refresh 2026-09-24 — page scope and per-model pages** (all retrieved 2026-09-24). The prompting guide now lists "Claude Fable 5.1, Claude Mythos 5.1, Claude Fable 5, Claude Mythos 5, Claude Opus 5.5, Claude Opus 5, Claude Opus 4.8, …" and adds: "Where a technique names a specific model, treat it as measured on that model and re-check it against your own evals before applying it to another." Its worked example for giving reasons: less effective "NEVER use ellipses"; more effective "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them." — "Claude is smart enough to generalize from the explanation." Claude Code v2.1.280 (2026-09-22) made **Claude Opus 5.5** (`claude-opus-5-5`) the default Opus model.

*Opus 5.5* — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5:
> "Existing Claude Opus 5 prompts should perform well without changes, and the patterns in Prompting Claude Opus 5 remain a reasonable starting point."
> "if your system prompt contains instructions that tell Claude to think carefully before answering, consider removing them for Claude Opus 5.5. The model decides for itself how much to think, and effort is the main control. In Anthropic's testing in a chat product, removing such a line made replies start sooner, with no clear decline in the quality of the reply."
> "To get less thinking, lower the effort level first. Lowering effort reduces thinking, and with it cost and latency, more reliably than prompt instructions do."
> "If your prompts ask the model to write out its reasoning in the response, remove those instructions" (`reasoning_extraction` refusal category, new vs Opus 5)
> "Claude Opus 5.5 is responsive to instructions that name the specific kinds of early stop you want it to avoid … It also helps to name the stops you do want"

*Opus 5* — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5:
> "If your prompt contains explicit verification instructions ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality."
> "Avoid instructing re-checks it already performs ('double-check your answer,' 're-verify before responding'); like verification instructions, these compound with the model's own behavior and add cost without improving results."
> "If your review prompt says 'only report high-severity issues' or 'be conservative,' the model may follow that instruction literally and report less; ask it to report everything and filter in a separate pass instead."
> "Positive examples of the communication style you want tend to be more effective than instructions about what not to do."
> "If your system prompt contains a rule instructing the model not to think or not to reason, remove it"

*Fable 5.1* — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1:
> "Your existing Claude Fable 5 prompts should perform well on Claude Fable 5.1 without changes"
> "Some earlier models were eager to give updates while working, which led to system prompt lines such as 'hold all findings for the final response.' Remove lines like that before adding anything."
> "Earlier models overused bullets and bold in chat, and many prompts carry anti-formatting rules written to hold that down. Claude Fable 5.1 leans the other way … If your prompt contains anti-formatting language, remove it or replace it with a rule that says when specific formatting is appropriate"
> Recommended additions (official sample blocks): "Keep changes and tests to what the task asks for" ("If, while working or testing, you find a pre-existing bug … report it as a follow-up in your summary … This is about extras only: implement every behavior the task asks for, completely."), "# Delivering work" scope block, and "try to surgically edit a file rather than rewrite the entire thing."

*Anthropic blog — "The new rules of context engineering for Claude 5 generation models"* (Thariq Shihipar, 2026-07-24) — https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/:
> "We removed over 80% of Claude Code's system prompt for models like Claude Opus 5 and Claude Fable 5 with no measurable loss on our coding evaluations."
> "Overall, we found that we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills."
> "Keep your CLAUDE.md lightweight and briefly describe what your repo is for, but spend most of the tokens on gotchas inside of the codebase."
> "Avoid stating 'the obvious' things Claude should know by looking at your file system or your repo."
> "For example if you have several unique instructions on how to verify your work, create a verification skill and reference it from your CLAUDE.md."
> "Instead of using examples, think more about the design of your tools, scripts and files- what parameters does Claude have and how can they be more expressive?"

- Implication (2026-09-24): the review lens for CLAUDE.md is now "what can be *deleted*" as much as "what is missing". Reasoning-reproduction instructions are a refusal risk (Major); verification/"think carefully"/narration-suppression/anti-formatting lines are overhead (Stale Information); official per-model sample blocks copied into CLAUDE.md are endorsed, subject to the model-specificity caveat.

---

## Changelog

- 2025-05-01: Initial version (based on Claude Code v2.x official docs)
- 2026-03-29: Major update — rewrote from official docs at code.claude.com/docs/en/memory and code.claude.com/docs/en/best-practices. Added: two memory systems table, managed policy locations (macOS/Linux/Windows), writing effective instructions (size/structure/specificity/consistency), include/exclude table, pruning guidance with direct quotes, emphasis for adherence, /init with CLAUDE_CODE_NEW_INIT, @path import details (depth limit, approval dialog, relative resolution), AGENTS.md compatibility, path-specific rules with YAML frontmatter and glob patterns, claudeMdExcludes setting, HTML comments stripping, CLAUDE.md vs hooks distinction, CLAUDE.md vs skills distinction, over-specified anti-pattern, compaction behavior and survival, troubleshooting section (InstructionsLoaded hook, /memory, --append-system-prompt), Claude 4 prompting practices (explicit instructions, motivation/context).
- 2026-05-30: Re-read official memory + best-practices docs. Factual corrections: recursive import depth is **four hops** (was "five"); `CLAUDE_CODE_NEW_INIT` shown as `=1` (was `=true`). Added: updated size guidance steering to path-scoped rules first and explicit note that imports do NOT reduce context (load at launch); `claudeMd` key for embedding managed CLAUDE.md content in `managed-settings.json`; AGENTS.md symlink option + `/init` reading `.cursorrules`/`.windsurfrules`; external-import-decline-is-permanent detail. Best-practices page otherwise unchanged. last_updated bumped to 2026-05-30.
- 2026-04-17: Re-read official docs. Added: `CLAUDE.local.md` as fourth scope in file-locations table (with concatenation/append-after ordering), new "When to Add to CLAUDE.md" official heuristic (4 triggers), `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` env var for `--add-dir` directories, Managed CLAUDE.md vs Managed Settings decision table, Auto Memory settings (`autoMemoryEnabled`, `autoMemoryDirectory`, v2.1.59+ requirement, `CLAUDE_CODE_DISABLE_AUTO_MEMORY`), Self-Editing CLAUDE.md guidance from long-running Claude research blog. Updated compaction behavior to clarify only project-root CLAUDE.md is re-injected after `/compact`; nested files reload lazily.
- 2026-06-24: Freshness re-run (14 days stale). Re-read memory + skills docs (unchanged vs 2026-06-10) and cross-checked the official changelog for May–June 2026. **Material additions from changelog v2.1.169–v2.1.181**: (1) `--safe-mode` / `CLAUDE_CODE_SAFE_MODE` disables all customizations incl. CLAUDE.md for troubleshooting (added to Troubleshooting); (2) the in-product "CLAUDE.md is too long" warning threshold now scales with the model's context window — authoring target of under-200 lines unchanged (added to Size guidance); (3) `/cd` command relocates a session to a new working dir, appending the new CLAUDE.md as a message without rebuilding the prompt cache, plus v2.1.172 branch-reporting fix (added to File Locations); (4) MEMORY.md compaction reminder (v2.1.181) and `CLAUDE_MEMORY_STORES` remote team-memory-store fix (v2.1.176) (added to Auto Memory). Added changelog to sources. last_updated bumped to 2026-06-24.
- 2026-06-10: Re-read code.claude.com/docs/en/memory (retrieved 2026-06-10). Factual correction: **`autoMemoryDirectory` is now read from any settings scope (user, project, local, policy, `--settings`)** — previously documented as not accepted from project settings; the project-scope restriction was replaced by the workspace-trust-dialog gate. Auto memory scope wording updated to "Per repository, shared across worktrees" (and machine-local). `/init` tool-config reading now includes `.devin/rules/`. All other content re-verified unchanged: under-200-line target, four-hop import depth, imports-load-at-launch, `.claude/rules/` recursion + symlinks + user-level rules, path-scoped rule triggering, HTML-comment stripping, `claudeMdExcludes`, `claudeMd` managed key, compaction re-injection (project-root only), `InstructionsLoaded` hook, MEMORY.md 200-line/25KB load limit.
- 2026-06-26: Freshness re-run (2 days stale). Re-read memory docs (https://code.claude.com/docs/en/memory, retrieved 2026-06-26) and cross-checked changelog through v2.1.193 (2026-06-25). **Material additions**: (1) **Import parsing skips fenced code blocks and code spans** — to mention an `@path` without importing, wrap in backticks (added to Import Syntax). (2) v2.1.181: CLAUDE.md Write/Edit fixed for network drives and cloud-synced folders (added to Troubleshooting). (3) v2.1.191: `/rewind` recovers conversation state after `/clear` (added to Troubleshooting). All other content re-verified unchanged: under-200-line authoring target (warning threshold still scales with context window per v2.1.169), four-hop import depth, `/cd`, `--safe-mode`, MEMORY.md compaction reminder, `claudeMd` managed key, `claudeMdExcludes`, compaction re-injection, auto-memory storage and trust-gate. last_updated bumped to 2026-06-26.
- 2026-07-25: Refreshed against code.claude.com/docs/en/memory (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **Material additions**: (1) **`/doctor` CLAUDE.md trim proposal** (v2.1.206) - cuts content derivable from the codebase (directory layouts, dependency lists, architecture overviews), keeps pitfalls, rationale, and conventions that differ from tool defaults. (2) **`.claude/rules/` path matching through symlinks** (v2.1.198). (3) **`paths` brace-expansion budget**: 1,000 expanded patterns and 4 MiB per rule; over-budget patterns are used unexpanded and match nothing (v2.1.217, which also fixed a startup stall/crash from many brace groups). (4) **Glob bracket handling**: an unreadable `[` bracket expression matches nothing and no longer breaks Read for every file the rule is evaluated against (v2.1.207); escape a literal `[` as `\[`. (5) **`--setting-sources` now also skips on-demand and nested project rules** when `project` is excluded (v2.1.211). (6) **MEMORY.md limit accounting** now strips YAML frontmatter and block-level HTML comments before measuring against the 200-line / 25KB read limit (v2.1.211), with a shorten-reminder near the limit and a rewrite error over it (v2.1.210). (7) **`modified` frontmatter timestamp** stamped on memory files that already have frontmatter (v2.1.214); Claude Code never adds frontmatter to a file that has none. (8) **`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`** loads memory files from `--add-dir` directories. (9) **`InstructionsLoaded` hook** for logging exactly which instruction files load, when, and why - the recommended tool for debugging path-scoped and lazy-loaded rules. (10) `/memory` no longer blocks the session while a GUI editor is open (v2.1.216). Under-200-line target, four-hop import depth, code-span/fenced-block import skipping, `claudeMd` managed key, `claudeMdExcludes`, and compaction re-injection all re-verified unchanged. last_updated bumped to 2026-07-25.
- 2026-09-04: Refreshed against code.claude.com/docs/en/memory + best-practices (retrieved 2026-09-04) and changelog v2.1.229–v2.1.260 (newest v2.1.260, 2026-09-03). **Material additions**: (1) **Emphasis dilution warning** — best-practices now says add "IMPORTANT" to the one skipped line *alone*; "If you emphasize many lines, none of them stands out" (added to Emphasis for Adherence). (2) **4 MiB hard limit** — a CLAUDE.md over 4 MiB is skipped entirely, not truncated (added to Size). (3) **`/import` command** (v2.1.213+) — one-time copy of another agent's instruction files (AGENTS.md etc.) plus MCP servers/commands/subagents/skills (added to AGENTS.md Compatibility). (4) **`/init` reading list restructured** — Cursor (`.cursor/rules/` or `.cursorrules`) + Copilot (`.github/copilot-instructions.md`) by default; AGENTS.md/`.devin/rules/`/`.windsurf/rules/`/`.clinerules` only with `CLAUDE_CODE_NEW_INIT=1`. (5) **User-scope import trust** — imports in `~/.claude/CLAUDE.md` / `~/.claude/rules/` load without the approval dialog except in Cowork desktop sessions, which also skip symlinked user-scope memory files pointing outside the working dir (added to Import Syntax). (6) **`claudeMdExcludes` symlink matching** (v2.1.239–v2.1.243) — a pattern matching either the rules path or the link target now excludes the file (added to claudeMdExcludes). (7) **`CLAUDE_CODE_PROJECT_DIR_NAME`** (v2.1.234) shares one auto-memory dir across projects; **four auto-memory `type` kinds** (`user`/`feedback`/`project`/`reference`) documented (added to Auto Memory). (8) **`/context` supersedes `/memory` as the load-verification command**; compaction wording now covers path-scoped rules reloading lazily (added to Troubleshooting/Compaction). (9) v2.1.260: managed `claudeMd` no longer triggers the security approval dialog; v2.1.257: `.claude/` folder created after startup is now picked up without restart. Under-200-line target, four-hop import depth, imports-load-at-launch, `/doctor` trim, and MEMORY.md limits all re-verified unchanged. last_updated bumped to 2026-09-04.
- 2026-09-16: Refreshed against code.claude.com/docs/en/memory + best-practices (retrieved 2026-09-16), three newly-cited official pages (context-window, large-codebases, sub-agents), the platform prompting docs, and changelog v2.1.261–v2.1.273 (newest v2.1.273, 2026-09-15). **Material additions/corrections**: (1) **Load-order correction** — the file-locations table is now ordered Managed → User → Project → Local per "a project instruction appears in context after a user instruction"; this file previously listed Project above User (File Locations). (2) **Symlinked rules outside the working directory are external imports** — they don't load until external-import approval, which symlinks alone never trigger, and path-scoped ones never load even after approval; official fix is `~/.claude/rules/` (Modularization). (3) **`omitClaudeMd` subagent frontmatter** (v2.1.271) + what a subagent loads: full CLAUDE.md hierarchy incl. user file, rules, CLAUDE.local.md; Explore/Plan skip it; main-session auto memory never reaches subagents except forks (new "Subagents and CLAUDE.md" section, Auto Memory). (4) **"What survives compaction" table** — unscoped rules and the plan file re-inject from disk; path-scoped rules and nested CLAUDE.md are summarized away ("drop the `paths:` frontmatter" to persist); skill bodies capped 5,000/skill, 25,000 total; v2.1.269 git-status-after-compaction fix; v2.1.273 context-meter fix (Compaction). (5) **Illustrative startup token costs** from the context-window page (project CLAUDE.md ~1,800, user ~320, MEMORY.md ~680) (Size). (6) **large-codebases page**: per-directory CLAUDE.md vs path-scoped rule decision table, `claudeMdExcludes` pattern recipes, `additionalDirectories` never loads memory files vs `--add-dir`, settings not inherited from parent dirs, and three maintenance practices — review in PRs, revisit after major model releases, Stop hook proposing updates (Modularization, claudeMdExcludes, File Locations, Troubleshooting). (7) **Claude 4 → Claude 5 prompting section** — old URL 301s to platform.claude.com "Prompting best practices"; new official quotes: dial back aggressive "CRITICAL: You MUST" language, brief instructions suffice on Fable 5, re-evaluate old instructions after capability jumps, give the reason. (8) Minor: memory-page intro now names PreToolUse hooks as the enforcement path; auto-memory "Use for" column re-worded; `/init` personal-option gitignore requires `CLAUDE_CODE_NEW_INIT=1`; v2.1.261 `/context` local-estimate fallback + `/skill-doctor`; v2.1.269 attribution reminder no longer overrides a CLAUDE.md rule; v2.1.273 `blockReadsOutsideWorkingDirectories` ignores repo-chosen memory dirs. Under-200-line target, 4 MiB skip, four-hop import depth, imports-load-at-launch, `/doctor` trim, `/import`, and MEMORY.md limits all re-verified unchanged. last_updated bumped to 2026-09-16.
- 2026-08-12: Refreshed against code.claude.com/docs/en/memory (retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. **Doc page re-verified with no authoring-rule changes**: under-200-line target, four-hop import depth, imports-load-at-launch, specificity/structure/consistency guidance, `.claude/rules/` (recursive, symlink-friendly, user-level loaded before project), `paths` glob format and brace budget, `claudeMd` / `claudeMdExcludes` managed keys, HTML-comment stripping, compaction re-injection (project-root only), MEMORY.md 200-line/25KB load limit, `modified` frontmatter timestamp, `InstructionsLoaded` hook, and the `/doctor` trim proposal all unchanged. **Changelog additions**: (1) **Auto-compact now keeps sessions within the assumed context window** (v2.1.223) and `CLAUDE_CODE_DISABLE_1M_CONTEXT` holds every Claude 1M model to 200K - the effective budget CLAUDE.md competes for can be smaller than the model's nominal window, reinforcing the under-200-line target. (2) **Session cleanup no longer deletes contents inside a project's memory folder** (v2.1.228) - a prior cause of vanished auto-memory files. (3) **Claude Opus 5 (`claude-opus-5`) is the default Opus model** (v2.1.219); the in-product "CLAUDE.md is too long" threshold still scales with the active model's context window. (4) `/cd` mid-session resume fixed (v2.1.223). last_updated bumped to 2026-08-12.
- 2026-09-24: Refreshed against code.claude.com/docs/en/memory (incl. the new #agents-md section) + best-practices (retrieved 2026-09-24), the platform prompting guide and per-model pages for Opus 5, Opus 5.5, Fable 5, Fable 5.1, the Anthropic blog "The new rules of context engineering for Claude 5 generation models" (2026-07-24), and changelog v2.1.274–v2.1.281 (newest v2.1.281, 2026-09-23). **Material additions/corrections**: (1) **AGENTS.md — CORRECTION**: native reading since v2.1.277; the 2026-03 "Claude Code reads CLAUDE.md, not AGENTS.md" quote is superseded. Recorded default (`claude-md-or-agents-md`: AGENTS.md only when no CLAUDE.md/.claude/CLAUDE.md/CLAUDE.local.md on the path), the four Project-instructions values and where they may be set, loading/difference rules, unavailability cases, and the official "remove an earlier workaround" list (prose pointer and SessionStart-print hook are to be removed; `@AGENTS.md` import is safe to keep). (2) **Size**: v2.1.281 startup notice now aggregates instruction files and @-imports. (3) **Claude 5 Prompting Practices** extended: prompting guide now covers Opus 5.5 and says model-named techniques are measured on that model; official "NEVER use ellipses → give the reason" example; Opus 5.5 (default Opus since v2.1.280) — remove "think carefully" lines, remove reasoning-in-response instructions (`reasoning_extraction`), lower effort before prompting for less thinking; Opus 5 — remove verification/double-check instructions, severity filters in review prompts are followed literally, positive examples beat don'ts, remove no-thinking rules; Fable 5.1 — remove narration suppression and anti-formatting rules, official scope/"Delivering work"/surgical-edit sample blocks; blog — 80%+ of Claude Code's system prompt removed, "overconstraining … in our CLAUDE.md files and skills", "spend most of the tokens on gotchas", verification instructions → a skill referenced from CLAUDE.md. (4) **Troubleshooting**: v2.1.281 `"attribution": false` setting; `--add-dir` double-send fix; v2.1.277 headless first-turn CLAUDE.md lookup no longer blocks. Under-200-line target, 4 MiB skip, four-hop import depth, imports-load-at-launch, emphasis-one-line rule and `/doctor` trim re-verified unchanged. last_updated bumped to 2026-09-24.

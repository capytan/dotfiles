# Official Best Practices for CLAUDE.md

> This file is auto-updated in Phase 0 (Research).
> Manual edits are fine but may be overwritten on next research run.
> Items tagged `[custom]` are protected from overwrite.

last_updated: 2026-11-19
sources:
  - https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
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
- Best-Practices Page Rewrite (2026-10)
- Memory Page Additions (2026-10)
- Additions (2026-11)

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
- **Caveat (2026-10-28)**: the "later-read wins" precedence above is this file's inference, not documented. The memory page now says of user vs project rules: "Neither set overrides the other: if a user rule and a project rule conflict, Claude may follow either one, so keep the two consistent." Treat cross-scope conflicts as Conflicting Instructions, not as resolved by load order.
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

**Superseded 2026-10-28**: the rewritten page no longer recommends emphasis at all — "adding IMPORTANT probably won't fix it" and "Add IMPORTANT or ALL CAPS" is listed under "What you can stop doing". See "Best-Practices Page Rewrite" below.

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

- "**Not read**: `AGENTS.local.md`, `AGENTS.override.md`, or anything under a `.agents/` directory" — https://code.claude.com/docs/en/memory#agents-md (retrieved 2026-11-19)
- **Project instructions** values (`/config`, or `pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles` in user/`--settings`/managed settings — ignored in project and local settings): `claude-md-or-agents-md` (default), `claude-md-and-agents-md` ("each directory's `CLAUDE.md` files first and its `AGENTS.md` after them. Claude Code skips an `AGENTS.md` it has already loaded"), `claude-md`, `managed-only`. Plugin ID (retrieved 2026-11-19): "Before v2.1.285, the plugin's ID was `agents-md@builtin`, and Claude Code ignored an entry under `cc-plugin-agents-md@builtin`. If earlier versions also read your settings file, use `agents-md@builtin` there. Claude Code v2.1.285 and later reads an entry under either ID." — https://code.claude.com/docs/en/memory#agents-md
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

  **Updated 2026-10-28**: the page now reads "Claude Code asks for that approval once per project, in a dialog at the start of an interactive session. The dialog lists the linked rule files alongside any external `@path` imports." (changelog v2.1.284 fixed outside-symlinked rules "being skipped without ever showing" the dialog), so consequence (1) below is obsolete on v2.1.284+; (2) still holds.

  Two consequences for symlink-based sharing: (1) [obsolete since v2.1.284] a project whose only outside-the-tree reference is a symlink never triggers the approval dialog, so those linked rules silently never load; (2) even after approval, a linked rule *with* `paths:` frontmatter never loads. The official fix is `~/.claude/rules/` for personal sharing, or a plugin for team sharing (https://code.claude.com/docs/en/large-codebases, "Centralize conventions when layering stops scaling").
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

- **`/context all` is the load-verification command** (was `/context` from 2026-09-04): "Run `/context all` and check the list under **Memory files** to verify the CLAUDE.md and CLAUDE.local.md files that should load at launch." and "In fullscreen mode, `/context` alone collapses that list." The best-practices page uses the same command: "In a session, run `/context all` to confirm that Claude loaded the file." (`/memory` lists file locations including not-yet-created ones; `/context all` shows what actually loaded this session.) — https://code.claude.com/docs/en/memory, https://code.claude.com/docs/en/best-practices (retrieved 2026-11-19)
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

### Best-Practices Page Rewrite (first observed 2026-10-28) `[official]`

The best-practices page is restructured around "tell Claude what it can't see / give it a check to run / enforce the rules that can't have exceptions". All quotes below: https://code.claude.com/docs/en/best-practices (retrieved 2026-10-28). The old Include/Exclude table and the "Would removing this cause Claude to make mistakes?" pruning quote no longer appear on the page; the principles survive in the wording below.

*Inferability test*
> "Only write down what Claude can't find by reading the repo, or what it would otherwise spend time rediscovering every session."
> "A good test before you write anything down for Claude: 1. Could it find this by reading the code? 2. Would it actually go and look? If both are yes, leave it out."
> "There's also information that *is* in the repo but takes a few minutes of digging to find, and Claude has to redo that digging at the start of every session."

*Keep CLAUDE.md short — the new official include list*
> "every line in it takes a little of Claude's attention on *every* task, whether it's relevant or not. That's why the file works best when it only holds what Claude couldn't work out from the code itself:
> - How to confirm work in this repo: the exact test, typecheck, and lint commands, and how to run a single test file
> - Places where the code is misleading: an old pattern that's everywhere but that new code must not copy, or a directory that looks unused but isn't
> - Decisions that aren't in the repo: which error helper the team settled on, how deploys work, what needs a migration review
> - Anything you've had to correct twice already"
> "Notice that the typecheck line is only the command. … A line like `Always typecheck before you finish` in this file works most of the time, not every time." (→ Stop hook for enforcement)
> "`/doctor prompt-audit` flags instructions that were written for older models, point at files that no longer exist, or contradict each other."

*Emphasis — supersedes the 2026-09-04 "add emphasis to that line alone" wording*
> "If Claude keeps ignoring a line that *is* in `CLAUDE.md`, adding IMPORTANT probably won't fix it. Either the file has grown long enough that the line gets lost, or the line is a rule that can't have exceptions, in which case it belongs in a hook."
> "If you keep adding emphasis to a `CLAUDE.md` line and Claude still misses it, that's a sign the line belongs in a hook. The reverse holds too: if you have hooks for things that are only preferences, delete them and let Claude decide."

*Hooks only for zero-exception rules*
> "If something has to happen every time, make it a hook, a deny rule, or a managed setting. `CLAUDE.md` is for guidelines, and Claude is allowed to decide a guideline doesn't apply."
> "Don't overdo it, though: a hook is for a rule with *zero* exceptions, and `Prefer named exports` has plenty, so that one stays in `CLAUDE.md`."
> "keep the enforced set small. Every hook and deny rule will occasionally fire when it shouldn't … If you ever find yourself at forty of them, most are probably preferences that Claude could have weighed on its own."
> "A `prompt` or `agent` hook asks *another model* to decide, so it isn't deterministic either. For real enforcement, use a `command` or `http` hook, and add `onFailure: \"block\"` …"

*Skills for team procedures*
> "The `CLAUDE.md` rule applies to skills too: only write down what Claude can't find on its own."

*"What you can stop doing" table (old advice → why it's gone)*
> "Add IMPORTANT or ALL CAPS to instructions Claude keeps missing | Older models sometimes needed the emphasis. Current ones follow a plainly worded line, and piling on emphasis mostly makes Claude over-apply the rule. If it's a rule that can't bend, turn it into a hook or a deny rule. If the line is getting lost in a long file, the file needs to be shorter."
> "`think hard`, `think harder`, `be thorough` in the prompt | Effort is the control for that. … `ultrathink` still works: it asks for deeper reasoning on that single turn without touching your effort setting."
> "Tell Claude to keep going, loop until done, don't be lazy | Current models usually carry on through an agreed task without being told, and lines like that are more likely to cause over-work than fix a stall. Giving Claude a check to pass is different, and still worth doing."
> "Describe your architecture and file layout in `CLAUDE.md` | Claude reads the repo itself. Only write down what isn't in there."
> "Use subagents to protect your context window | Running out of context is rarely the problem anymore."

**Conflict note**: the memory page still lists "project layout" among facts to keep ("Keep it to facts Claude should hold in every session: build commands, conventions, project layout, 'always do X' rules") and "architectural decisions" for a project CLAUDE.md. Reconciled reading (consistent with the `/doctor` trim rule): *decisions* and *misleading places* stay; *descriptions of layout Claude can read* go.

### Memory Page Additions (retrieved 2026-10-28) `[official]`

All from https://code.claude.com/docs/en/memory (retrieved 2026-10-28) unless noted.

- **`/doctor prompt-audit` (v2.1.283+)**: "To have Claude check your instruction files for outdated or conflicting content, run `/doctor prompt-audit` in a session. Claude looks for problems such as instructions written for older models, references to files or commands that don't exist, and files that contradict each other. You get a report of findings with proposed edits, and nothing in your files changes until you ask Claude to apply them." Default scope: "your CLAUDE.md, CLAUDE.local.md, and AGENTS.md files, plus the rules, skills, commands, subagents, and output styles under `.claude/` and `~/.claude/`". "The audit runs through the bundled `/claude-api` skill. It's unavailable while that skill is turned off in `skillOverrides` or with `disableBundledSkills`." Changelog v2.1.283: "Improved `prompt-audit` on Claude Code configuration: stale paths, stale commands and contradicting instruction files…" lead the report.
- **Per-file size limit for on-demand files (v2.1.309, 2026-10-22)**: "When a subdirectory `CLAUDE.md` or a rules file that loads on demand is over a per-file size limit, Claude receives only the start of it. That part ends with a note telling Claude to read the rest with the Read tool, and until Claude chooses to, the later instructions aren't in its context." Applies to subdirectory CLAUDE.md/CLAUDE.local.md (+ their `@` imports), rules in a subdirectory's `.claude/rules/`, and path-scoped rules in `.claude/rules/` or `~/.claude/rules/`. Limits: "**200K context window**: 40,000 characters"; "**1M context window**: 200,000 characters on Claude Opus 4.6 and Claude Sonnet 4.6, and 150,000 characters on later models". Check with `wc -m`. Fix: "trim the file, or move part of it into one or more rules files, which each count against the limit on their own". "Before v2.1.309, Claude Code didn't apply this limit to files that load on demand."
- **Combined-size warning**: "You also see a warning when files that are each within that length add up past a combined limit at session start. Each CLAUDE.md, rules file, and `@path` import counts as a separate file."
- **Rule frontmatter reference**: "`paths` is the only field Claude Code reads from a rule; any other field is ignored without an error." "If the YAML between the markers doesn't parse, Claude Code ignores the frontmatter and loads the rule as if it had no `paths`." `paths` "Accepts a YAML list or a comma-separated string".
- **User vs project rules — no override (correction)**: "Claude Code loads user-level rules before project rules, so a project rule appears later in Claude's context than a user rule. Neither set overrides the other: if a user rule and a project rule conflict, Claude may follow either one, so keep the two consistent." This supersedes the inference recorded under File Locations ("later-read content wins on conflict … a project CLAUDE.md rule overrides") — load order is documented, precedence is not.
- **User-level path-scoped rules**: pattern base is "the session's primary working directory" (project rules: "the directory that contains the rule's `.claude` folder").
- **Competing built-in guidance**: "Check whether your instruction competes with guidance Claude Code adds on its own. If your CLAUDE.md sets commit or pull request rules, turn off the built-in ones with `includeGitInstructions` and set the attribution text with `attribution`."
- **Import paths with spaces**: "put a backslash before each space. … A path wrapped in quotes isn't imported at all, with or without the backslashes."
- **Network-path symlinks**: "If you point a `.claude/rules/` or `CLAUDE.md` symlink at a network path such as the UNC share `\\server\share` or a path under `/net` or `/Network`, the linked instructions don't load."
- **Testing a new subdirectory CLAUDE.md**: "To test a new one, create it from your shell rather than asking Claude to write it, then ask Claude to read a file in that subdirectory." `Instruction file not loaded` notices are documented at errors.md.
- **Changelog v2.1.282–v2.1.311 (newest 2026-10-26)** — https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md (retrieved 2026-10-28): v2.1.284 "Improved auto-memory loading: invisible characters and tags that imitate Claude Code's own markup…" and fixed rules symlinked from outside the project "being skipped without ever showing…" the approval dialog; v2.1.286 fixed worktree-isolated subagents loading the project CLAUDE.md and imports twice; v2.1.287 fixed a folder's CLAUDE.md attached twice after resume/compaction; v2.1.290 "Fixed a subdirectory's AGENTS.md not being attached when a file under it is @-mentioned" and "Changed `/code-review` at medium effort to also report cleanup and CLAUDE.md conventions findings…"; v2.1.292 "Fixed reviews ignoring a CLAUDE.md's rules when the pull request edits that file…"; v2.1.293 path-scoped rules / nested CLAUDE.md now load on a single-file `cat`; v2.1.309 "a nested CLAUDE.md over the size limit now loads only its start"; v2.1.311 "Fixed Claude seeing stale MEMORY.md and CLAUDE.md content right after automatic compaction" and "Fixed long freezes at startup … when a CLAUDE.md file holds a very long list item".

### Additions (retrieved 2026-11-19) `[official]`

Best-practices page (https://code.claude.com/docs/en/best-practices, retrieved 2026-11-19). The 2026-10-28 quotes above are unchanged; these are new or newly prominent:

- **Check command as the top line**: "If your repo already has one of these, the single most useful line in your `CLAUDE.md` is the command that runs it." ("these" = "A test file / A build's exit code / A linter / A script that diffs output against a fixture / A browser screenshot next to the mockup".)
- **New "Deterministic and non-deterministic instructions" section**: "Non-deterministic: you write the instruction, and Claude (the model) reads it. This can be your prompt, `CLAUDE.md`, or a skill." / "Deterministic: you configure the instruction, and Claude Code (the harness) *has* to execute this. This can be a hook, a deny rule, or a managed setting." / "Most of the time, you want Claude to decide. Almost every guideline has exceptions, and current models are good at reading the code in front of them and judging whether a guideline fits the situation. With the actual code in front of it, Claude is usually better placed to make that call than a rule you wrote in advance." / "You could've written either of these as a line in `CLAUDE.md` or in your prompt, and Claude would follow it nearly every time. But no matter how strongly you word it, whether Claude follows that line on a given turn is still Claude's call."
- **Official example CLAUDE.md** uses three headings — `# Commands` (Install, "Run one test file", Typecheck), `# Conventions`, `# Gotchas` — introduced as "A `CLAUDE.md` that passes that test stays short".
- **Tooling for trimming**: "`/init` generates a starting version from your codebase. From there the work is mostly removing lines." / "`/doctor` suggests cuts for anything Claude can already work out from the code."
- **Personal preferences**: "Your personal preferences go in `CLAUDE.local.md` instead of `CLAUDE.md`, and you add that file to `.gitignore` so it stays out of the repo."
- **Install command for fresh checkouts**: worktrees don't carry dependencies, so for large directories use `worktree.symlinkDirectories`, "or keep the install command in `CLAUDE.md` so Claude runs it whenever it starts in a new checkout."
- **Skills are lighter on context**: "A long release procedure sitting in a skill doesn't weigh on your unrelated bug fix the way it would in `CLAUDE.md`."

Memory page (https://code.claude.com/docs/en/memory, retrieved 2026-11-19):

- **Write effective instructions — reworded**: "Claude treats CLAUDE.md files as context, not enforced configuration, so how you write instructions affects how reliably Claude follows them." Size bullet now: "Move instructions that matter for only part of the codebase into path-scoped rules, which load only when Claude works with matching files. Imports help you organize a long file but don't reduce its context cost, because imported files load together with the CLAUDE.md that imports them." Under-200-line target unchanged.
- **`/init` tip**: "Refine from there with instructions Claude wouldn't discover on its own."
- **`/doctor prompt-audit` scoping**: "To audit one file or directory instead, pass its path, for example `/doctor prompt-audit .claude/skills/deploy`."
- **Path-scoped rules and sibling worktrees**: "To have path-scoped rules load for files in a sibling git worktree, start Claude Code in that worktree or move the session there with `/cd`."
- **Literal `[` in `paths`**: "To match a literal `[` in a file name, escape it inside single quotes, as in `'photos \[2024/**'`." Unparseable frontmatter: "Run `claude --debug` to see the parse error."
- **Managed CLAUDE.md and disabled loading**: "If a developer starts a session with CLAUDE.md loading turned off altogether, that session doesn't load the managed content either. Use the file for guidance, and enforce rules with managed settings such as `permissions.deny`."
- **Network symlinks**: "`\\wsl$` paths don't count as network paths."
- **Auto memory**: on by default locally, but "a session in a self-hosted environment runs with auto memory off by default"; memory files are excluded from the `cleanupPeriodDays` transcript sweep.

Changelog v2.1.312–v2.1.328 (newest v2.1.328, 2026-11-19) — https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md (retrieved 2026-11-19). No change to loading rules, size limits, or rule frontmatter. Relevant items: v2.1.328 "Changed `/code-review` on most models to report only bugs and CLAUDE.md violations; run `/simplify` for reuse, simplification and efficiency cleanups"; v2.1.312 "Fixed Claude overwriting a very large CLAUDE.md, rules file or @-included file in a subdirectory after seeing only its start; Write now asks Claude to read it all or edit in place"; v2.1.317 "Fixed \"Prompt is too long\" after automatic compaction in sessions whose very large CLAUDE.md changed since it was last sent"; v2.1.314 fixed `/resume` showing CLAUDE.md text as a session title; v2.1.316 SDK `register_repo_root` CLAUDE.md loading fix; v2.1.323/v2.1.326 `/memory` path display and read-only-file warning fixes; v2.1.326 "Improved `/doctor` to share findings as it works"; v2.1.327 `claudeMdExcludes` Windows drive-letter case fix.

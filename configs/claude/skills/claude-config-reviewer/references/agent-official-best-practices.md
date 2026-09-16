# Official Best Practices for Agent Files

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

last_updated: 2026-09-16
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/best-practices
  - https://code.claude.com/docs/en/changelog
  - https://code.claude.com/docs/en/errors
  - https://code.claude.com/docs/en/agent-teams
  - https://code.claude.com/docs/en/tools-reference
  - https://claude.com/blog/subagents-in-claude-code
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

---

## Contents

Summary from Official Documentation:
- What Subagents Are
- Subagent File Structure
- Frontmatter Reference
- Subagent Files Claude Code Skips
- Where Subagents Live
- Description & Triggering
- Model Selection
- Tool Restriction
- Preloading Skills
- Persistent Memory
- Built-in Subagents
- Best Practices
- System Prompt Style
- When to Use Subagents vs Main Conversation
- Invocation Patterns
- Hooks in Subagents
- Plugin Subagent Restrictions
- Permission Modes
- Subagent Definitions as Agent-Team Teammates
- Headless: --append-subagent-system-prompt
- Auto-Compaction
- Nesting Limit
- Forked Subagents (experimental)
- CLI-defined subagents (--agents JSON)

## Summary from Official Documentation

### What Subagents Are `[official]`

> "Subagents are specialized AI assistants that handle specific types of tasks. Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and returns only the summary. Define a custom subagent when you keep spawning the same kind of worker with the same instructions."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

Key benefits:
- Preserve context (exploration stays out of main conversation)
- Enforce constraints (limit tools)
- Reuse configurations across projects
- Specialize behavior with focused system prompts
- Control costs by routing to faster/cheaper models

### Subagent File Structure `[official]`

> "Subagent files use YAML frontmatter for configuration, followed by the system prompt in Markdown."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Frontmatter Reference `[official]`

> "Only name and description are required."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens. Hooks receive this as `agent_type`. **The filename does not have to match the `name`.** Identity comes only from the `name` field; the subdirectory path does not affect invocation. **`:` is forbidden (added 2026-09-04)**: "Names can't contain `:`, which is reserved for plugin-scoped identifiers such as `my-plugin:reviewer`. Claude Code doesn't load a file whose name contains one and logs an error to the debug log. Before v2.1.218, such names were accepted" (retrieved 2026-09-04). **Leading `-` is also forbidden (added 2026-09-16)**: "A `name` that starts with `-` or contains `:`: Claude Code skips the file and writes an error to the debug log" (retrieved 2026-09-16; see *Subagent Files Claude Code Skips*) |
| `description` | Yes | When Claude should delegate to this subagent. **A file with `name` but no `description` is skipped entirely** (retrieved 2026-09-16; see *Subagent Files Claude Code Skips*) |
| `tools` | No | Tools the subagent can use. "Inherits every tool available to subagents if omitted. If no entry in the list resolves to a tool, the subagent usually fails to launch with an error naming the entries. To preload Skills into context, use the `skills` field rather than listing `Skill` here" (retrieved 2026-09-16). The "usually" is precise: an **empty** `tools` list, or one that `disallowedTools` empties, launches tool-less without the refusal (see *Tool Restriction*) |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list. **Specifiers are not honored (added 2026-09-16)**: "An entry with a specifier, such as `Bash(git push *)`, still removes the whole tool" (retrieved 2026-09-16; see *Tool Restriction*) |
| `model` | No | `sonnet`, `opus`, `haiku`, `fable`, full model ID (e.g., `claude-opus-4-8`, `claude-sonnet-4-6`), or `inherit`. Default: `inherit`. **`fable` added to the official alias list (retrieved 2026-06-10)** |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual` (alias for `default`, v2.1.200+). `auto` = background classifier reviews commands; `dontAsk` = auto-deny prompts (explicitly allowed tools still work). Parent `bypassPermissions`/`acceptEdits` take precedence and cannot be overridden; a parent in auto mode forces auto mode (frontmatter ignored). **As of v2.1.223, an agent definition's `bypassPermissions` no longer overrides org policy** ("Fixed permission gap where agent definition's `bypassPermissions` mode ignored org policy"). **As of v2.1.267 (added 2026-09-16) a subagent's `bypassPermissions` is honored only when the main conversation is already in that mode** — see *Permission Modes* |
| `maxTurns` | No | Maximum agentic turns before stopping. **Updated 2026-09-04:** "When the subagent reaches the limit, Claude Code returns its output marked as partial, and Claude can resume it to continue. The partial marking requires Claude Code v2.1.246 or later" |
| `skills` | No | Skills to preload into context at startup |
| `mcpServers` | No | MCP servers available to subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | **Semantics clarified 2026-09-04:** "Set to `true` to keep this subagent in the background even when Claude asks to run it in the foreground." Default: `false`. An in-process agent-team teammate **refuses with an error** to spawn a subagent whose definition sets `background: true` (retrieved 2026-09-16) |
| `omitClaudeMd` | No | **NEW (v2.1.271, added 2026-09-16):** "Set to `true` to launch this subagent without the user, project, and local CLAUDE.md files; managed policy files still load, except for managed subagents. Use it for subagents that take everything they need from the delegation prompt. Ignored when the agent runs as the main session agent via `--agent` or the `agent` setting. Requires Claude Code v2.1.271 or later" (retrieved 2026-09-16). Also accepted in `--agents` JSON. Changelog v2.1.271: "Added `omitClaudeMd` to agent frontmatter and `--agents` JSON, letting custom and plugin subagents run without user, project and local CLAUDE.md files; managed policy files still load" |
| `effort` | No | `low`, `medium`, `high`, `xhigh`, `max` (levels depend on model) |
| `isolation` | No | `worktree` for temporary git worktree isolation. **Semantics detailed 2026-09-04:** "giving it an isolated copy of the repository branched by default from your default branch rather than the parent session's `HEAD`. The worktree is automatically cleaned up if the subagent makes no changes." |
| `color` | No | Display color. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan` |
| `initialPrompt` | No | Auto-submitted first user turn when running as main session agent |
| `experimental` | No | **NEW (v2.1.248, added 2026-09-04):** "Map of experimental options. Set its `cacheTtl` key to `5m` or `1h` to choose the prompt cache lifetime for this subagent's requests… Claude Code ignores any other value, ignores `1h` while your Claude subscription is using usage credits, and reads the field only from subagent files. Requires Claude Code v2.1.248 or later" |

**Note on `color` values `[official]`:** Updated 2026-04-17. The official palette is `red | blue | green | yellow | purple | orange | pink | cyan`. Prior references to `magenta` are not part of the documented set.
— https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Subagent Files Claude Code Skips `[official]` (NEW 2026-09-16)

The docs now enumerate every frontmatter defect that makes a file silently not exist. None of these is reported in the session; most go only to the debug log (`--debug`).

> "Claude Code skips a file in a project, user, or managed `agents` directory, or in one under a directory you add with `--add-dir`, without reporting it in the session, when the frontmatter has any of these problems:
> - **No `name`**: Claude Code treats the file as documentation kept beside your agents.
> - **An opening `---` that isn't the file's first line**: Claude Code reads the file as having no frontmatter and treats it as documentation.
> - **A `name` that starts with `-` or contains `:`**: Claude Code skips the file and writes an error to the debug log.
> - **A `name` but no `description`**: Claude Code skips the file and writes the reason to the debug log.
> - **YAML that doesn't parse**: Claude Code reads no fields from the file, skips it, and writes the parse error to the debug log."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Scoring implication: all five are Critical for criterion A — the agent is not misconfigured, it is absent. The "`---` not on line 1" case covers a leading blank line, a comment, or a stray character before the frontmatter (the UTF-8 BOM case, fixed in v2.1.239, is the historical instance of it). "No `name`" is the one *intentional* use: a README-style `.md` kept inside `agents/` is fine as long as it has no `name:` frontmatter.

### Where Subagents Live `[official]`

| Location | Scope | Priority |
|----------|-------|----------|
| Managed settings (`.claude/agents/` in managed dir) | Organization-wide | 1 (highest) |
| `--agents` CLI flag | Current session | 2 |
| `.claude/agents/` | Current project | 3 |
| `~/.claude/agents/` | All your projects | 4 |
| Plugin's `agents/` | Where plugin is enabled | 5 (lowest) |

> "Project subagents (.claude/agents/) are ideal for subagents specific to a codebase. Check them into version control so your team can use and improve them collaboratively."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**Recursive scanning & name uniqueness `[official]` (2026-06; wording updated 2026-09-16):**
> "Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so you can organize definitions into subfolders such as `agents/review/` or `agents/research/`. The subdirectory path does not affect how a subagent is identified or invoked, because identity comes only from the `name` frontmatter field. Keep `name` values unique across the whole tree: if two files within one scope declare the same name, Claude Code keeps one and discards the other without warning."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

Current wording makes the tie-break explicitly undefined: "if two files under the same `.claude/agents/` directory, including its subfolders, declare the same name, Claude Code loads only one of them, chosen by filesystem read order rather than a documented precedence." (retrieved 2026-09-16) — i.e. which one wins can differ between machines.

Plugin `agents/` subfolders, unlike project/user scopes, DO become part of the scoped identifier: `agents/review/security.md` in plugin `my-plugin` registers as `my-plugin:review:security`.

**Nested project agents tie-break — closest-to-cwd wins `[official]` (added 2026-06-26, changelog v2.1.178):**
> "Project subagents are discovered by walking up from the current working directory, so every `.claude/agents/` between there and the repository root is scanned. As of v2.1.178, when more than one of these nested directories defines the same `name`, Claude Code uses the definition closest to the working directory."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

This is a *different* rule from the within-one-scope "duplicates silently discarded" behavior: nested project `.claude/agents/` directories along the cwd walk now have a deterministic tie-break (closest wins), rather than silent loss.

**Load timing — hot reload `[official]` (CORRECTED 2026-09-16; supersedes the 2026-06 "restart your session" note):**
> "Claude Code watches `~/.claude/agents/` and `.claude/agents/`. When you add or edit a subagent file on disk, or ask Claude to write one for you, Claude Code detects the change within a few seconds and the next delegation uses the updated definition, with no restart needed.
> Three cases still need a restart:
> - The watcher covers only directories that existed when the session started, so after creating a scope's first agent file in a new `agents` directory, restart to load it.
> - Claude Code doesn't watch `.claude/agents/` inside directories added with `--add-dir` or `/add-dir`, so after adding or editing a subagent there, restart to load the change.
> - Sessions started with `--disable-slash-commands` don't watch these directories at all."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

The 2026-06 text ("Subagents are loaded at session start… restart your session to load it") is gone from the docs. Agent files or READMEs that tell users to restart after every edit now carry stale guidance (advisory only; the three exceptions above are still real).

**UTF-8 BOM makes the file invisible `[official]` (added 2026-09-04, changelog v2.1.239):**
> "Fixed agents, skills, and commands whose `.md` file starts with a UTF-8 BOM being silently ignored"
> — https://code.claude.com/docs/en/changelog, v2.1.239 (retrieved 2026-09-04)

Before v2.1.239, an agent file saved with a UTF-8 BOM (common with some Windows editors) was silently ignored — no error, the agent just never existed. Fixed in current versions, but a BOM in a checked-in agent file still breaks users on older Claude Code; flag it.

**`/cd` reloads project agents `[official]` (added 2026-09-04, changelog v2.1.243):** "Improved `/cd`: the new directory's project settings, hooks, `.mcp.json` servers, skills, and agents now take effect right after the move."

**`--add-dir` scope for agents `[official]` (added 2026-06-26):**
> "Directories added with `--add-dir` are also scanned: a `.claude/agents/` folder inside an added directory loads alongside project subagents."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

### Description & Triggering `[official]`

> "Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "To encourage proactive delegation, include phrases like 'use proactively' in your subagent's description field."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Claude automatically delegates tasks based on the task description in your request, the description field in subagent configurations, and current context."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**Combined description token budget — 15,000 tokens `[official]` (added 2026-09-04):**
> "Those descriptions take up context, so keep them short. When the combined descriptions of your subagents, except the built-in ones, exceed 15,000 tokens, Claude Code shows a warning at startup with the total token count. Trim the `description` fields of your subagents, and move detail into each subagent's system prompt, which only loads when that subagent runs."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

This is the first official, quantified pressure toward **short descriptions**: every subagent's description is always-loaded context, and the budget is shared across the whole pool. Scoring implication: very long descriptions (e.g. many `<example>` blocks) now have a documented cost, not just a style preference — behavior detail belongs in the body, which loads only when the agent runs.

**Budget mechanics (added 2026-09-16)** — the errors reference clarifies what is counted and that nothing is dropped:
> "Claude Code shows this warning as a startup notice in the conversation view rather than on stderr. The combined descriptions of your subagents, except the built-in ones, exceed 15,000 tokens as Claude Code estimates them. Each agent counts its name plus its `description` frontmatter. Claude Code loads every agent whether or not the total is over the limit, so the warning doesn't change what loads."
> — https://code.claude.com/docs/en/errors (retrieved 2026-09-16)

Sample notice text: `Agent descriptions are over the 15.0k-token limit (~16.2k tokens) · ask Claude to trim agent descriptions in .claude/agents/`. The sub-agents page adds the same reassurance in its best-practices list: "Keep descriptions brief: Claude Code shows a startup warning when your subagents' combined descriptions pass the 15,000-token limit, and still loads every subagent." (retrieved 2026-09-16)

**Official description example patterns (no `<example>` blocks):**
> "Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code."
> — https://code.claude.com/docs/en/sub-agents (code-reviewer example, retrieved 2026-04-17)

> "Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues."
> — https://code.claude.com/docs/en/sub-agents (debugger example, retrieved 2026-04-17)

> "Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries."
> — https://code.claude.com/docs/en/sub-agents (data-scientist example, retrieved 2026-04-17)

**Note:** Anthropic's own documented examples use **prose descriptions, not `<example>` blocks**. The `<example>` convention with `Context/user/assistant/<commentary>` is a community pattern (see `agent-community-practices.md`). Neither style is officially required; scoring should not penalize the absence of `<example>` blocks when the prose description already conveys trigger conditions clearly. `[custom]` (interpretation of official examples)

**Description voice — third person `[official]`:** The official subagent example descriptions are written in **third person** describing *what the agent does* ("Expert code review specialist. Proactively reviews code…", "Debugging specialist for errors…", "Data analysis expert for SQL queries…"), not second-person instructions to the agent. The official Skills authoring guidance (which governs the same description-discovery mechanism) makes this explicit:
> "Always write in third person. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems."
> — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-05-30)

So the canonical pattern is **third-person description** (routing signal the parent reads) + **second-person body** (the agent's own system prompt: "You are…"). The description should not contain "You are…" / "When invoked, you will…" — that is behavior, and belongs in the body.

### Model Selection `[official]`

**Model resolution order — CHANGED (v2.1.251, updated 2026-09-04):**
1. Per-invocation `model` parameter
2. Subagent definition's `model` frontmatter (`inherit` selects the main conversation's model)
3. `CLAUDE_CODE_SUBAGENT_MODEL` env var (when set to a model alias or ID)
4. Main conversation's model

> "Before v2.1.251, `CLAUDE_CODE_SUBAGENT_MODEL` came first in this order and overrode both the per-invocation parameter and the frontmatter, including `model: inherit`."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

The env var is now a *default*, not an override (changelog v2.1.251: "Fixed `CLAUDE_CODE_SUBAGENT_MODEL` to set the default subagent model rather than override everything"). Scoring implication: a definition's `model:` frontmatter now reliably wins over the environment — do not warn that the env var can silently override it.

**`CLAUDE_CODE_SUBAGENT_MODEL_FORCE` `[official]` (NEW, v2.1.257):**
> "To apply one model to every subagent, also set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` to `1`. Requires Claude Code v2.1.257 or later. If you set both variables, subagents run on the model in `CLAUDE_CODE_SUBAGENT_MODEL`. If you set only `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, subagents run on the main conversation's model."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Details added 2026-09-16 (retrieved 2026-09-16):
- "Setting `CLAUDE_CODE_SUBAGENT_MODEL` by itself doesn't change the model the built-in Explore and Plan subagents run on." The env var applies to *custom* and general-purpose subagents; Explore/Plan keep their own resolution.
- "While `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is on, Claude Code ignores the `model` field of every subagent definition, including the built-in Explore and Plan subagents, and Claude can't pass a model when it starts a subagent." The force switch also reaches agent-team teammates and workflow agents.
- "When you set only `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, the built-in Explore subagent keeps its model cap."
- Observability: "To check which model a subagent is running on, run `/tasks`. Claude Code names the model on the subagent's row, and adds the effort level when the subagent's definition, or the skill it forked from, sets `effort`. Requires Claude Code v2.1.242 or later."

**`availableModels` allowlist interaction (added 2026-08-12) `[official]`:**
> "Claude Code checks the environment variable, per-invocation parameter, and frontmatter values against your organization's `availableModels` allowlist. For a blocked value, it substitutes another model: When the blocked value is a family alias such as `opus`, Claude Code runs the subagent on the newest version of that family the allowlist permits… For any other blocked value, on providers where that substitution doesn't operate, or when the allowlist permits no version of the family, Claude Code runs the subagent on the inherited model instead."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-08-12)

Before v2.1.222, a blocked family alias also fell back to the inherited model rather than stepping down within the family (changelog v2.1.222: "Fixed org-restricted model aliases dropping to parent instead stepping down"). **Scoring implication:** a `model:` value an org allowlist blocks is silently substituted, never an error — do not score `model:` as a hard failure on allowlist grounds, but a family alias (`opus`/`sonnet`/`haiku`) degrades more predictably than a pinned full model ID under org restrictions.

**Current model IDs (2026-09-04) `[official]`:** Claude Opus 5 (`claude-opus-5`) is the default Opus model as of changelog v2.1.219. **Claude Fable 5.1 (`claude-fable-5-1`) is the default Fable model as of changelog v2.1.257** ("Added Claude Fable 5.1 (`claude-fable-5-1`), now the default Fable model — 1M context"). Earlier reference examples used `claude-opus-4-8` / `claude-sonnet-4-6`; those remain valid IDs but are no longer the newest. The docs' own frontmatter example now cites `claude-opus-5` as the full-ID example.

### Tool Restriction `[official]`

> "To restrict tools, use either the tools field (allowlist) or the disallowedTools field (denylist)."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

- If both are set, `disallowedTools` applied first, then `tools` resolved against remaining pool
- `Agent(agent_type)` syntax restricts which subagents can be spawned (main-thread agents only; has no effect inside subagent definitions)
- As of 2.1.63, the Task tool was renamed to `Agent`; `Task(...)` still works as an alias

**Tools unavailable to subagents `[official]` (list updated 2026-09-04):** The first filter removes these tools even when listed in `tools`:
> "`Agent`, when the subagent is at the depth limit; in a fork the tool stays listed but returns an error instead of spawning · `AskUserQuestion` · `EndConversation`, which can end only the main conversation · `EnterPlanMode` · `ExitPlanMode`, unless the subagent's `permissionMode` is `plan` · `ScheduleWakeup` · `TaskOutput` · `WaitForMcpServers` · `Workflow`"
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Changes vs the 2026-05-30 list: `EndConversation`, `TaskOutput`, and `Workflow` added; `Agent` is now removed **only at the depth limit** (below the limit a subagent keeps it and can nest). Listing filtered tools is a no-op (flag in cross-reference checks); "The removal reports no error unless it leaves the `tools` list resolving to nothing."

**Background subagent built-in tool set `[official]` (enumerated 2026-09-04; `SubagentHandback` added 2026-09-16):**
> "Apart from `Agent` and `ExitPlanMode`, which follow the first filter's conditions wherever the subagent runs, a background subagent keeps every MCP tool but only these built-in tools: `Read`, `Grep`, `Glob`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, and `Artifact`, plus `SubagentHandback` for a subagent that reports through it. Claude Code removes every other built-in tool from a background subagent, whether inherited or listed in the `tools` field, so the same definition can resolve to different tools in the foreground and the background. The removal reports no error unless it leaves the `tools` list resolving to nothing."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Forks skip both filters and receive the main conversation's exact tool pool. Agent-team teammates additionally keep `TaskCreate`, `TaskGet`, `TaskList`, `TaskUpdate`, `CronCreate`, `CronDelete`, `CronList`.

**`SubagentHandback` `[official]` (NEW v2.1.271, added 2026-09-16):** an auto-mode-only report channel that Claude Code injects regardless of the `tools` list:
> "Delivers a subagent's final report to whichever conversation receives that subagent's result. Provided only in auto mode, to subagents that the Agent tool runs locally other than forks, and available in the terminal CLI, IDE extensions, cloud sessions, and the Agent SDK; the classifier reviews the report before it's delivered. Requires Claude Code v2.1.271 or later"
> "Where the conditions in the `SubagentHandback` tools-table entry hold, Claude Code also gives the subagent that tool, even if you leave it out of `tools` or list it in `disallowedTools`."
> — https://code.claude.com/docs/en/tools-reference (retrieved 2026-09-16)

Changelog v2.1.273: "Changed auto mode so a subagent reports back to its caller through a dedicated hand-back call that the safety classifier reviews, instead of its last message being reviewed after the fact". Reviewer implication: listing or denying `SubagentHandback` in frontmatter is a no-op; a body that tells the agent to "end with a final report" is fine — that report is what the classifier reviews.

**Zero-resolvable-tools refusal — exact rules `[official]` (errors reference, added 2026-09-16):**
> "Every entry in the subagent's `tools` list failed to match a usable tool, so Claude Code refused to launch the subagent: with no tools, it couldn't act. The message groups your entries by what went wrong:
> - **Unrecognized**: the entry matches no tool name, usually a typo such as `Grpe` for `Grep`.
> - **Not available to subagents**: the entry names a real tool that subagents can't use. Background subagents keep a smaller built-in tool set, so an entry that only a foreground subagent can use lands here when the subagent would run in the background, which is the default. If you list `Agent`, the message reports it under the next group instead.
> - **Matched no tools in this session**: the entry is valid but no tool in the current session matches it right now, such as `mcp__github__*` with no GitHub MCP server connected, or `Agent` for a subagent at the depth limit.
> Omitting the `tools` field never triggers this refusal. If you leave the `tools` list empty, or `disallowedTools` removes every entry in it, Claude Code also skips the refusal and launches the subagent without tools."
> — https://code.claude.com/docs/en/errors (retrieved 2026-09-16)

Sample error: `Agent 'code-reviewer' would be spawned with zero tools — refusing. Its tools list resolved to nothing: unrecognized [Grpe]. Fix the agent's tools frontmatter or pass a different subagent_type.` Two reviewer consequences: (1) a `tools` list made only of foreground-only built-ins (the docs' example is `LSP`) refuses in the default background case; (2) an **empty** `tools:` list is *worse* than a wrong one — it launches a tool-less agent with no error at all.

**Task-tracking tools are model-gated `[official]` (changelog v2.1.268–v2.1.271 — two retrievals placed the entry under different versions; added 2026-09-16):**
> "The task-tracking tools, `TaskCreate`, `TaskGet`, `TaskUpdate`, `TaskList`, and `TodoWrite`, are available by default only on Claude 3.x models, Opus 4 through 4.7, Sonnet 4 through 4.6, and Haiku 4.5."
> — https://code.claude.com/docs/en/tools-reference (retrieved 2026-09-16)

Changelog (Sep 2026): "Changed the task-tracking tools (TaskCreate/Get/Update/List, TodoWrite) to be offered only on Claude 3.x, Opus 4.0–4.7, Sonnet 4.0–4.6, Haiku 4.5; set `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` elsewhere". On a Claude 5-family model (`opus`, `sonnet`, `fable` aliases, `claude-opus-5`, `claude-fable-5-1`) a `tools: TodoWrite` entry resolves to "matched no tools in this session" unless the env var is set — harmless alongside other tools, but a refusal if it is the only entry.

**`disallowedTools` specifiers remove the whole tool `[official]` (added 2026-09-16):**
> "A `disallowedTools` entry with a specifier, such as `Bash(git push *)`, still removes the whole tool from the subagent, not only the matching commands. To keep Bash and block specific commands, add a Bash deny rule such as `Bash(git push *)` to `permissions.deny` in your settings. The rule applies to the main conversation and to subagents."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

An author who writes `disallowedTools: Bash(git push *)` intending "Bash minus git push" gets "no Bash". The command-level lever lives in `settings.json` `permissions.deny`, not in agent frontmatter.

**Official guidance for read-only/reviewer agents `[official]`:**
> "For a read-only reviewer, deselect everything except Read-only tools."
> — https://code.claude.com/docs/en/sub-agents (quickstart, retrieved 2026-04-17)

Canonical tool sets seen in the official example agents:
- code-reviewer (read-only): `Read, Grep, Glob, Bash`
- debugger (can fix): `Read, Edit, Bash, Grep, Glob`
- data-scientist (writes output): `Bash, Read, Write`
- db-reader (Bash gated by hook): `Bash`

### Preloading Skills `[official]`

> "Use the skills field to inject skill content into a subagent's context at startup. This gives the subagent domain knowledge without requiring it to discover and load skills during execution."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**Clarified (2026-06-10, supersedes earlier "don't inherit skills" wording):** the `skills` field controls *preloading*, not access.
> "The full content of each listed skill is injected into the subagent's context at startup. This field controls which skills are preloaded, not which skills the subagent can access: without it, the subagent can still discover and invoke project, user, and plugin skills through the Skill tool during execution."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

> "You cannot preload skills that set `disable-model-invocation: true`, since preloading draws from the same set of skills Claude can invoke. If a listed skill is missing or disabled, Claude Code skips it and logs a warning to the debug log."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

To prevent a subagent from invoking skills entirely, omit `Skill` from `tools` or add it to `disallowedTools`. To preload Skills, use the `skills` field rather than listing `Skill` in `tools`.

### Persistent Memory `[official]`

| Scope | Location | Use when |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge applies across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not in VCS |

> "project is the recommended default scope."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**What `memory` injects and enables `[official]` (added 2026-09-16):**
> "When memory is enabled:
> - The subagent's system prompt includes instructions for reading and writing to the memory directory.
> - The subagent's system prompt also includes the first 200 lines or 25KB of `MEMORY.md` in the memory directory, whichever comes first, with instructions to curate `MEMORY.md` if it exceeds that limit.
> - Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory files."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Reviewer implication: `memory:` silently widens the tool pool. A "read-only" reviewer with `tools: Read, Grep, Glob` plus `memory: project` *does* have `Write` and `Edit` at runtime; the least-privilege intent in `tools` is not what runs. Not a defect on its own (the docs define it), but worth an advisory note on read-only agents.

### Built-in Subagents `[official]`

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only | File discovery, code search |
| Plan | Inherits | Read-only | Codebase research for planning |
| General-purpose | Inherits | All | Complex multi-step tasks |
| statusline-setup | Sonnet | — | `/statusline` configuration |
| claude-code-guide | Haiku | — | Claude Code feature Q&A |

### What Loads at Startup `[official]` (NEW 2026-06)

A non-fork subagent's initial context contains: system prompt (agent's own prompt + environment details, **not** the full Claude Code system prompt), the delegation/task message, CLAUDE.md and memory hierarchy, a git status snapshot from the parent session start, and preloaded skills (`skills` field).

> "Explore and Plan skip your CLAUDE.md files and the parent session's git status to keep research fast and inexpensive. Every other built-in and custom subagent loads both."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

> "Explore and Plan are the only subagents that omit CLAUDE.md and git status. There is no frontmatter field or per-agent setting to change which agents skip them."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

Implication: if a CLAUDE.md rule must reach an Explore/Plan delegation (e.g. "ignore `vendor/`"), restate it in the delegation prompt.

**Correction (2026-09-16) — CLAUDE.md now has a per-agent opt-out; git status still does not.** The 2026-06 "no frontmatter field" sentence is superseded for CLAUDE.md by `omitClaudeMd` (v2.1.271):
> "**CLAUDE.md files**: every level of the CLAUDE.md hierarchy the main conversation loads, including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, and managed policy files. The built-in Explore and Plan agents skip this. A subagent whose definition sets `omitClaudeMd` loads only the managed policy files, or none at all when the definition comes from managed settings."
> "You can't change which subagents receive git status. Only Explore and Plan skip it."
> "The main conversation still has your full CLAUDE.md when it reads these subagents' results, so most rules don't need to reach the subagent itself. If a rule must, such as 'ignore the `vendor/` directory,' restate it in the prompt you give Claude when delegating."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Additional startup facts recorded 2026-09-16 (same page): the **sibling roster** is "a snapshot taken when the subagent starts, so agents named later don't appear"; and three things never reach a non-fork subagent — "**Output style**: a subagent runs its own system prompt, so your output style doesn't shape its responses, except in a fork"; "**Auto memory**: the main conversation's auto memory isn't loaded. To give a subagent persistent memory of its own, use the `memory` field"; "**Context window size**: a subagent's context window is sized by its own model, not the parent's. Delegating to a model with a smaller window gives that subagent the smaller window."

Reviewer implication of `omitClaudeMd: true`: the body must be self-sufficient. A body that says "follow the conventions in CLAUDE.md" or relies on project rules it never restates contradicts its own frontmatter.

### Resuming Subagents `[official]` (NEW 2026-06; updated 2026-09-04)

Subagents can be resumed with full prior conversation history. Claude uses the `SendMessage` tool with the agent's ID **or name** as the `to` field.

**Correction (2026-09-04) — SendMessage no longer requires agent teams:**
> "`SendMessage` doesn't require agent teams to be enabled; only structured team-protocol messages such as `shutdown_request` and `plan_approval_response` do."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

This supersedes the 2026-06 note that resuming needed `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Additional current behavior (retrieved 2026-09-04):
- "Claude can give a subagent a name by passing a `name` parameter on the Agent tool call… The name makes the subagent addressable: Claude can message or resume it by name after it finishes."
- "A completed subagent that receives a `SendMessage` auto-resumes in the background without a new `Agent` invocation."
- v2.1.199+: `SendMessage` refuses delivery when a newer agent has taken the name, reporting which agent the name now reaches.
- v2.1.206+: subagents whose tools include `SendMessage` receive a **sibling roster** system reminder listing `main` and every other named agent, when at least one other agent has a name.
- Agent teams: "In an interactive session with agent teams enabled, a subagent that Claude spawns from the main conversation with a `name` launches as a teammate instead, unless the call is a fork or passes `isolation` on the call itself."
- `maxTurns` interplay: "When a subagent stops at its `maxTurns` limit, Claude Code marks the returned output as partial… Claude can message the subagent to continue from where it stopped." (partial marking v2.1.246+)
> "The built-in Explore and Plan agents are one-shot and return no agent ID, so they can't be resumed; use `general-purpose` or a custom subagent when you need to continue the work."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

Transcripts persist at `~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`, independent of main-conversation compaction; cleaned up per `cleanupPeriodDays` (default 30 days).

### Best Practices `[official]`

> "Design focused subagents: each subagent should excel at one specific task."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Write detailed descriptions: Claude uses the description to decide when to delegate."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Limit tool access: grant only necessary permissions for security and focus."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Check into version control: share project subagents with your team."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### System Prompt Style (inferred from official examples) `[official]`

All four documented example agents (code-reviewer, debugger, data-scientist, db-reader) share the same structural pattern:

1. **Identity opener in second person** — "You are a senior code reviewer ensuring high standards of code quality and security."
2. **"When invoked:"** numbered action sequence (3–5 steps)
3. **Domain checklist / key practices** — bullet list of concerns or techniques
4. **Output format** — explicit list of sections or priority labels (Critical / Warnings / Suggestions)
5. **Closing focus statement** — single-sentence priority reminder (e.g., "Focus on fixing the underlying issue, not the symptoms.")

Second person (`You are`, `When invoked`, `Focus on`) is used universally; no first- or third-person voice appears in any official example.
— https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### When to Use Subagents vs Main Conversation `[official]`

**Use main conversation when:**
- Task needs frequent back-and-forth
- Multiple phases share significant context
- Making quick targeted changes
- Latency matters

**Use subagents when:**
- Task produces verbose output
- Want to enforce specific tool restrictions
- Work is self-contained and can return a summary

> "Consider Skills instead when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Invocation Patterns `[official]`

Three escalation levels:
- **Natural language** — name the subagent in your prompt; Claude decides whether to delegate
- **@-mention** — `@"code-reviewer (agent)"` or `@agent-<name>`; guarantees that subagent runs for one task
- **Session-wide** — `claude --agent <name>` or `"agent"` in `.claude/settings.json` replaces the default Claude Code system prompt entirely

Plugin agents are addressed as `@agent-<plugin-name>:<agent-name>`.

### Hooks in Subagents `[official]`

Subagent-specific hooks in frontmatter:
- `PreToolUse`: Before tool use
- `PostToolUse`: After tool use
- `Stop`: When subagent finishes (converted to `SubagentStop` at runtime)

> "Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention, and when the agent runs as the main session via `--agent` or the `agent` setting. In the main-session case they run alongside any hooks defined in settings.json."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

**Correction (2026-06-10):** earlier docs (retrieved 2026-04-17) said frontmatter hooks "do not fire when the agent runs as the main session via --agent". Current official docs state the opposite — they now DO fire in the main-session case. Official wins; reviewers should not flag main-session hook reliance as broken.

Project-level hooks in `settings.json`:
- `SubagentStart`: When subagent begins
- `SubagentStop`: When subagent completes

### Plugin Subagent Restrictions `[official]`

> "For security reasons, plugin subagents do not support the hooks, mcpServers, or permissionMode frontmatter fields."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

`omitClaudeMd` (v2.1.271) is explicitly supported for plugin subagents ("letting custom and plugin subagents run without…").

### Permission Modes `[official]` (NEW section 2026-09-16)

The full section is now on the sub-agents page (retrieved 2026-09-16):
> "Set `permissionMode` to choose the permission mode a subagent runs in. Use the modes' config values, so Manual mode is `default`. If you leave it unset, the subagent inherits the main conversation's mode, which starts as auto mode on Pro, Max, and Team plans unless your settings or your organization change it."
> "When the main conversation is in `bypassPermissions`, `acceptEdits`, or auto mode, the subagent runs in that same mode and Claude Code ignores the `permissionMode` you set. Under auto mode, the classifier evaluates the subagent's tool calls with the main conversation's block and allow rules. When the subagent finishes, the classifier also reviews its work and its final report before the report is delivered"
> "When the main conversation is in `default`, `dontAsk`, or `plan` mode, the subagent runs in the permission mode you set, except `bypassPermissions`. A subagent that declares `bypassPermissions` keeps the main conversation's mode instead. The `bypassPermissions` exception requires Claude Code v2.1.267 or later."
> `bypassPermissions` table row: "Skip permission prompts. A subagent runs in this mode only when the main conversation does"
> `dontAsk` table row: "Auto-deny permission prompts. Explicitly allowed tools still work; `AskUserQuestion`, MCP tools marked `requiresUserInteraction`, and connector tools your organization set to `ask` in sessions where that setting reaches Claude Code are denied even if you've allowed them"

Net effect for reviewers: **`permissionMode: bypassPermissions` in a subagent definition is never an escalation.** If the parent is in bypass it is redundant; otherwise it is ignored (v2.1.267+). This generalizes the v2.1.223 org-policy fix. Since Pro/Max/Team sessions start in auto mode, in the common case the frontmatter `permissionMode` is ignored entirely and the classifier governs the subagent. `permissionMode` only takes effect when the parent is in `default`/`dontAsk`/`plan`.

### Subagent Definitions as Agent-Team Teammates `[official]` (NEW section 2026-09-16)

Agent teams (still experimental, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) can spawn a teammate from a subagent definition, but only *parts* of the file apply — and which parts depends on display mode:
> "- **`tools`**: Claude Code limits the teammate to the tools in the definition's `tools` list. For an in-process teammate, Claude Code adds `SendMessage` to that list, and in a session that has the Task tools it adds `TaskCreate`, `TaskGet`, `TaskList`, and `TaskUpdate` too.
> - **`model`**: Claude Code uses the definition's `model` in either display mode when your spawn prompt doesn't name one.
> - **Body**: for an in-process teammate, Claude Code appends the definition's body to its default system prompt as additional instructions. For a split-pane teammate, Claude Code uses the body in place of its default system prompt.
> - **`skills`**: Claude Code doesn't apply the definition's `skills` to a teammate in either display mode. The teammate loads skills from your project and user settings.
> - **`mcpServers`**: for a split-pane teammate, Claude Code applies the definition's `mcpServers` under the rules for that field, which cover a session started with `--agent` as well. An in-process teammate ignores the field and loads MCP servers from your project and user settings."
> — https://code.claude.com/docs/en/agent-teams (retrieved 2026-09-16)

Also: "Teammates start with the lead's permission mode, except `dontAsk` mode, which they don't inherit"; teammates load CLAUDE.md, MCP servers, and skills like a regular session (so `omitClaudeMd` is a subagent-only lever). Changelog v2.1.267/268 (placement differed between retrievals): "Fixed a respawned in-process teammate picking up tools or a system prompt from a same-named agent file in a folder you have not trusted". Reviewer implication: an agent file that is reused as a teammate role should not depend on `skills` preloading or on `permissionMode`/`hooks`; put that knowledge in the body.

### Headless: `--append-subagent-system-prompt` `[official]` (NEW 2026-09-16)

> "In non-interactive mode, pass `--append-subagent-system-prompt` to append your text to the end of every subagent's system prompt, nested subagents included, apart from a forked subagent, which reuses the conversation's own prompt. Requires Claude Code v2.1.205 or later. If your text is too long to pass on the command line, save it to a file and pass the path with `--append-subagent-system-prompt-file` instead. The file flag requires Claude Code v2.1.261 or later."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Reviewer note: in `-p`/SDK harnesses, the markdown body is not necessarily the *entire* system prompt — a harness-wide suffix may follow it. Body text that assumes it is the last word ("ignore any instructions after this") is fragile.

### Foreground vs Background; Permission Surfacing `[official]` (added 2026-06-26)

> "Foreground subagents block the main conversation until complete. Permission prompts are passed through to you as they come up. Background subagents run concurrently while you continue working. As of v2.1.186, when a background subagent reaches a tool call that needs permission, the prompt surfaces in your main session and names the subagent that is asking. Approve to let the subagent continue, or press Esc to deny that one tool call without stopping the subagent. Before v2.1.186, background subagents auto-denied any tool call that would have prompted."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

Implication for reviewers: an agent with `background: true` is no longer at risk of silent auto-deny on permission prompts (since v2.1.186). Ctrl+B backgrounds the running task; `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` disables background entirely.

**Foreground/background decision logic `[official]` (updated 2026-09-04):** Claude Code picks from the first matching case:
> "If an in-process agent team teammate spawned the subagent, Claude Code runs it in the foreground… If you set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` to `1`, Claude Code runs the subagent in the foreground… Where fork mode is on, as it is by default in an interactive session, Claude Code runs the subagent in the background, forks and non-fork subagents alike, and Claude can't ask for the foreground. Where fork mode is off, Claude runs the subagent in the background by default and in the foreground when it needs the result before continuing. Fork mode is off in non-interactive mode with `-p` and in the Agent SDK unless you turn it on."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Since fork mode is on by default in interactive sessions, **in practice every interactively spawned subagent runs in the background** — the background tool-set narrowing (see Tool Restriction) is the normal case, not the exception. `background: true` now means "keep in background even when Claude wants the result in the foreground". Also: "Removed the one-hour time limit on background commands started by subagents; they now run until they exit or are stopped" (changelog v2.1.260).

**Fork mode details `[official]` (added 2026-09-16):**
> "Claude Code turns fork mode on by default in interactive sessions and leaves it off by default in non-interactive mode with `-p` and in the Agent SDK. The interactive default requires Claude Code v2.1.232 or later. On earlier versions, set `CLAUDE_CODE_FORK_SUBAGENT` to `1` to turn fork mode on."
> "Claude Code runs the subagents Claude spawns in the background, forks and non-fork subagents alike, apart from the cases that stay in the foreground. Claude Code also removes the Agent tool's `run_in_background` parameter, so Claude can't ask for the foreground."
> "`1` turns fork mode on in non-interactive mode and the Agent SDK as well · `0` turns fork mode off in every kind of session"
> "To keep fork mode on but stop Claude from spawning forks, deny the `fork` subagent type with an `Agent(fork)` rule."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Teammate-spawned subagents: "If an in-process agent team teammate spawned the subagent, Claude Code runs it in the foreground. Claude Code refuses with an error to spawn a teammate's subagent whose definition sets `background: true`." So `background: true` is a hard error in exactly one context — a definition intended for use *from* a teammate must not set it.

### MCP Server Restrictions on Subagent-Inline Servers `[official]` (added 2026-06-26)

As of v2.1.153, the MCP restrictions that apply to the main session also cover servers declared in subagent `mcpServers` frontmatter:
- `--strict-mcp-config` and `--bare`
- Enterprise managed MCP configuration
- `allowedMcpServers` and `deniedMcpServers` policies

When one of these blocks a server, Claude Code skips it and shows a warning naming the blocked servers. Note: `--strict-mcp-config` does **not** filter servers passed inline via `--agents` JSON or the SDK `agents` option (those are explicit caller input).

> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

### Working Directory and `isolation: worktree` Enforcement `[official]` (consolidated 2026-09-16)

> "A subagent starts in the main conversation's current working directory. Within a subagent, `cd` commands don't persist between Bash or PowerShell tool calls and don't affect the main conversation's working directory."
> "A subagent with `isolation: worktree` runs its Bash and PowerShell commands inside its worktree. A command whose working directory resolves to your main checkout instead, for example because the worktree directory was removed while the subagent was running, fails with an error. Before v2.1.203, such a command could run in the main checkout."
> "For Bash commands, Claude Code also checks the command itself in two ways: It blocks a command that redirects git into the main checkout. It refuses a command when it can't verify from the command text that any git the command runs stays inside the worktree, for example when the command name is computed at runtime… PowerShell commands get only the working-directory check."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-16)

Two reviewer facts: (1) a body that chains `cd somewhere` in one Bash call and expects it to persist in the next call is wrong for *every* subagent, not only worktree ones; (2) in a worktree agent, dynamically constructed git invocations (`$CMD status`, `eval`, `xargs git …` in some shapes) are refused outright, not merely checked. Also: "An `isolation` value in the subagent's frontmatter doesn't prevent" a named spawn from becoming a teammate when agent teams are on, "and the teammate then runs in the main session's working directory".

### Auto-Compaction `[official]`

> "Subagents support automatic compaction using the same logic as the main conversation. By default, auto-compaction triggers at approximately 95% capacity."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Nesting Limit `[official]`

> "Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**Correction (2026-06-26, changelog v2.1.172, 2026-06):** Nested subagent spawning is now allowed up to depth 5.
> "As of Claude Code v2.1.172, a subagent can spawn its own subagents… A subagent at depth five does not receive the Agent tool and cannot spawn further. The limit is fixed and not configurable."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

**Correction (2026-08-12, changelog v2.1.219, 2026-08) — SUPERSEDES the depth-5 figure:**
> "Subagents can spawn nested subagents up to depth 3 by default"
> — https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md, v2.1.219 (retrieved 2026-08-12)

The default budget is now **depth 3**, not 5. Scoring implication: an agent designed around a 4- or 5-level delegation chain is relying on a budget that no longer exists by default. Depth-based deductions remain out of scope for file-level review (the limit is the platform's), but do not cite "depth 5" as the current cap.

**Depth is now configurable `[official]` (added 2026-09-04):**
> "To change the limit, set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to the number of subagent layers you want below your main conversation… Set `1` to turn nesting off."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Version history per the docs: v2.1.172–v2.1.216 defaulted to 5 (not configurable); v2.1.217–v2.1.218 defaulted to 1; v2.1.219+ defaults to 3 (configurable). At the depth limit "Claude Code withholds the `Agent` tool from every subagent except a fork".

**Concurrent subagent limit `[official]` (added 2026-09-04, v2.1.217+):**
> "By default, when 20 subagents are running in a session, spawning another with the Agent tool fails with `Concurrent subagent limit reached`, and the error tells Claude not to retry. To change the limit, set `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` to any positive whole number."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Note the distinction: the per-session *total* spawn cap (200) was removed in v2.1.224, but a *concurrent* cap of 20 exists — relevant only to orchestrators that fan out very wide in parallel. Added 2026-09-16: "Sessions with ultracode active are exempt: the limit isn't enforced there." (retrieved 2026-09-16). Changelog v2.1.269: "Improved nested background subagent results to be saved in the parent subagent's transcript, so resumed subagents keep them and shared transcripts show the delivery".

**Per-session spawn cap removed (changelog v2.1.224, 2026-08):**
> "Removed 200-subagent-per-session spawn cap; long-running sessions no longer refuse agents"
> — https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md, v2.1.224 (retrieved 2026-08-12)

- A fork still cannot spawn another fork; it can spawn other subagent types and those count toward the depth limit.
- As of v2.1.187, a background subagent's depth is fixed at first spawn; resuming it later from a shallower context does not let it spawn additional levels.
- To prevent a specific subagent from spawning others, omit `Agent` from its `tools` list or add it to `disallowedTools`.
- The subagent panel shows the full tree (`(+N)` count per row); `/agents` Running tab lists them flat.

### Forked Subagents `[official]`

New as of v2.1.117 (env var `CLAUDE_CODE_FORK_SUBAGENT=1`). **From v2.1.161 the `/fork` command is enabled by default**; making forks the model's *default* spawn behavior remains experimental ("Forked subagents require Claude Code v2.1.117 or later. From v2.1.161 the /fork command is enabled by default" — retrieved 2026-06-10). A **fork** is a subagent that inherits the *entire conversation so far* instead of starting fresh — same system prompt, tools, model, and message history as the main session.

> "A fork is a subagent that inherits the entire conversation so far instead of starting fresh. This drops the input isolation that subagents otherwise provide… Use a fork when a named subagent would need too much background to be useful, or when you want to try several approaches in parallel from the same starting point."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-05-30)

Forks vs named subagents: a fork has full conversation history, shares the main session's prompt cache (cheaper), and surfaces permission prompts in the terminal; a named subagent starts from its own definition with fresh context and a separate cache. Forks cannot spawn further forks. Not authored as `.md` files — relevant context for reviewers, not a new agent-file shape.

### CLI-defined subagents (`--agents` JSON) `[official]`

Subagents can be passed as JSON at launch via `--agents`, session-only and never written to disk. The JSON accepts the same fields as file frontmatter (`description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `hooks`, `maxTurns`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `isolation`, `color`) plus `prompt` — the JSON equivalent of the markdown body (the system prompt).
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-05-30)

---

## Changelog

- 2026-03-29: Skeleton created
- 2026-03-30: Populated with official documentation from code.claude.com/docs/en/sub-agents. Added: subagent definition, frontmatter reference (all 15 fields), scope/priority table, description/triggering guidance, model resolution order, tool restriction (allowlist/denylist/Agent syntax), skill preloading, persistent memory (3 scopes), built-in subagents, best practices (4 principles), when-to-use guide, hooks (frontmatter + settings.json), plugin restrictions, auto-compaction.
- 2026-04-17: Refreshed from 2026-04-17 retrieval of code.claude.com/docs/en/sub-agents. Corrections: `color` palette updated to `red | blue | green | yellow | purple | orange | pink | cyan` (removed `magenta`, added `purple/orange/pink`). `effort` levels now include `xhigh`. Added managed-settings scope (priority 1) and updated scope table to 5 tiers. Added `auto` to `permissionMode` values. Noted `Task → Agent` rename (2.1.63). Added quoted guidance that official examples use **prose descriptions, not `<example>` blocks** — flagged as scoring implication. Added canonical tool sets for the 4 documented example agents, the 5-part system-prompt structural pattern, invocation-pattern escalation, nesting limit, and `initialPrompt` behavior notes.
- 2026-05-30: Refreshed from 2026-05-30 retrieval of code.claude.com/docs/en/sub-agents + Skills authoring best-practices doc. Material additions: (1) **Description voice — third person** rule, sourced from the official Skills best-practices ("Always write in third person…") and confirmed by all official subagent description examples; canonical pattern is third-person description + second-person body. (2) `name` does not have to match filename; identity is from `name` only (cross-reference implication). (3) Model ID examples bumped to `claude-opus-4-8` / `claude-sonnet-4-6`. (4) **Tools unavailable to subagents** list (`Agent`, `AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode`, `ScheduleWakeup`, `WaitForMcpServers`) — listing them is a no-op. (5) New **forked subagents** (experimental, v2.1.117) and **`--agents` CLI JSON** (`prompt` field) sections. Frontmatter field list, scope table, hooks, plugin restrictions, nesting, auto-compaction all re-verified unchanged.
- 2026-06-10: Refreshed from 2026-06-10 retrieval of code.claude.com/docs/en/sub-agents. Scoring-relevant changes: (1) **`fable` is now a valid model alias** (`sonnet | opus | haiku | fable`) — do not flag as invalid. (2) **Hooks correction**: frontmatter hooks now ALSO fire when the agent runs as the main session via `--agent` / `agent` setting (official docs reversed the 2026-04 wording; conflict noted, official wins). (3) New **What Loads at Startup** section: Explore/Plan skip CLAUDE.md + parent git status, no opt-out field; all other subagents load both. (4) **Recursive scanning + name uniqueness**: agents dirs scanned recursively; duplicate `name` within one scope → one file silently discarded; plugin subfolders join the scoped ID (`my-plugin:review:security`). (5) `skills` preload clarified — controls preloading, not access (supersedes "don't inherit skills" wording); skills with `disable-model-invocation: true` cannot be preloaded (skipped + debug-log warning). (6) `permissionMode` behaviors detailed (`auto` classifier, `dontAsk` auto-deny, parent-precedence rules). (7) `/fork` enabled by default from v2.1.161. (8) New **Resuming Subagents** section (SendMessage + agent ID; Explore/Plan are one-shot, no ID). (9) Load timing: file-on-disk agent edits need session restart; `/agents`-created agents take effect immediately.
- 2026-06-26: Refreshed from 2026-06-26 retrieval of code.claude.com/docs/en/sub-agents + changelog through v2.1.193. **Material additions**: (1) **Nesting Limit superseded** (changelog v2.1.172): subagents CAN now spawn nested subagents up to depth 5; a depth-5 agent does not receive the Agent tool. Forks count toward the limit but cannot spawn other forks. v2.1.187 fixes background subagent depth at first spawn (resuming from a shallower context does not reset). (2) **Foreground vs Background + permission surfacing** (changelog v2.1.186): background subagents no longer auto-deny permission prompts — they surface in the main session, named, with approve/Esc options. (3) **MCP restrictions on subagent-inline `mcpServers`** (v2.1.153): `--strict-mcp-config`, managed MCP config, and `allowedMcpServers`/`deniedMcpServers` now also filter servers declared in subagent frontmatter; blocks are warned. `--strict-mcp-config` exempts `--agents` JSON and SDK-passed agents. (4) **Nested project agents tie-break** (v2.1.178): when nested project `.claude/agents/` along the cwd walk define the same `name`, the closest-to-cwd definition wins (different from the within-one-scope silent-discard rule). (5) **`--add-dir` scans `.claude/agents/` inside the added directory** as project subagents. (6) Spawn-nested-subagent fix v2.1.181 prevented unbounded nested chains (5-level limit enforced). All other content re-verified unchanged. last_updated bumped to 2026-06-26.
- 2026-07-25: Refreshed against code.claude.com/docs/en/sub-agents (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **Material additions**: (1) **Background is now the default** (v2.1.198) - Claude runs a subagent in the foreground only when it needs the result before continuing, and background subagents get a **smaller built-in tool set** than foreground ones; forks are exempt from both filters. (2) **Zero-resolvable-tools now refuses to launch** (v2.1.208), returning an error naming the unresolved entries. (3) **`/agents` wizard removed** (v2.1.198) - the command prints a reminder to ask Claude or edit `.claude/agents/` directly; files, frontmatter, and locations unchanged. (4) **`permissionMode: manual`** added as an alias for `default` (v2.1.200). (5) **Subagents inherit extended thinking** from the main conversation (v2.1.198); no per-subagent field. (6) **Explore inherits the main model** instead of always Haiku (v2.1.198), capped at Opus on the Claude API; `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1` removes the built-in Explore/Plan agents. (7) **`isolation: worktree` hardening** - the working-directory check now covers the whole containing repository (v2.1.210) and, for Bash, the command text itself is checked for git redirects into the main checkout (v2.1.216). (8) **`/doctor` reports duplicate agent names** in the same directory and proposes renaming or removing all but one (v2.1.205). (9) **`skills` preload exclusion extended** to the bundled `/verify` and `/code-review`, which only the user can run (v2.1.215). (10) Per-invocation `model` now survives resume/follow-up (v2.1.211); `CLAUDE_CODE_SUBAGENT_MODEL=inherit` is equivalent to unset (v2.1.196). (11) `SendMessage` name-reuse guard (v2.1.199) and sibling-roster system reminder (v2.1.206). (12) Forked-subagent command is now `/subtask` (v2.1.212); `/fork` copies the session into a background session. Frontmatter field table re-verified in full - `initialPrompt`, `isolation`, `effort`, `memory`, `maxTurns`, `mcpServers`, `hooks`, `background`, `disallowedTools`, `skills` all current. last_updated bumped to 2026-07-25.
- 2026-08-12: Refreshed against code.claude.com/docs/en/sub-agents (retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. **Material corrections**: (1) **Nesting depth is now 3 by default** (v2.1.219: "Subagents can spawn nested subagents up to depth 3 by default") - supersedes the depth-5 figure recorded 2026-06-26. (2) **200-subagent-per-session spawn cap removed** (v2.1.224). (3) **`availableModels` allowlist substitution documented**: a blocked family alias steps down to the newest permitted version of that family (v2.1.222 fixed it dropping to the parent model instead); any other blocked value falls back to the inherited model. Blocked `model:` values are substituted silently, never an error. (4) **Claude Opus 5 (`claude-opus-5`) is the default Opus model** (v2.1.219); prior `claude-opus-4-8` / `claude-sonnet-4-6` examples remain valid but are not newest. (5) **`permissionMode: bypassPermissions` in an agent definition no longer overrides org policy** (v2.1.223). (6) `permissionMode: manual` alias added to the frontmatter table. (7) v2.1.223 adds a warning when a workflow agent's requested subagent model is org-restricted and the parent model runs instead. (8) v2.1.222 fixed worktree-isolated subagents running destructive git against the main checkout, and fixed the spinner showing the session's effort label instead of the subagent's own. (9) v2.1.225 adds a workspace-trust prompt to `claude agents` for untrusted directories. Frontmatter field table, scope/priority table, tool-filter rules, skills preload, memory scopes, hooks, and plugin restrictions all re-verified unchanged. last_updated bumped to 2026-08-12.
- 2026-09-04: Refreshed against code.claude.com/docs/en/sub-agents (retrieved 2026-09-04) + changelog v2.1.229-v2.1.260. **Material additions**: (1) **`name` cannot contain `:`** (reserved for plugin scopes) — the file is not loaded and an error goes to the debug log (behavior since v2.1.218, now documented). (2) **New `experimental` frontmatter field** with `cacheTtl: 5m|1h` per-agent prompt-cache TTL (v2.1.248). (3) **Combined description budget: 15,000 tokens** — startup warning when custom subagent descriptions together exceed it; official guidance to keep descriptions short and move detail into the body. (4) **Model resolution order changed** (v2.1.251): per-invocation > frontmatter > `CLAUDE_CODE_SUBAGENT_MODEL` > main model — the env var is now a default, not an override; new `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (v2.1.257) restores force semantics. (5) **Tools-unavailable list updated**: `EndConversation`, `TaskOutput`, `Workflow` added; `Agent` removed only at the depth limit; background built-in tool set now explicitly enumerated (19 tools; forks exempt; teammates keep task/cron tools). (6) **Nesting depth configurable** via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (default 3; `1` disables nesting); **concurrent subagent limit 20** via `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (v2.1.217+). (7) **SendMessage no longer requires agent teams** for resume/messaging (supersedes 2026-06 note); auto-resume on message; name-identity guard (v2.1.199); sibling roster (v2.1.206); named spawns become teammates when teams are on. (8) **`maxTurns` output marked partial + resumable** (v2.1.246). (9) **UTF-8 BOM agent files were silently ignored before v2.1.239** — flag BOMs in checked-in files. (10) `isolation: worktree` branches from the **default branch**, not parent HEAD; auto-cleanup when unchanged; v2.1.257 reduced false Bash refusals (loops/xargs/wrappers). (11) Fork-mode background default: interactively spawned subagents effectively always run in the background; background command 1-hour limit removed (v2.1.260). (12) Claude Fable 5.1 (`claude-fable-5-1`) default Fable model (v2.1.257); `/cd` now hot-reloads the new directory's agents (v2.1.243). last_updated bumped to 2026-09-04.
- 2026-09-16: Refreshed against code.claude.com/docs/en/sub-agents, /errors, /agent-teams, /tools-reference (all retrieved 2026-09-16) + changelog v2.1.261-v2.1.273 (newest 2.1.273, 2026-09-15). **Material additions/corrections**: (1) **Hot reload — CORRECTION**: Claude Code now watches `~/.claude/agents/` and `.claude/agents/` and picks up edits within seconds; the 2026-06 "restart your session" note is superseded. Three cases still need a restart (first file in a new `agents` dir, `--add-dir`/`/add-dir` dirs, `--disable-slash-commands`). (2) **New `omitClaudeMd` frontmatter field** (v2.1.271): subagent skips user/project/local CLAUDE.md (managed policy still loads); works for plugin subagents and `--agents` JSON; ignored for `--agent` main-session use. Supersedes the 2026-06 "no frontmatter field" sentence for CLAUDE.md (git status still has no opt-out). (3) **New "Subagent files Claude Code skips" list**: no `name` (treated as docs), `---` not on line 1, `name` starting with `-` or containing `:`, `name` without `description`, unparseable YAML — all silent, debug log only. (4) **`disallowedTools` specifiers** (`Bash(git push *)`) remove the whole tool; command-level denies belong in `settings.json` `permissions.deny`. (5) **Zero-tools refusal exact rules** (errors page): three failure groups (unrecognized / not available to subagents incl. background-dropped tools / matched nothing this session incl. disconnected MCP and `Agent` at depth limit); an **empty** `tools` list launches tool-less with no refusal. (6) **Task-tracking tools model-gated** (changelog v2.1.268–271): `TodoWrite`/`TaskCreate`… offered only on Claude 3.x, Opus 4.0–4.7, Sonnet 4.0–4.6, Haiku 4.5 unless `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`. (7) **`SubagentHandback`** (v2.1.271): auto-mode-only report tool injected regardless of `tools`/`disallowedTools`; added to the background set; v2.1.273 routes auto-mode subagent reports through it for classifier review. (8) **Permission modes**: parent auto/bypass/acceptEdits override frontmatter; a subagent's `bypassPermissions` is honored only when the parent already is (v2.1.267); main sessions start in auto mode on Pro/Max/Team; under auto mode the classifier reviews the subagent's tool calls and its final report. (9) **`memory` injects MEMORY.md (200 lines / 25KB) and auto-enables Read/Write/Edit** even when omitted from `tools`. (10) **Agent-team teammates from subagent definitions**: `tools` (+SendMessage/Task tools) and `model` apply; body is appended (in-process) or replaces (split-pane); `skills` never applies; `mcpServers` split-pane only; v2.1.267/268 untrusted-folder fix. (11) 15,000-token budget counts `name` + `description`, is a startup notice, and drops nothing. (12) Duplicate-name tie-break within a scope is "filesystem read order rather than a documented precedence". (13) Fork mode: interactive default since v2.1.232, `run_in_background` removed while on, `CLAUDE_CODE_FORK_SUBAGENT` 0/1, `Agent(fork)` deny; teammate-spawned subagents run foreground and `background: true` definitions error there. (14) Worktree/cwd: `cd` doesn't persist across Bash calls in any subagent; worktree commands resolving to the main checkout fail (v2.1.203); unverifiable git invocations refused. (15) `CLAUDE_CODE_SUBAGENT_MODEL` alone doesn't touch Explore/Plan; `_FORCE` ignores every definition's `model` and blocks per-call model; `/tasks` shows model + effort (v2.1.242); concurrent cap exempt under ultracode; nested background results persisted to parent transcript (v2.1.269); headless `--append-subagent-system-prompt-file` (v2.1.261). last_updated bumped to 2026-09-16.

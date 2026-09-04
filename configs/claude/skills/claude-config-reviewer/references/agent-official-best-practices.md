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

last_updated: 2026-09-04
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/best-practices
  - https://code.claude.com/docs/en/changelog
  - https://claude.com/blog/subagents-in-claude-code
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices

---

## Contents

Summary from Official Documentation:
- What Subagents Are
- Subagent File Structure
- Frontmatter Reference
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
| `name` | Yes | Unique identifier using lowercase letters and hyphens. Hooks receive this as `agent_type`. **The filename does not have to match the `name`.** Identity comes only from the `name` field; the subdirectory path does not affect invocation. **`:` is forbidden (added 2026-09-04)**: "Names can't contain `:`, which is reserved for plugin-scoped identifiers such as `my-plugin:reviewer`. Claude Code doesn't load a file whose name contains one and logs an error to the debug log. Before v2.1.218, such names were accepted" (retrieved 2026-09-04) |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, `fable`, full model ID (e.g., `claude-opus-4-8`, `claude-sonnet-4-6`), or `inherit`. Default: `inherit`. **`fable` added to the official alias list (retrieved 2026-06-10)** |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual` (alias for `default`, v2.1.200+). `auto` = background classifier reviews commands; `dontAsk` = auto-deny prompts (explicitly allowed tools still work). Parent `bypassPermissions`/`acceptEdits` take precedence and cannot be overridden; a parent in auto mode forces auto mode (frontmatter ignored). **As of v2.1.223, an agent definition's `bypassPermissions` no longer overrides org policy** ("Fixed permission gap where agent definition's `bypassPermissions` mode ignored org policy") |
| `maxTurns` | No | Maximum agentic turns before stopping. **Updated 2026-09-04:** "When the subagent reaches the limit, Claude Code returns its output marked as partial, and Claude can resume it to continue. The partial marking requires Claude Code v2.1.246 or later" |
| `skills` | No | Skills to preload into context at startup |
| `mcpServers` | No | MCP servers available to subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | **Semantics clarified 2026-09-04:** "Set to `true` to keep this subagent in the background even when Claude asks to run it in the foreground." Default: `false` |
| `effort` | No | `low`, `medium`, `high`, `xhigh`, `max` (levels depend on model) |
| `isolation` | No | `worktree` for temporary git worktree isolation. **Semantics detailed 2026-09-04:** "giving it an isolated copy of the repository branched by default from your default branch rather than the parent session's `HEAD`. The worktree is automatically cleaned up if the subagent makes no changes." |
| `color` | No | Display color. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan` |
| `initialPrompt` | No | Auto-submitted first user turn when running as main session agent |
| `experimental` | No | **NEW (v2.1.248, added 2026-09-04):** "Map of experimental options. Set its `cacheTtl` key to `5m` or `1h` to choose the prompt cache lifetime for this subagent's requests… Claude Code ignores any other value, ignores `1h` while your Claude subscription is using usage credits, and reads the field only from subagent files. Requires Claude Code v2.1.248 or later" |

**Note on `color` values `[official]`:** Updated 2026-04-17. The official palette is `red | blue | green | yellow | purple | orange | pink | cyan`. Prior references to `magenta` are not part of the documented set.
— https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

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

**Recursive scanning & name uniqueness `[official]` (2026-06):**
> "Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so you can organize definitions into subfolders such as `agents/review/` or `agents/research/`. The subdirectory path does not affect how a subagent is identified or invoked, because identity comes only from the `name` frontmatter field. Keep `name` values unique across the whole tree: if two files within one scope declare the same name, Claude Code keeps one and discards the other without warning."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

Plugin `agents/` subfolders, unlike project/user scopes, DO become part of the scoped identifier: `agents/review/security.md` in plugin `my-plugin` registers as `my-plugin:review:security`.

**Nested project agents tie-break — closest-to-cwd wins `[official]` (added 2026-06-26, changelog v2.1.178):**
> "Project subagents are discovered by walking up from the current working directory, so every `.claude/agents/` between there and the repository root is scanned. As of v2.1.178, when more than one of these nested directories defines the same `name`, Claude Code uses the definition closest to the working directory."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

This is a *different* rule from the within-one-scope "duplicates silently discarded" behavior: nested project `.claude/agents/` directories along the cwd walk now have a deterministic tie-break (closest wins), rather than silent loss.

**Load timing `[official]` (2026-06):** "Subagents are loaded at session start. If you add or edit a subagent file directly on disk, restart your session to load it. Subagents created through the `/agents` interface take effect immediately without a restart." (No live change detection for agents, unlike skills.)

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

**Background subagent built-in tool set `[official]` (enumerated 2026-09-04):**
> "Apart from `Agent` and `ExitPlanMode`, which follow the first filter's conditions wherever the subagent runs, a background subagent keeps every MCP tool but only these built-in tools: `Read`, `Grep`, `Glob`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, and `Artifact`. Claude Code removes every other built-in tool from a background subagent, whether inherited or listed in the `tools` field, so the same definition can resolve to different tools in the foreground and the background."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Forks skip both filters and receive the main conversation's exact tool pool. Agent-team teammates additionally keep `TaskCreate`, `TaskGet`, `TaskList`, `TaskUpdate`, `CronCreate`, `CronDelete`, `CronList`.

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

### Foreground vs Background; Permission Surfacing `[official]` (added 2026-06-26)

> "Foreground subagents block the main conversation until complete. Permission prompts are passed through to you as they come up. Background subagents run concurrently while you continue working. As of v2.1.186, when a background subagent reaches a tool call that needs permission, the prompt surfaces in your main session and names the subagent that is asking. Approve to let the subagent continue, or press Esc to deny that one tool call without stopping the subagent. Before v2.1.186, background subagents auto-denied any tool call that would have prompted."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

Implication for reviewers: an agent with `background: true` is no longer at risk of silent auto-deny on permission prompts (since v2.1.186). Ctrl+B backgrounds the running task; `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` disables background entirely.

**Foreground/background decision logic `[official]` (updated 2026-09-04):** Claude Code picks from the first matching case:
> "If an in-process agent team teammate spawned the subagent, Claude Code runs it in the foreground… If you set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` to `1`, Claude Code runs the subagent in the foreground… Where fork mode is on, as it is by default in an interactive session, Claude Code runs the subagent in the background, forks and non-fork subagents alike, and Claude can't ask for the foreground. Where fork mode is off, Claude runs the subagent in the background by default and in the foreground when it needs the result before continuing. Fork mode is off in non-interactive mode with `-p` and in the Agent SDK unless you turn it on."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-09-04)

Since fork mode is on by default in interactive sessions, **in practice every interactively spawned subagent runs in the background** — the background tool-set narrowing (see Tool Restriction) is the normal case, not the exception. `background: true` now means "keep in background even when Claude wants the result in the foreground". Also: "Removed the one-hour time limit on background commands started by subagents; they now run until they exit or are stopped" (changelog v2.1.260).

### MCP Server Restrictions on Subagent-Inline Servers `[official]` (added 2026-06-26)

As of v2.1.153, the MCP restrictions that apply to the main session also cover servers declared in subagent `mcpServers` frontmatter:
- `--strict-mcp-config` and `--bare`
- Enterprise managed MCP configuration
- `allowedMcpServers` and `deniedMcpServers` policies

When one of these blocks a server, Claude Code skips it and shows a warning naming the blocked servers. Note: `--strict-mcp-config` does **not** filter servers passed inline via `--agents` JSON or the SDK `agents` option (those are explicit caller input).

> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

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

Note the distinction: the per-session *total* spawn cap (200) was removed in v2.1.224, but a *concurrent* cap of 20 exists — relevant only to orchestrators that fan out very wide in parallel.

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

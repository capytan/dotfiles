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

last_updated: 2026-06-05
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/best-practices
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
| `name` | Yes | Unique identifier using lowercase letters and hyphens. Hooks receive this as `agent_type`. **The filename does not have to match the `name`.** Identity comes only from the `name` field; the subdirectory path does not affect invocation |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, full model ID (e.g., `claude-opus-4-8`, `claude-sonnet-4-6`), or `inherit`. Default: `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan` |
| `maxTurns` | No | Maximum agentic turns before stopping |
| `skills` | No | Skills to preload into context at startup |
| `mcpServers` | No | MCP servers available to subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | `true` to always run as background task. Default: `false` |
| `effort` | No | `low`, `medium`, `high`, `xhigh`, `max` (levels depend on model) |
| `isolation` | No | `worktree` for temporary git worktree isolation |
| `color` | No | Display color. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan` |
| `initialPrompt` | No | Auto-submitted first user turn when running as main session agent |

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

### Description & Triggering `[official]`

> "Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "To encourage proactive delegation, include phrases like 'use proactively' in your subagent's description field."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

> "Claude automatically delegates tasks based on the task description in your request, the description field in subagent configurations, and current context."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

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

Model resolution order:
1. `CLAUDE_CODE_SUBAGENT_MODEL` env var
2. Per-invocation `model` parameter
3. Subagent definition's `model` frontmatter
4. Main conversation's model

### Tool Restriction `[official]`

> "To restrict tools, use either the tools field (allowlist) or the disallowedTools field (denylist)."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

- If both are set, `disallowedTools` applied first, then `tools` resolved against remaining pool
- `Agent(agent_type)` syntax restricts which subagents can be spawned (main-thread agents only; has no effect inside subagent definitions)
- As of 2.1.63, the Task tool was renamed to `Agent`; `Task(...)` still works as an alias

**Tools unavailable to subagents `[official]`:** These depend on the main conversation's UI/session state and are *not available to subagents even when listed in `tools`*: `Agent`, `AskUserQuestion`, `EnterPlanMode`, `ExitPlanMode` (unless `permissionMode: plan`), `ScheduleWakeup`, `WaitForMcpServers`. Listing them is a no-op (flag in cross-reference checks).
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-05-30)

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

> "Subagents don't inherit skills from the parent conversation; you must list them explicitly."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

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
| Claude Code Guide | Haiku | — | Claude Code feature Q&A |

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

> "Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention. They do not fire when the agent runs as the main session via --agent or the agent setting."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

Project-level hooks in `settings.json`:
- `SubagentStart`: When subagent begins
- `SubagentStop`: When subagent completes

### Plugin Subagent Restrictions `[official]`

> "For security reasons, plugin subagents do not support the hooks, mcpServers, or permissionMode frontmatter fields."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Auto-Compaction `[official]`

> "Subagents support automatic compaction using the same logic as the main conversation. By default, auto-compaction triggers at approximately 95% capacity."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Nesting Limit `[official]`

> "Subagents cannot spawn other subagents. If your workflow requires nested delegation, use Skills or chain subagents from the main conversation."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

### Forked Subagents (experimental) `[official]`

New as of v2.1.117 (env var `CLAUDE_CODE_FORK_SUBAGENT=1`). A **fork** is a subagent that inherits the *entire conversation so far* instead of starting fresh — same system prompt, tools, model, and message history as the main session.

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

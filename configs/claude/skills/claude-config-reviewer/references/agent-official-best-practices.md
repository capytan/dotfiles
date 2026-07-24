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

last_updated: 2026-07-25
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
| `name` | Yes | Unique identifier using lowercase letters and hyphens. Hooks receive this as `agent_type`. **The filename does not have to match the `name`.** Identity comes only from the `name` field; the subdirectory path does not affect invocation |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, `fable`, full model ID (e.g., `claude-opus-4-8`, `claude-sonnet-4-6`), or `inherit`. Default: `inherit`. **`fable` added to the official alias list (retrieved 2026-06-10)** |
| `permissionMode` | No | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, or `plan`. `auto` = background classifier reviews commands; `dontAsk` = auto-deny prompts (explicitly allowed tools still work). Parent `bypassPermissions`/`acceptEdits` take precedence and cannot be overridden; a parent in auto mode forces auto mode (frontmatter ignored) |
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

**Recursive scanning & name uniqueness `[official]` (2026-06):**
> "Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so you can organize definitions into subfolders such as `agents/review/` or `agents/research/`. The subdirectory path does not affect how a subagent is identified or invoked, because identity comes only from the `name` frontmatter field. Keep `name` values unique across the whole tree: if two files within one scope declare the same name, Claude Code keeps one and discards the other without warning."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-10)

Plugin `agents/` subfolders, unlike project/user scopes, DO become part of the scoped identifier: `agents/review/security.md` in plugin `my-plugin` registers as `my-plugin:review:security`.

**Nested project agents tie-break — closest-to-cwd wins `[official]` (added 2026-06-26, changelog v2.1.178):**
> "Project subagents are discovered by walking up from the current working directory, so every `.claude/agents/` between there and the repository root is scanned. As of v2.1.178, when more than one of these nested directories defines the same `name`, Claude Code uses the definition closest to the working directory."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-06-26)

This is a *different* rule from the within-one-scope "duplicates silently discarded" behavior: nested project `.claude/agents/` directories along the cwd walk now have a deterministic tie-break (closest wins), rather than silent loss.

**Load timing `[official]` (2026-06):** "Subagents are loaded at session start. If you add or edit a subagent file directly on disk, restart your session to load it. Subagents created through the `/agents` interface take effect immediately without a restart." (No live change detection for agents, unlike skills.)

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

### Resuming Subagents `[official]` (NEW 2026-06)

Subagents can be resumed with full prior conversation history. Claude uses the `SendMessage` tool with the agent ID (available only when agent teams are enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
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

Implication for reviewers: an agent with `background: true` is no longer at risk of silent auto-deny on permission prompts (since v2.1.186). Ctrl+B backgrounds the running task; `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` disables background entirely. When `CLAUDE_CODE_FORK_SUBAGENT=1`, every subagent spawn runs in the background regardless of `background` field.

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

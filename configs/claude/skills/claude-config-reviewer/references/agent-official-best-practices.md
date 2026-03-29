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

last_updated: 2026-03-30
sources:
  - https://code.claude.com/docs/en/sub-agents
  - https://code.claude.com/docs/en/best-practices

---

## Summary from Official Documentation

### What Subagents Are `[official]`

> "Subagents are specialized AI assistants that handle specific types of tasks. Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

Key benefits:
- Preserve context (exploration stays out of main conversation)
- Enforce constraints (limit tools)
- Reuse configurations across projects
- Specialize behavior with focused system prompts
- Control costs by routing to faster/cheaper models

### Subagent File Structure `[official]`

> "Subagent files use YAML frontmatter for configuration, followed by the system prompt in Markdown."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "Subagents receive only this system prompt (plus basic environment details like working directory), not the full Claude Code system prompt."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

### Frontmatter Reference `[official]`

> "Only name and description are required."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Unique identifier using lowercase letters and hyphens |
| `description` | Yes | When Claude should delegate to this subagent |
| `tools` | No | Tools the subagent can use. Inherits all if omitted |
| `disallowedTools` | No | Tools to deny, removed from inherited or specified list |
| `model` | No | `sonnet`, `opus`, `haiku`, full model ID, or `inherit`. Default: `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, or `plan` |
| `maxTurns` | No | Maximum agentic turns before stopping |
| `skills` | No | Skills to preload into context at startup |
| `mcpServers` | No | MCP servers available to subagent |
| `hooks` | No | Lifecycle hooks scoped to this subagent |
| `memory` | No | Persistent memory scope: `user`, `project`, or `local` |
| `background` | No | `true` to always run as background task. Default: `false` |
| `effort` | No | `low`, `medium`, `high`, `max` (Opus 4.6 only) |
| `isolation` | No | `worktree` for temporary git worktree isolation |
| `initialPrompt` | No | Auto-submitted first user turn when running as main session agent |

### Where Subagents Live `[official]`

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Current session | 1 (highest) |
| `.claude/agents/` | Current project | 2 |
| `~/.claude/agents/` | All your projects | 3 |
| Plugin's `agents/` | Where plugin is enabled | 4 (lowest) |

### Description & Triggering `[official]`

> "Claude uses each subagent's description to decide when to delegate tasks. When you create a subagent, write a clear description so Claude knows when to use it."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "To encourage proactive delegation, include phrases like 'use proactively' in your subagent's description field."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

### Model Selection `[official]`

Model resolution order:
1. `CLAUDE_CODE_SUBAGENT_MODEL` env var
2. Per-invocation `model` parameter
3. Subagent definition's `model` frontmatter
4. Main conversation's model

### Tool Restriction `[official]`

> "To restrict tools, use either the tools field (allowlist) or the disallowedTools field (denylist)."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

- If both are set, `disallowedTools` applied first, then `tools` resolved against remaining pool
- `Agent(agent_type)` syntax restricts which subagents can be spawned

### Preloading Skills `[official]`

> "Use the skills field to inject skill content into a subagent's context at startup. This gives the subagent domain knowledge without requiring it to discover and load skills during execution."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "Subagents don't inherit skills from the parent conversation; you must list them explicitly."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

### Persistent Memory `[official]`

| Scope | Location | Use when |
|-------|----------|----------|
| `user` | `~/.claude/agent-memory/<name>/` | Knowledge applies across all projects |
| `project` | `.claude/agent-memory/<name>/` | Project-specific, shareable via VCS |
| `local` | `.claude/agent-memory-local/<name>/` | Project-specific, not in VCS |

> "project is the recommended default scope."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

### Built-in Subagents `[official]`

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only | File discovery, code search |
| Plan | Inherits | Read-only | Codebase research for planning |
| General-purpose | Inherits | All | Complex multi-step tasks |

### Best Practices `[official]`

> "Design focused subagents: each subagent should excel at one specific task."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "Write detailed descriptions: Claude uses the description to decide when to delegate."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "Limit tool access: grant only necessary permissions for security and focus."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

> "Check into version control: share project subagents with your team."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

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

### Hooks in Subagents `[official]`

Subagent-specific hooks in frontmatter:
- `PreToolUse`: Before tool use
- `PostToolUse`: After tool use
- `Stop`: When subagent finishes (converted to `SubagentStop` at runtime)

Project-level hooks in `settings.json`:
- `SubagentStart`: When subagent begins
- `SubagentStop`: When subagent completes

### Plugin Subagent Restrictions `[official]`

> "For security reasons, plugin subagents do not support the hooks, mcpServers, or permissionMode frontmatter fields."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

### Auto-Compaction `[official]`

> "Subagents support automatic compaction using the same logic as the main conversation. By default, auto-compaction triggers at approximately 95% capacity."
> — https://code.claude.com/docs/en/sub-agents (retrieved 2026-03-30)

---

## Changelog

- 2026-03-29: Skeleton created
- 2026-03-30: Populated with official documentation from code.claude.com/docs/en/sub-agents. Added: subagent definition, frontmatter reference (all 15 fields), scope/priority table, description/triggering guidance, model resolution order, tool restriction (allowlist/denylist/Agent syntax), skill preloading, persistent memory (3 scopes), built-in subagents, best practices (4 principles), when-to-use guide, hooks (frontmatter + settings.json), plugin restrictions, auto-compaction.

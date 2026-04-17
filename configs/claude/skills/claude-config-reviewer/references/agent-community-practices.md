# Agent Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects agent definition insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only)

last_updated: 2026-04-17

---

## Description Field — Trigger Language

### "MUST BE USED" / "Use PROACTIVELY" formula `[community:high]`

The community has converged on a description micro-template built on action-trigger keywords that the router scans for:

```
description: MUST BE USED to <do X> whenever <condition>. Use PROACTIVELY before <event>.
```

> "To enable automatic delegation, you include phrases like 'Use PROACTIVELY' or 'MUST BE USED' in your subagent's description field, which signals that Claude should use this subagent without being asked."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

Notes:
- Official docs only document `"use proactively"` (lowercase); `MUST BE USED` is community-driven but widely replicated.
- Anthropic's own example descriptions use `"Proactively"` / `"Use proactively"` / `"Use immediately after"` — no `"MUST BE USED"` in official examples as of 2026-04-17.

### Action-verb recall hooks `[community:high]`

> "Explicit descriptions generally out-perform code examples for guiding tool use. Claude scans conversations for cues that match the description. Embed action words to raise recall."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

Commonly recommended recall verbs: `review`, `analyze`, `optimize`, `audit`, `generate`, `refactor`, `debug`, `test`, `document`.

### Specificity over capability `[semi-official]`

> "Reviews code for security issues before commits" routes better than "security expert."
> — https://claude.com/blog/subagents-in-claude-code (Anthropic blog, retrieved 2026-04-17)

Description should state **trigger conditions**, not just capabilities.

---

## `<example>` Blocks in Descriptions

### Status: community convention, not official `[community:high]`

Many agent collections (especially Japanese-speaking community outputs and `awesome-claude-code-*` forks) use an `<example>`-block pattern with `Context:`, `user:`, `assistant:`, `<commentary>` subsections inside the description. This convention comes from Anthropic's internal-style prompt engineering guidance but **does not appear in any current official example** on code.claude.com/docs/en/sub-agents (retrieved 2026-04-17).

**Implication:** When the prose description is already specific and contains trigger verbs, `<example>` blocks are redundant. Quality criteria should not penalize agents that follow the official prose-only style.

### When `<example>` blocks add value `[community:mid]`

Community consensus: use 2–4 examples when the triggering condition is ambiguous, contextual, or requires demonstrating proactive (auto-trigger) firing. For simple, explicit-invocation agents, a well-written one-paragraph description is sufficient.

---

## Tool Scoping — Role-Based Allowlists

### Three-tier allowlist pattern `[community:high]`

From `VoltAgent/awesome-claude-code-subagents` (17.5k stars, retrieved 2026-04-17):

| Role | Tools |
|------|-------|
| **Read-only** (reviewers, auditors) | `Read, Grep, Glob` |
| **Research** (gather information) | `Read, Grep, Glob, WebFetch, WebSearch` |
| **Code writer** (create and execute) | `Read, Write, Edit, Bash, Glob, Grep` |
| **Documentation** | `Read, Write, Edit, Glob, Grep, WebFetch, WebSearch` |

> "Each agent has minimal necessary permissions, with read-only agents (reviewers, auditors) using Read, Grep, Glob; research agents adding WebFetch and WebSearch; and code writers using Read, Write, Edit, Bash, Glob, Grep."
> — https://github.com/VoltAgent/awesome-claude-code-subagents (retrieved 2026-04-17)

**Note:** Anthropic's official code-reviewer example includes `Bash` (for `git diff`); the pure `Read, Grep, Glob` read-only pattern is stricter. Both are valid — pick based on whether the agent needs shell-level introspection.

### Model routing per role `[community:high]`

| Task profile | Model |
|--------------|-------|
| Deep reasoning (architecture reviews, security audits) | Opus |
| Everyday coding (writing, debugging, refactoring) | Sonnet |
| Quick tasks (docs, searches, dep checks) | Haiku |

> "Opus: Deep reasoning tasks (architecture reviews, security audits). Sonnet: Everyday coding (writing, debugging, refactoring). Haiku: Quick tasks (docs, searches, dependency checks)."
> — https://github.com/VoltAgent/awesome-claude-code-subagents (retrieved 2026-04-17)

---

## System Prompt Structure

### Five-layer blueprint `[community:high]`

> "Mission/Role – singular outcome statement; Workflow – numbered procedural steps; Output Contract – required Markdown or JSON format; Heuristics & Checks – edge cases and validation rules; (Optional) Delegation cues – cross-agent references."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

This maps cleanly onto the official example structure (role → "When invoked:" steps → checklist → output format → focus statement) — the two sources agree.

### Persona specificity `[community:mid]`

Community agents often add qualifying phrases to the persona opener to invoke domain-specific training: `"senior"`, `"specialist"`, `"15+ years of experience"`. Example: `"You are a senior code reviewer with 15+ years of experience."` This is an optional flourish, not required.

### "Keep scope narrow — one specialty per agent" `[community:high]`

> "One agent should equal one domain of expertise (e.g., code-reviewer, api-architect). Avoid 'mega-agents'; smaller prompts stay in-context and converge faster."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

### Don't mix behavioral instructions into the description `[community:high]`

> "Never mix behavioural instructions meant for the agent into the description block."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

Description = routing signal. System prompt = behavior. Keep them separated.

---

## Second-Person Voice

### Always open with "You are..." `[community:high]`

Universal convention across every high-star collection and every official example:
- `"You are a senior code reviewer..."`
- `"You are an expert debugger..."`
- `"You are a data scientist specializing in SQL and BigQuery analysis."`
- `"You are a file search specialist for Claude Code..."` (built-in Explore agent)

First-person (`I will...`) and third-person (`The agent will...`) both break the convention and are not seen in any official or high-star community agent.

---

## Session Budget Heuristics

### When to delegate `[semi-official]`

> "When a task requires exploring ten or more files, or involves three or more independent pieces of work, that's a strong signal to direct Claude toward subagents."
> — https://claude.com/blog/subagents-in-claude-code (Anthropic blog, retrieved 2026-04-17)

### Chain vs. parallel `[community:high]`

- **Chain** (sequential): `"Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them"` — results flow between agents
- **Parallel**: `"Research the authentication, database, and API modules in parallel using separate subagents"` — independent context, results synthesized at the end

Warning from official docs: parallel subagents returning detailed results can consume significant main-conversation context; use summaries.

---

## Invocation in 2026

### `@agent-<name>` typeahead `[official]`

As of the April 2026 update, `@agent-<name>` in the prompt invokes a specific subagent directly — the same syntax as file mentions. This is now the preferred way to guarantee which subagent runs when you care.
— https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

---

## Japanese Community Notes `[community:mid]`

From Zenn articles (2025-11 through 2026-04):
- Strong emphasis on subagents as **context isolation** tools rather than pure specialization — the "tens of thousands of tokens used, condensed summary returned" framing comes up repeatedly.
- `subagent-creator` pattern: a meta-agent that writes new agent files by interviewing the user. Seen in multiple Zenn posts; useful template for teams standardizing agent authoring.
- Skills vs. Sub-agents comparisons dominate 2026 Japanese posts: consensus is "use subagents when you want isolated context; use skills when you want shared context."

Sources:
- https://zenn.dev/hirokita117/articles/69cbc2c1a389c9 (subagent-creator)
- https://zenn.dev/cureapp/articles/claude-code-skills-vs-subagents
- https://zenn.dev/katsuhisa_/articles/claude-code-subagents-guide

---

## Changelog

- 2026-03-30: Initial skeleton
- 2026-04-17: Populated from Phase 0 research. Added: MUST BE USED / PROACTIVELY trigger formula (with official-vs-community distinction), action-verb recall guidance, `<example>` block status clarification (community convention, not official — do not penalize prose-only descriptions), three-tier role-based tool allowlist (VoltAgent 17.5k-star repo), model-to-role routing table, five-layer system prompt blueprint, persona specificity tips, "one specialty per agent" rule, description/behavior separation rule, second-person universality, Anthropic's 10-files / 3-tasks delegation heuristic, chain-vs-parallel patterns, `@agent-<name>` typeahead invocation, Japanese community notes on context-isolation framing.

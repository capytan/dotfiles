# Agent Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects agent definition insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only)

last_updated: 2026-07-25

---

## Contents

- Description Field — Voice
- Description Field — Trigger Language
- `<example>` Blocks in Descriptions
- Tool Scoping — Role-Based Allowlists
- System Prompt Structure
- Second-Person Voice
- Session Budget Heuristics
- Invocation in 2026
- Japanese Community Notes

## Description Field — Voice

### Third-person description + second-person body `[official]` (resolves a community split)

The official Skills authoring doc says the discovery `description` should be written in **third person** ("Always write in third person… inconsistent point-of-view can cause discovery problems" — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices, retrieved 2026-05-30). All official subagent description examples follow this ("Reviews code for quality…", "Debugging specialist for errors…"). The **body/system prompt** stays second person ("You are…").

Some 2026 community guides muddle this by saying to write the description "as if you're telling Claude when to use it," which reads as imperative. Verified analysis (alexop.dev, tembo.io, digitalapplied.com, 2026-05) concludes this is **not** advocating second person — it is emphasizing *trigger conditions over capabilities*. Net rule: third-person capability + explicit trigger clause. Do not put "You are…" in the description.

Sources:
- https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices (retrieved 2026-05-30) `[official]`
- https://www.tembo.io/blog/claude-code-subagents (retrieved 2026-05-30) `[community:mid]`

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

From `VoltAgent/awesome-claude-code-subagents` (20.9k stars, retrieved 2026-05-30; was 17.5k in April):

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

### "One job and a clear definition of done" `[community:mid]`

> "Keep the system prompt short. Subagents work best with one job and a clear definition of done."
> — https://www.tembo.io/blog/claude-code-subagents (retrieved 2026-05-30)

Tembo's recommended body structure (corroborates the five-layer blueprint): job title → "When invoked, do the following in order:" numbered steps → output format (Markdown / severity tags / file grouping) → explicit constraints (e.g., "Do not modify files; you are read-only by design" for read-only agents). The supatest-ai collection notes its agents target **300–800 lines of focused, actionable content** rather than 2000+ line tutorials `[community:mid]`.

### "Keep scope narrow — one specialty per agent" `[community:high]`

> "One agent should equal one domain of expertise (e.g., code-reviewer, api-architect). Avoid 'mega-agents'; smaller prompts stay in-context and converge faster."
> — https://github.com/vijaythecoder/awesome-claude-agents/blob/main/docs/best-practices.md (retrieved 2026-04-17)

### Feature-specific subagents with preloaded skills over generic role agents `[community:mid]`

Prefer feature-specific subagents (e.g., `payments-api-reviewer` with `skills: [api-conventions, payment-flows]`) over general "qa engineer" / "backend engineer" role agents. Generic role agents duplicate what the main conversation already does; feature-specific agents with preloaded skill content carry actual domain deltas into the isolated context.

> Source: https://github.com/shanraisshan/claude-code-best-practice (retrieved 2026-06-10)
> Aligns with the official `skills` preload mechanism (full skill content injected at subagent startup) and the "one specialty per agent" rule above.

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
- 2026-05-30: Refresh. Added **"Description Field — Voice"** section resolving a 2026 community split: description is third person (official Skills guidance), body stays second person — verified against alexop.dev/tembo.io/digitalapplied.com analyses concluding the imperative-sounding guidance is really "trigger conditions over capabilities," not second person. Updated VoltAgent star count 17.5k → 20.9k (still `[community:high]`). Added Tembo "one job and a clear definition of done / keep system prompt short" guidance and supatest-ai 300–800-line target `[community:mid]`. Model routing, allowlist tiers, blueprint, trigger formula re-verified unchanged.

- 2026-06-05: Freshness re-run (references were 6 days stale). Re-read official skills + sub-agents docs and a 2026-06 CLAUDE.md best-practices survey (Medium/orchestrator.dev/substack, community:mid). No material change: ~80-120 line practical limit / under-200 / 150-200 instruction budget, the "five things", custom-commands-merged-into-skills, agentskills.io open standard, and auto memory / MEMORY.md (200-line auto-load, routing rules stay in CLAUDE.md) all already captured. last_updated bumped to 2026-06-05.
- 2026-06-10: Added one `[community:mid]` insight: prefer feature-specific subagents with preloaded skills over generic "qa engineer"/"backend engineer" role agents (shanraisshan/claude-code-best-practice). Existing sections re-verified, no other changes. last_updated bumped to 2026-06-10.
- 2026-06-26: Freshness re-run (16 days stale). No new community insights worth adopting. Re-verified existing sections against late-June 2026 sources: third-person description + second-person body, MUST BE USED / Use PROACTIVELY trigger formula, action-verb specificity, role-based tool tiers, model routing (Opus/Sonnet/Haiku), five-layer system-prompt blueprint, "one job and a clear definition of done," 300–800-line body target, feature-specific over generic role agents, second-person voice universality, chain vs parallel patterns, @agent-<name> typeahead, Japanese context-isolation framing — all current. Notable official additions in this window (nested subagent spawning v2.1.172, background subagent permission surfacing v2.1.186, nested project agent tie-break v2.1.178) are recorded in official-best-practices, not here. last_updated bumped to 2026-06-26.
- 2026-07-25: Freshness re-run (29 days stale). Surveyed 2026-07 subagent guidance (pubnub, tembo.io, nimbalyst, agentkit.best, computingforgeeks). Existing items re-verified: description-drives-delegation, one job + clear definition of done, explicit output format (parent sees only the final result), tools-as-security-lever, model-as-cost-lever, body-is-the-verbatim-system-prompt. **Correction recorded**: several 2026-07 community articles still describe `/agents` as an interactive creation wizard - that was removed in v2.1.198; official wins, treat the community claim as stale. One new `[community:mid]` datapoint: subagent-heavy workflows can run ~7x the tokens of a single-thread session because each subagent carries its own context - supports existing guidance to reserve subagents for genuinely context-heavy side tasks. No scoring-criteria changes. last_updated bumped to 2026-07-25.

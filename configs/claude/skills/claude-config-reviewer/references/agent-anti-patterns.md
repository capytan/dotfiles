# Agent Anti-Pattern Catalog

> Referenced during Phase 2, criterion E (Anti-patterns) for agent file reviews.
> Each pattern has a severity: Critical / Major / Minor.

---

## Critical — Immediate Action Required

### Empty or Near-Empty System Prompt `[custom:derived-from-agent-reviewer]`

System prompt under 100 characters provides no meaningful guidance for autonomous behavior.

**Detection patterns:**
- Character count of content after closing `---` is under 100
- Only a single sentence or placeholder text

**Fix:** Write a full system prompt with role definition, responsibilities, process steps, and output format. See agent-quality-criteria.md category C for minimum expectations.

---

## Major — Strongly Recommended to Fix

### Wrong Voice in System Prompt `[custom:derived-from-agent-reviewer]`

First-person or third-person voice instead of second person. System prompts must address the agent as "you".

**Detection patterns:**
- First person: `I will`, `I am`, `I should`, `My task is`
- Third person: `The agent will`, `This agent is`, `It should`, `The assistant`

**Fix:** Rewrite in second person: `You are`, `You will`, `Your task is`.

### Generic Agent Name `[custom:derived-from-agent-reviewer]`

Names like "helper", "assistant", "agent", or "tool" provide no signal about purpose and risk collision.

**Detection patterns:**
- `name:` value is one of: `helper`, `assistant`, `agent`, `tool`, `bot`, `utility`
- Name does not hint at the agent's domain or function

**Fix:** Use a descriptive name that reflects the agent's purpose (e.g., `code-reviewer`, `migration-planner`, `test-generator`).

### Description Without Sufficient Examples `[custom:derived-from-agent-reviewer]`

Fewer than 2 `<example>` blocks in the description. Examples are the primary mechanism for triggering accuracy.

**Detection patterns:**
- Count of `<example>` tags in `description` block is 0 or 1
- Description relies solely on prose without concrete trigger demonstrations

**Fix:** Add at least 2 examples (3–4 recommended). Each must include `Context:`, `user:`, `assistant:`, and `<commentary>` blocks.

### Unjustified Write/Bash Tools `[custom:derived-from-agent-reviewer]`

`Write` or `Bash` listed in the `tools` array without clear justification from the agent's described functionality.

**Detection patterns:**
- `tools` array contains `Write` or `Bash`
- System prompt describes read-only or analysis-only responsibilities
- No mention of file creation, modification, or command execution in the process steps

**Fix:** Remove unjustified tools. If the agent only reads and reports, restrict to `["Read", "Grep", "Glob"]`. Add tools back only when the system prompt explicitly describes write or execution behavior.

### Thin System Prompt for Autonomous Agent `[custom:derived-from-agent-reviewer]`

System prompt under 500 words (~3,000 characters) for an agent expected to operate autonomously.

**Detection patterns:**
- Character count between 100 and 2,999
- Agent description implies autonomous decision-making or multi-step workflows
- Lacks process steps, output format, or edge case handling

**Fix:** Expand the system prompt to cover: role definition, core responsibilities (3–8 items), ordered process steps, explicit output format, and edge case handling.

---

## Minor — Recommended to Improve

### Identical Example Phrasing `[custom:derived-from-agent-reviewer]`

All `<example>` blocks use the same phrasing pattern for the user message, reducing trigger variety.

**Detection patterns:**
- User messages across examples start with the same words
- Synonyms or rephrasings are not represented

**Fix:** Vary user message phrasing across examples. Mix direct requests, indirect references, and different vocabulary.

### Missing Proactive Trigger Example `[custom:derived-from-agent-reviewer]`

No example demonstrates the agent firing without an explicit user request (auto-trigger after related work).

**Detection patterns:**
- All examples show the user directly asking for the agent's service
- No example where the assistant proactively invokes the agent

**Fix:** Add at least one example where the assistant auto-triggers the agent after completing related work (e.g., reviewing an agent file after helping write one).

### No Edge Case Handling Instructions `[custom:derived-from-agent-reviewer]`

System prompt lacks guidance for failure modes or unusual inputs.

**Detection patterns:**
- No section mentioning edge cases, errors, or fallback behavior
- No "if X is missing" or "if Y fails" conditional instructions

**Fix:** Add an Edge Cases section covering: file not found, malformed input, empty content, and any domain-specific failure modes.

---

## Changelog

- 2026-03-29: Initial version — derived from agent-reviewer.md check items. All items tagged `[custom:derived-from-agent-reviewer]` pending Phase 0 research for official source validation.

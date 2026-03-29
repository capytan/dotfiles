# Cross-Artifact Checks

> Referenced during Phase 3 (Report) for Cross-Artifact Summary.
> These checks detect issues spanning multiple configuration artifact types.

---

## Check Categories

### 1. Reference Existence
[Verify that referenced skills/agents exist on the filesystem]
- Agent description mentions a skill name → check `.claude/skills/{name}/SKILL.md` exists
- SKILL.md references an agent → check `.claude/agents/{name}.md` exists
- CLAUDE.md mentions a skill/agent by name → verify it exists
- Detection: Grep for skill/agent names across all discovered files, then Glob to verify targets

### 2. Description Consistency
[Check for contradictions between CLAUDE.md and skill/agent descriptions]
- CLAUDE.md states a workflow → skill/agent for that workflow should align
- Agent description claims capabilities → system prompt should support them
- Detection: Extract key claims from each file and cross-compare

### 3. Circular References
[Detect skill→agent→skill reference chains]
- A skill's workflow invokes an agent that invokes the same skill
- Detection: Build a reference graph from all discovered files, check for cycles
- Note: Not all cycles are bugs — some are intentional (e.g., meta-review). Flag for human review.

### 4. Tool Consistency
[Verify tool declarations match actual usage]
- Agent frontmatter `tools:` field lists tools not mentioned in system prompt
- Agent system prompt describes using tools not in `tools:` field
- Skill `tools:` field lists tools not used in any phase
- Detection: Parse tools from frontmatter, grep for tool names in body content

### 5. Stale References
[Detect references to deleted/renamed artifacts]
- References to old skill/agent names that no longer exist
- CLAUDE.md mentions commands or workflows tied to removed skills
- Detection: Collect all referenced names, diff against discovered file list

---

## Severity Classification

| Check | Severity if Failed |
|-------|-------------------|
| Reference Existence | Major |
| Description Consistency | Minor |
| Circular References | Minor (flag for review) |
| Tool Consistency | Major |
| Stale References | Major |

---

## Changelog

- 2026-03-30: Initial version

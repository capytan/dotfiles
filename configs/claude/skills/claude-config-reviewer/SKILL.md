---
name: claude-config-reviewer
description: |
  Review CLAUDE.md, SKILL.md, and agent definitions with researched 100-point scoring.
  Use when: "review CLAUDE.md", "review skill", "review agent", "audit configs", "check quality".
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
---

# Claude Code Config Reviewer

Review and improve Claude Code configuration files — CLAUDE.md, SKILL.md,
and agent definitions (.md). Researches official documentation and
community-backed insights, then updates its own evaluation criteria.

## Workflow Overview

```
Phase 0: Research (investigate & update best practices for all artifact types)
    ↓
Phase 1: Discovery (find CLAUDE.md, SKILL.md, and agent files)
    ↓
Phase 2: Quality Assessment (score each file against type-specific criteria)
    ↓
Phase 3: Report (per-file scores + cross-artifact summary)
    ↓
Phase 4: Fix Proposals & Apply (after user approval)
```

## Paths

Skill directory: `~/.claude/skills/claude-config-reviewer/`
Reference files: `~/.claude/skills/claude-config-reviewer/references/`

⚠️ Always use these absolute paths for Glob/Read. The current working directory is the project being reviewed, not this skill's directory.

---

## Phase 0: Research — Investigate & Update Best Practices

Always run research before reviewing — best practices evolve fast and the cost of
checking is low compared to the risk of evaluating against stale criteria.
Reference files live in the `references/` directory.

### Research Steps

#### Step 1: Official Documentation

1. **context7 MCP** — `resolve-library-id` for "claude code", then `query-docs` for CLAUDE.md, skills, and agents
2. **Anthropic website** — `WebSearch` for latest best practices on `code.claude.com` and `docs.anthropic.com`
3. **Official skill docs** — `WebFetch` https://code.claude.com/docs/en/skills and https://code.claude.com/docs/en/sub-agents

#### Step 2: Community Insights

Research practices with community traction. Sources: GitHub (starred repos, issues), tech blogs, Zenn, Qiita, dev.to, Reddit. Judge by stars, likes, citations.

#### Credibility Tiers

Tag findings per credibility tier defined in each reference file's header (`[official]`, `[semi-official]`, `[community:high]`, `[community:mid]`, `[community:low]`). Only `[community:mid]` and above feed into scoring criteria.

#### Step 3: Diff & Update

- Compare findings against existing reference files
- When official and community sources conflict, prioritize official but note the conflict
- Update all affected `references/*.md` files; set `last_updated` to today

### Recording Rules

- Save source text as direct quotes, not summaries
- Always record source URLs (broken links can be detected later, but missing URLs can never be verified)
- Tag each item with its credibility tier
- Record retrieval date (freshness matters especially for community insights)

---

## Phase 1: Discovery — Find All Configuration Files

Find all Claude Code configuration files in the target repo.
If the user specifies a scope (e.g., "review my skills only"), honor that. Otherwise review all types.

### CLAUDE.md Files

```bash
find . -maxdepth 5 \( -name "CLAUDE.md" -o -name ".claude.local.md" \) 2>/dev/null | head -30
```

Also check:
- `~/.claude/CLAUDE.md` (global defaults)
- `.claude/rules/*.md` (auto-loaded rules)
- `.claude/settings.json` (consistency with hooks)

### SKILL.md Files

```bash
find . -maxdepth 5 -name "SKILL.md" 2>/dev/null | head -30
```

Also check: `~/.claude/skills/*/SKILL.md`

### Agent Definition Files

```bash
find . -maxdepth 3 -path "*agents/*.md" 2>/dev/null | head -30
```

Also check: `~/.claude/agents/*.md`

### File Type Classification

| Type | Location | Scope | Check |
|------|----------|-------|-------|
| Project root | `./CLAUDE.md` | Team-shared (git) | Primary review target |
| Local override | `./.claude.local.md` | Personal (gitignored) | Sensitive info placed here correctly? |
| Global | `~/.claude/CLAUDE.md` | All projects | No project-specific content leaking in? |
| Subdirectory | `./packages/*/CLAUDE.md` | Team-shared | No duplication with root? |
| Rule files | `.claude/rules/*.md` | Team-shared | Properly separated from CLAUDE.md? |
| Skill definition | `.claude/skills/*/SKILL.md` | Per-skill | Best practices compliance? |
| Agent definition | `.claude/agents/*.md` | Per-agent | Best practices compliance? |

---

## Phase 2: Quality Assessment (Parallel Subagents)

Classify discovered files into three pools (CLAUDE.md / SKILL.md / Agent).
For each non-empty pool, dispatch a subagent with its own context window.
Skip empty pools (mark as N/A in the report).

### Dispatch Process

For each non-empty pool, in a **single message with parallel Agent tool calls**:

1. Read the assessor definition from this skill's `agents/` directory
2. Compose the Agent tool prompt by combining:
   - The full assessor file content (role, criteria paths, process, output format)
   - The list of file paths to review (from Phase 1 Discovery)
   - Relevant Discovery context (file classifications, related settings)
3. Dispatch via Agent tool

### Assessors

| Pool | Assessor File | Criteria | Categories |
|------|--------------|----------|------------|
| CLAUDE.md | `agents/claude-md-assessor.md` | `references/claude-md-quality-criteria.md` | A-G (100 pts) |
| SKILL.md | `agents/skill-assessor.md` | `references/skill-quality-criteria.md` | A-H (100 pts) |
| Agent | `agents/agent-assessor.md` | `references/agent-quality-criteria.md` | A-G (100 pts) |

Each assessor reads its own criteria and anti-patterns files, scores every file, runs codebase cross-reference checks, and returns structured results.

### Output Contract

Each subagent returns structured markdown containing:
- Per-file score table (Category | Score | Max | Findings)
- Per-file issues (severity-tagged) and strengths
- Pool Summary (file count, average score, issue counts by severity)

### Error Handling

- If a subagent fails or times out: note the failure, continue with remaining subagents
- If a file cannot be read: skip it, record the skip in the pool summary
- All dispatched subagents must complete before proceeding to Phase 3

---

## Phase 3: Report

**Always output the report before making any changes.** Let the user understand the situation first.

### Aggregating Subagent Results

1. Collect structured output from all dispatched subagents
2. For failed subagents, note the pool as "Assessment failed" in the report
3. For skipped (empty) pools, note as "N/A — no files discovered"
4. Compile per-file assessments into the report template below
5. Read `references/cross-artifact-checks.md` and run all cross-artifact checks using the combined results
6. Generate the Cross-Artifact Summary

### Per-Type Report Template

Use the same structure for each artifact type — adjust category columns to match:

```markdown
## Config Review Report

### Summary
- Files reviewed: X (CLAUDE.md: N, Skills: N, Agents: N)
- Average score: XX/100 (Grade: X)
- Best practices reference date: YYYY-MM-DD

### Per-File Assessment

#### [file path]
**Score: XX/100 (Grade: X)**

| Category | Score | Findings |
|----------|-------|----------|
| ... | ... | ... |

**Issues Found:**
- [Critical] ...
- [Major] ...
- [Minor] ...

**Strengths:**
- ...
```

### Cross-Artifact Summary

When reviewing multiple artifact types, always include (even when scope is limited):

```markdown
### Cross-Artifact Summary
- CLAUDE.md: X files, avg XX/100
- Skills: X files, avg XX/100
- Agents: X files, avg XX/100
- Cross-cutting issues: ...
```

Run all checks defined in `references/cross-artifact-checks.md`:
- References to non-existent skills/agents
- Contradictions between CLAUDE.md and skill/agent descriptions
- Circular references (skill→agent→skill)
- Tool field vs actual usage mismatches
- Stale references to deleted/renamed artifacts

### Grading Scale

| Grade | Score | Meaning |
|-------|-------|---------|
| S | 95-100 | Exemplary — a reference for other projects |
| A | 85-94 | Excellent — only minor improvements possible |
| B | 70-84 | Good — some improvements needed |
| C | 50-69 | Needs improvement — key information missing |
| D | 30-49 | Insufficient — major revision needed |
| F | 0-29 | Not functioning effectively |

---

## Phase 4: Fix Proposals & Apply

After presenting the report, get user approval before making changes.

### Proposal Format

Present each fix as a diff, with per-section token impact quantified:

```markdown
### Fix 1: [file path] — [Section Name]

**Reason:** [one-line why this fix is needed]
**Severity:** [Critical / Major / Minor]
**Lines:** [current] → [proposed] (−N lines, ~M tokens saved)

\```diff
- removed line
+ added line
\```
```

After all individual fixes, include a savings summary table:

```markdown
### Token Savings Summary

| Section | Action | Lines Saved | ~Tokens Saved |
|---------|--------|-------------|---------------|
| ... | ... | ... | ... |
| **Total** | | **−N** | **~M** |

**Before:** X lines (~Y tokens) → **After:** X' lines (~Y' tokens)
```

To estimate tokens: count words in the section and multiply by ~1.3 (English)
or ~2.0 (Japanese/mixed). This is a rough guide, not an exact count.

### Fix Principles

1. **Minimal changes** — only what's needed; no drive-by refactoring
2. **Respect existing structure** — preserve the user's style and organization
3. **Cite the basis** — reference the specific best practice for each fix
4. **Quantify the impact** — every proposal includes line count and estimated token savings
5. **Suggest modularization** — for CLAUDE.md: propose `.claude/rules/` extraction for sections over 30 lines
6. **Show the end state** — present a complete rewrite of the proposed file
7. **Preserve YAML frontmatter** — for SKILL.md and agent fixes, maintain frontmatter structure and `---` delimiters
8. **Name changes require renames** — if `name` field changes, note that directory (skills) or file (agents) must also be renamed

### Modularization Decision Guide (CLAUDE.md)

See [references/claude-md-modularization-guide.md](references/claude-md-modularization-guide.md) for details.

| Method | Best For |
|--------|----------|
| `.claude/rules/*.md` | Rules that should always load (auto-loaded) |
| `@path` in CLAUDE.md | Supplemental info needed only for specific tasks |
| Subdirectory CLAUDE.md | Package-specific info in monorepos |

---

## Reference Files

This skill's evaluation criteria are defined in the following references.
They are updated based on the latest best practices discovered in Phase 0.

### CLAUDE.md References

| File | Content | When Referenced |
|------|---------|----------------|
| [references/claude-md-official-best-practices.md](references/claude-md-official-best-practices.md) | Official best practices | Phase 0 |
| [references/claude-md-community-practices.md](references/claude-md-community-practices.md) | Community insights | Phase 0 |
| [references/claude-md-quality-criteria.md](references/claude-md-quality-criteria.md) | Scoring rubric | Phase 2 |
| [references/claude-md-anti-patterns.md](references/claude-md-anti-patterns.md) | Anti-pattern catalog | Phase 2 |
| [references/claude-md-modularization-guide.md](references/claude-md-modularization-guide.md) | Modularization strategies | Phase 4 |

### SKILL.md References

| File | Content | When Referenced |
|------|---------|----------------|
| [references/skill-official-best-practices.md](references/skill-official-best-practices.md) | Official best practices | Phase 0 |
| [references/skill-community-practices.md](references/skill-community-practices.md) | Community insights | Phase 0 |
| [references/skill-quality-criteria.md](references/skill-quality-criteria.md) | Scoring rubric | Phase 2 |
| [references/skill-anti-patterns.md](references/skill-anti-patterns.md) | Anti-pattern catalog | Phase 2 |

### Agent References

| File | Content | When Referenced |
|------|---------|----------------|
| [references/agent-official-best-practices.md](references/agent-official-best-practices.md) | Official best practices | Phase 0 |
| [references/agent-community-practices.md](references/agent-community-practices.md) | Community insights | Phase 0 |
| [references/agent-quality-criteria.md](references/agent-quality-criteria.md) | Scoring rubric | Phase 2 |
| [references/agent-anti-patterns.md](references/agent-anti-patterns.md) | Anti-pattern catalog | Phase 2 |

### Cross-Artifact

| File | Content | When Referenced |
|------|---------|----------------|
| [references/cross-artifact-checks.md](references/cross-artifact-checks.md) | Cross-artifact validation checks | Phase 3 |

---

## Self-Update Guidelines

Rules for updating this skill's references (content rules live in Phase 0 Recording Rules):

1. **Show the diff** — record what changed in each reference's `## Changelog` section
2. **Preserve custom criteria** — items not found in official docs (e.g., behavioral impact assessment) are tagged `[custom]` and retained
3. **Official wins on conflict** — but confirm with the user before removing custom criteria
4. **Update all artifact types** — when researching, check for updates across CLAUDE.md, SKILL.md, and agent best practices

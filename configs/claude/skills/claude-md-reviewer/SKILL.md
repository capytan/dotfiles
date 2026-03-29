---
name: claude-md-reviewer
description: |
  Review and improve CLAUDE.md files based on latest best practices.
  Self-evolving skill that researches official docs and community insights on each run.
  Use when: "review CLAUDE.md", "improve CLAUDE.md", "audit CLAUDE.md",
  "optimize project memory", "CLAUDE.md is too long", or any CLAUDE.md question.
  Covers quality assessment, fix proposals, updates, and modularization suggestions.
  Also handles new CLAUDE.md creation and health checks on existing files.
  Use this skill whenever CLAUDE.md is mentioned, even without explicit "review" requests.
tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
---

# CLAUDE.md Reviewer

Review and improve CLAUDE.md files based on the latest best practices.
Researches both official documentation and community-backed insights,
then updates its own evaluation criteria — keeping the skill always current.

## Workflow Overview

```
Phase 0: Research (investigate & update best practices)
    ↓
Phase 1: Discovery (find all CLAUDE.md files)
    ↓
Phase 2: Quality Assessment (score against criteria)
    ↓
Phase 3: Report (always present before making changes)
    ↓
Phase 4: Fix Proposals & Apply (after user approval)
```

---

## Phase 0: Research — Investigate & Update Best Practices

Always run research before reviewing — best practices evolve fast and the cost of
checking is low compared to the risk of evaluating against stale criteria.
Reference files live in the `references/` directory.

### Research Steps

#### Step 1: Official Documentation

1. **context7 MCP**
   - `resolve-library-id` to find "claude code"
   - `query-docs` for "CLAUDE.md best practices", "project memory", etc.
   - Extract CLAUDE.md-related sections from Claude Code official docs

2. **Anthropic website**
   - `WebSearch` for "claude code CLAUDE.md best practices site:docs.anthropic.com"
   - Check official blog and changelog for recent changes
   - `WebFetch` specific pages as needed

#### Step 2: Community Insights

Research practices with community traction, even if not in official docs.

1. **GitHub**
   - `WebSearch` for "CLAUDE.md tips OR best practices OR template site:github.com"
   - Collect well-starred repos' CLAUDE.md files as reference examples
   - Extract useful patterns from Claude Code issues/discussions

2. **Blogs, articles, forums**
   - `WebSearch` for "CLAUDE.md writing guide", "claude code project memory tips", etc.
   - Collect practical insights from tech blogs, Zenn, Qiita, dev.to, Reddit, etc.
   - Judge traction by bookmark count, likes, shares

3. **Awesome lists & curated resources**
   - `WebSearch` for "awesome claude code", "claude code resources"
   - Extract CLAUDE.md-related insights from curated collections

#### Credibility Tiers

Tag each piece of information with a credibility tier:

| Tier | Criteria | Tag |
|------|----------|-----|
| **Official** | Anthropic official docs or blog | `[official]` |
| **Semi-official** | Anthropic employee's personal posts, official repo comments | `[semi-official]` |
| **Community (high)** | GitHub 50+ stars, cited in multiple independent articles, widely reproduced | `[community:high]` |
| **Community (mid)** | GitHub 10-50 stars, verified in a tech blog with concrete testing | `[community:mid]` |
| **Community (low)** | Individual report, unverified but reasonable | `[community:low]` |

`[community:low]` items are recorded for reference only — not incorporated into scoring criteria.
Only `[official]`, `[semi-official]`, `[community:high]`, and `[community:mid]` feed into criteria.

#### Step 3: Diff Analysis

- Compare findings against existing reference files
- Identify new recommendations, deprecated practices, changes
- When official and community sources conflict, prioritize official but note the conflict

#### Step 4: Update References

- Update `references/official-best-practices.md` (official & semi-official info)
- Update `references/community-practices.md` (community insights)
- Set `last_updated` to today on both files
- Update `references/quality-criteria.md` if criteria are affected
- Add new anti-patterns to `references/anti-patterns.md` if found

### Recording Rules

- Save source text as direct quotes, not summaries
- Always record source URLs (broken links can be detected later, but missing URLs can never be verified)
- Tag each item with its credibility tier
- Record retrieval date (freshness matters especially for community insights)

---

## Phase 1: Discovery — Find All CLAUDE.md Files

Find all CLAUDE.md-related files in the target repo:

```bash
find . -maxdepth 5 \( -name "CLAUDE.md" -o -name ".claude.local.md" \) 2>/dev/null | head -30
```

Also check:
- `~/.claude/CLAUDE.md` (global defaults)
- `.claude/rules/*.md` (auto-loaded rules)
- `.claude/settings.json` (consistency with hooks)

### File Type Classification

| Type | Location | Scope | Check |
|------|----------|-------|-------|
| Project root | `./CLAUDE.md` | Team-shared (git) | Primary review target |
| Local override | `./.claude.local.md` | Personal (gitignored) | Sensitive info placed here correctly? |
| Global | `~/.claude/CLAUDE.md` | All projects | No project-specific content leaking in? |
| Subdirectory | `./packages/*/CLAUDE.md` | Team-shared | No duplication with root? |
| Rule files | `.claude/rules/*.md` | Team-shared | Properly separated from CLAUDE.md? |

---

## Phase 2: Quality Assessment

Evaluate each CLAUDE.md against criteria defined in `references/quality-criteria.md`.

### Process

1. Read file in full
2. Count lines (baseline for token efficiency)
3. Evaluate each criterion in order
4. Cross-reference against actual codebase (do commands work? do paths exist?)

### Criteria Summary

See [references/quality-criteria.md](references/quality-criteria.md) for full rubric.

| Category | Points | Summary |
|----------|--------|---------|
| A. Token Efficiency | 20 | Line count thresholds, inferable content detection |
| B. Commands & Workflows | 15 | Build/test/deploy coverage |
| C. Architecture Clarity | 15 | Structure explanation, module relationships |
| D. Non-Obvious Patterns | 15 | Gotchas, workarounds |
| E. Actionability | 15 | Copy-paste ready, concrete instructions |
| F. Anti-patterns | 10 | Known problem pattern detection |
| G. Behavioral Impact | 10 | Does each section actually change Claude's decisions? |

### Codebase Cross-Reference

Go beyond desk review — verify against the actual codebase:

- Do documented commands exist in `package.json`, `Makefile`, `Taskfile`, etc.?
- Do referenced file paths actually exist? (check with Glob)
- Does architecture description match actual directory structure?
- Are there oversized sections that should be split into `.claude/rules/`?

---

## Phase 3: Report

**Always output the report before making any changes.** Let the user understand the situation first.

```markdown
## CLAUDE.md Review Report

### Summary
- Files reviewed: X
- Average score: XX/100 (Grade: X)
- Best practices reference date: YYYY-MM-DD

### Per-File Assessment

#### ./CLAUDE.md (Project Root)
**Score: XX/100 (Grade: X)**

| Category | Score | Findings |
|----------|-------|----------|
| A. Token Efficiency | X/20 | ... |
| B. Commands | X/15 | ... |
| C. Architecture | X/15 | ... |
| D. Non-Obvious Patterns | X/15 | ... |
| E. Actionability | X/15 | ... |
| F. Anti-patterns | X/10 | ... |
| G. Behavioral Impact | X/10 | ... |

**Issues Found:**
- [Critical] ...
- [Major] ...
- [Minor] ...

**Modularization Suggestions:**
- ...

**Strengths:**
- ...
```

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
### Fix 1: ./CLAUDE.md — [Section Name]

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
| Architecture tree | Replace with 1-line summary | −25 | ~300 |
| Symlink table | Remove (discoverable from install.sh) | −12 | ~200 |
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
5. **Suggest modularization** — propose `.claude/rules/` extraction for sections over 30 lines
6. **Show the end state** — after the savings table, present a complete rewrite of the proposed CLAUDE.md so the user can see exactly what the file would look like after all fixes are applied; this makes it far easier to evaluate the overall result than reading individual diffs

### Modularization Decision Guide

See [references/modularization-guide.md](references/modularization-guide.md) for details.

| Method | Best For |
|--------|----------|
| `.claude/rules/*.md` | Rules that should always load (auto-loaded) |
| `@path` in CLAUDE.md | Supplemental info needed only for specific tasks |
| Subdirectory CLAUDE.md | Package-specific info in monorepos |

---

## Reference Files

This skill's evaluation criteria are defined in the following references.
They are updated based on the latest best practices discovered in Phase 0.

| File | Content | When Referenced |
|------|---------|----------------|
| [references/official-best-practices.md](references/official-best-practices.md) | Primary info from official docs | Phase 0 freshness check |
| [references/community-practices.md](references/community-practices.md) | Community-backed insights & patterns | Phase 0 freshness check |
| [references/quality-criteria.md](references/quality-criteria.md) | Scoring rubric details | Phase 2 assessment |
| [references/anti-patterns.md](references/anti-patterns.md) | Anti-pattern catalog | Phase 2 criterion F |
| [references/modularization-guide.md](references/modularization-guide.md) | Modularization strategies & decision criteria | Phase 4 split proposals |

---

## Self-Update Guidelines

Rules for updating this skill's references:

1. **Prefer primary sources** — save direct quotes from official docs, not summaries
2. **Always record provenance** — URL + retrieval date; criteria without traceable sources are unreliable
3. **Show the diff** — record what changed in the `## Changelog` section
4. **Preserve custom criteria** — items not found in official docs (e.g., behavioral impact assessment) are tagged `[custom]` and retained
5. **Official wins on conflict** — but confirm with the user before removing custom criteria

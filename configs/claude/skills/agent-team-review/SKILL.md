---
name: agent-team-review
description: |
  Parallel multi-agent code review with independent confidence scoring.
  Five methodology-based reviewers (rules audit, bug scan, git history,
  PR archaeology, code comments) each use a distinct information source
  to find bugs, then separate scoring agents filter false positives.
  Triggers on "team review", "deep review", "thorough review", "agent team review",
  "team review this PR". Use when deeper analysis is needed beyond
  code-review plugin or pr-review-toolkit. Supports both PRs and local changes.
---

# Agent Team Code Review

Five reviewers, each using a **distinct methodology and information source**, analyze code in parallel. Separate scoring agents independently evaluate each finding to filter false positives.

## Design Principles

- **Methodology diversity**: Each reviewer uses a different information source (diff only, git history, PR comments, code comments, project rules) — findings don't overlap
- **Independent scoring**: Findings are scored by separate agents, not by the reviewer that found them — eliminates self-scoring bias
- **Graduated models**: Haiku for prep/scoring, Opus for review
- **High threshold**: Only issues scoring 80+ survive

## Phase 1: Preparation (Parallel Haiku)

Launch 2 Haiku agents in parallel:

### 1a. Eligibility & Context (Haiku)

If PR number/URL provided:
- Check: not closed, not draft, not automated, not trivially simple, no existing review from you
- If ineligible, report reason and **stop**

Always:
- Read all CLAUDE.md / REVIEW.md files (root + directories of changed files)
- Return: file paths, rule content, eligibility status

### 1b. Change Summary (Haiku)

If PR:
- `gh pr view <number>` + `gh pr diff <number>`

If local changes:
- AskUserQuestion: "Review target: (1) staged (2) unstaged (3) both"
- Run appropriate `git diff` command

Return: summary of what changed and why, full diff, changed file list

**Stop conditions**: PR ineligible, diff empty.
**Warning**: Confirm with user if diff > 3000 lines.

## Phase 2: Parallel Review (5 Opus Agents)

Launch all five simultaneously in a single message via Agent tool.

Each agent receives: full diff + changed file list + CLAUDE.md content.
Each returns a list of findings in the following **common format** (required for Phase 3 scoring):

```
- **File**: path/to/file.ts:45
- **Summary**: one-line description of the finding
- **Reason**: why this was flagged (see agent-specific format below)
- **Detail**: full description, evidence, and fix suggestion
- **Pre-existing**: yes/no (is this on unchanged lines?)
```

### Agent #1: Rules Auditor

name: "rules-auditor", model: opus

Audit changes for CLAUDE.md / REVIEW.md compliance.

- Read each rule carefully
- Check if any change in the diff violates it
- Not all CLAUDE.md instructions apply during review — skip build/workflow instructions
- Only report violations where CLAUDE.md **specifically** calls out the issue
- Quote the exact rule being violated
- For issues silenced by lint-ignore/type-ignore comments in code, do NOT report
- Reason format: `CLAUDE.md says "<exact quote>"`

### Agent #2: Bug Scanner

name: "bug-scanner", model: opus

Shallow scan for obvious bugs. **Do NOT read extra context beyond the diff.**

- Focus on **large bugs only** — ignore small issues and nitpicks
- Ignore likely false positives — if unsure, skip it
- Do NOT report:
  - Issues a linter, typechecker, or compiler would catch (imports, type errors, formatting)
  - General quality issues (test coverage, documentation, security best practices) unless required in CLAUDE.md
  - Pre-existing issues on unchanged lines
  - Intentional changes directly related to the broader change purpose
- Reason format: `bug due to <file and code snippet>`

### Agent #3: History Analyst

name: "history-analyst", model: opus

Use git blame and git log to find bugs **invisible from the diff alone**.

- Run `git blame -L <start-10>,<end+10> <file>` around changed lines
- Run `git log -30 --oneline -- <file>` for each changed file
- Check if deleted/modified lines were added by bug-fix commits (keywords: fix, bugfix, hotfix, patch, security, revert)
- Check if the change reverts a previous fix
- Check for function signature changes breaking callers
- Base confidence on **git evidence**, not speculation
- Do NOT report: intentional refactoring, deprecated API migration
- Reason format: `historical git context: <commit and evidence>`

### Agent #4: PR Archaeologist

name: "pr-archaeologist", model: opus

Check previous PRs that touched these files for **comments that may also apply**.

- Find recent merged PRs: `gh pr list --state merged --search "<filename>" --limit 5` or `git log --oneline -20 -- <file>`
- Read comments on those PRs: `gh api repos/{owner}/{repo}/pulls/{number}/comments`
- Only report issues clearly relevant to the current change
- **Skip entirely** if not in a GitHub repo or `gh` is unavailable
- Reason format: `previous PR comment: <PR link and quote>`

### Agent #5: Comments Auditor

name: "comments-auditor", model: opus

Read code comments in modified files and check if changes **comply with in-code guidance**.

- Use Read to view the full file for each changed file
- Find directive comments: TODO, FIXME, HACK, WARNING, NOTE, IMPORTANT, "do not modify", "must be", "required by", etc.
- Check if any change violates guidance in those comments
- Check if any comment is now stale/misleading due to the changes
- Do NOT report: general lack of comments, style preferences
- Reason format: `code comment says "<quote>"`

## Phase 3: Independent Scoring (Parallel Haiku)

For **each finding** from Phase 2, launch a parallel Haiku agent to score confidence.

Each scoring agent receives:
- The full diff (or relevant excerpt around the finding)
- The finding description and reason flagged
- All CLAUDE.md files from Phase 1
- `references/false-positives.md` content

Scoring agents should **use Read to verify** the actual code when needed (e.g., "does this variable exist?", "is this actually nullable?"). Don't just evaluate the description — check the code.

Give each scoring agent the rubric from `references/scoring-rubric.md` **verbatim**.

## Phase 4: Filter & Report

### 4.1 Threshold

Filter out issues scoring < 80. Record filtered count.
If no issues remain, output "No issues found" report and **stop** (skip GitHub comment for PR).

### 4.2 Deduplication

Merge findings on the same file within 5 lines:
- Combine reviewer labels: `[Rules + Bug Scanner]`
- Keep the higher confidence score
- Merge details from both perspectives

### 4.3 Severity Classification

| Confidence | Severity |
|-----------|----------|
| 90–100 | 🔴 Normal — must fix |
| 80–89 | 🟡 Nit — recommended |
| Any (unchanged lines) | 🟣 Pre-existing |

### 4.4 Report

Output structured markdown in the session language:

```markdown
## Code Review Report

**Target**: PR #42 / Local changes (staged/unstaged/both)
**Files reviewed**: N files, M lines changed
**Reviewers**: Rules, Bug Scanner, History, PR Archaeology, Comments

### 🔴 Normal (N issues)

1. **[Rules Auditor]** description (CLAUDE.md says "<...>")
   - File: `path/to/file:45`
   - Confidence: 95
   - Detail and fix suggestion

2. **[Bug Scanner + History]** merged finding (bug due to <...>)
   - File: `path/to/file:23`
   - Confidence: 92
   - Bug Scanner: description / History: regression evidence

### 🟡 Nit (N issues)
...

### 🟣 Pre-existing (N issues)
...

### Summary
- Normal: N | Nit: N | Pre-existing: N
- Filtered: N issues (confidence < 80)
```

Zero issues:

```markdown
## Code Review Report

**Target**: PR #42 / Local changes
**Files reviewed**: N files, M lines changed

No issues found. All reviewers confirmed the changes look correct.
```

### 4.5 GitHub Comment (PR only)

1. Re-check eligibility (Haiku) — PR still open, no newer review from you
2. Post via `gh pr comment`
3. Link format — **full git SHA required** (no bash interpolation):
   ```
   https://github.com/owner/repo/blob/<full-sha>/path/file.ts#L44-L47
   ```
   - Include at least 1 line of context before/after in the line range
   - SHA must be the full 40-char hash, not abbreviated
4. Footer:
   ```
   🤖 Generated with [Claude Code](https://claude.ai/code)

   <sub>- If this code review was useful, please react with 👍. Otherwise, react with 👎.</sub>
   ```

## False Positives

Give `references/false-positives.md` to all reviewers (Phase 2) and scoring agents (Phase 3). Do not report pre-existing issues, linter-catchable issues, or pedantic nitpicks. See the reference file for the full catalog.

## Error Handling

- **Individual reviewer failure**: Skip failed reviewer, note in Summary, generate report from remaining
- **Diff retrieval failure**: Show error and stop
- **`gh` unavailable**: Skip PR Archaeologist, note in Summary
- **No issues above threshold**: Report "No issues found" — do not post empty review

## Notes

- Do NOT check build signal or attempt to build/typecheck. These run separately in CI.
- Use `gh` for GitHub interactions, not web fetch
- Make a todo list before starting
- Cite and link every issue (if referring to CLAUDE.md, link it)

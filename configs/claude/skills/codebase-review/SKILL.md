---
name: codebase-review
description: |
  Full codebase review with seven methodology-based reviewers (Opus or Sonnet) and independent
  confidence scoring. Covers rules compliance, bugs, git hotspots, code comments,
  architecture, security (OWASP), and dependency analysis.
  Triggers on "codebase review", "audit codebase", "review the codebase",
  "full review", "全体レビュー", "コードベースレビュー".
  Does not trigger for: PR review, diff review, document review.
  Use for reviewing source files directly (not diffs). For diff-based review,
  use agent-team-review or code-review instead.
---

# Codebase Review

Seven reviewers, each using a **distinct methodology and information source**, analyze source files in parallel. Separate scoring agents independently evaluate each finding to filter false positives.

## Design Principles

- **Methodology diversity**: Each reviewer uses a different information source — findings don't overlap
- **Independent scoring**: Findings are scored by separate agents, not by the reviewer that found them
- **Graduated models**: Haiku for prep/scoring, user-selected model (Opus or Sonnet) for review
- **High threshold**: Only findings scoring 80+ survive
- **Scoped execution**: User selects review scope to keep analysis tractable

## Phase 1: Scope & Context (Parallel Haiku)

Launch 2 Haiku agents in parallel:

### 1a. Project Discovery (Haiku)

- Discover project structure: languages, frameworks, file count
- Read all CLAUDE.md / REVIEW.md files (root + subdirectories)
- Identify source file patterns (exclude: node_modules, vendor, build artifacts, .git, binary files)
- Return: project summary, CLAUDE.md content, source file list with line counts

### 1b. Scope Selection (Haiku)

Present the user with scope and model options via AskUserQuestion (2 questions in one call):

**Question 1: Review scope**
```
(1) Full scan — all source files (small repos, < 100 files)
(2) Git hotspot — auto-prioritize by change frequency and bug-fix history (recommended)
(3) Directory scope — specify directories to review
(4) Hybrid — git hotspot priority + you add/exclude paths
```

**Question 2: Reviewer model**
```
(1) Opus — highest quality, slower and more expensive (recommended for critical reviews)
(2) Sonnet — good quality, faster and cheaper (recommended for iterative reviews)
```

For each option:
- **Full scan**: Use the complete source file list from 1a
- **Git hotspot**: Run `git log --since='6 months ago' --format='%H' -- <file>` per file, rank by change frequency. Also flag files touched by bug-fix commits (keywords: fix, bugfix, hotfix, patch, security). Select top N files (cap at 50).
- **Directory scope**: Ask user for directories, filter file list accordingly
- **Hybrid**: Start with git hotspot results, then ask user for additions/exclusions

Return: final prioritized file list for Phase 2

**Stop conditions**: No source files found, user cancels.
**Warning**: Confirm with user if file count > 100 or total lines > 50,000.

## Phase 2: Parallel Review (7 Agents)

Launch all seven simultaneously in a single message via Agent tool, using the **user-selected model** from Phase 1b.

Each agent receives: prioritized file list + CLAUDE.md content + project summary.
Each reads files directly via Read tool and returns findings in the **common format**:

```
- **File**: path/to/file.ts:45
- **Summary**: one-line description of the finding
- **Reason**: why this was flagged (see agent-specific format below)
- **Detail**: full description, evidence, and fix suggestion
```

### Agent #1: Rules Auditor

name: "rules-auditor", model: user-selected (opus or sonnet)

Audit source files for CLAUDE.md / REVIEW.md compliance.

- Read each file in the prioritized list
- Check against each CLAUDE.md rule
- Not all CLAUDE.md instructions apply during review — skip build/workflow instructions
- Only report violations where CLAUDE.md **specifically** calls out the issue
- Quote the exact rule being violated
- For issues silenced by lint-ignore/type-ignore comments, do NOT report
- Reason format: `CLAUDE.md says "<exact quote>"`

### Agent #2: Bug Scanner

name: "bug-scanner", model: user-selected (opus or sonnet)

Scan source files for obvious bugs.

- Read each file and look for clearly wrong logic
- Focus on **large bugs only** — ignore small issues and nitpicks
- Ignore false positives — if you are not confident the bug is real, skip it
- Do NOT report:
  - Issues a linter, typechecker, or compiler would catch
  - General quality issues unless required in CLAUDE.md
  - Framework-idiomatic patterns
- Reason format: `bug due to <file and code snippet>`

### Agent #3: History Analyst

name: "history-analyst", model: user-selected (opus or sonnet)

Use git log and blame to identify **high-risk areas** in the codebase.

- Run `git log -30 --oneline -- <file>` for each file
- Identify files with frequent bug-fix commits (keywords: fix, bugfix, hotfix, patch, security, revert)
- Run `git blame` on high-risk files to find recently patched areas
- Check if those patches have incomplete error handling, uncovered edge cases, missing validation, or TODO/FIXME comments indicating unfinished work
- Base findings on **git evidence**, not speculation
- Reason format: `git history: <commit evidence>`

### Agent #4: Comments Auditor

name: "comments-auditor", model: user-selected (opus or sonnet)

Read code comments and check if they accurately reflect the code.

- Use Read to view each file in the prioritized list
- Find directive comments: TODO, FIXME, HACK, WARNING, NOTE, IMPORTANT, "do not modify", "must be", "required by"
- Check if the code actually follows its own comments
- Identify stale comments that no longer match the code
- Flag abandoned TODOs older than 6 months (check via `git blame`)
- Do NOT report: general lack of comments, style preferences
- Reason format: `code comment says "<quote>"`

### Agent #5: Architecture Analyst

name: "architecture-analyst", model: user-selected (opus or sonnet)

Review file structure, dependencies, and architectural patterns.

- Analyze import/require/include statements across files
- Detect circular dependencies
- Identify layer violations (e.g., UI importing directly from DB layer)
- Check for god files (> 500 lines with multiple responsibilities)
- Verify directory structure follows project conventions (from CLAUDE.md)
- Flag inconsistent patterns across similar files
- Do NOT report: framework-mandated structure, test file organization
- Reason format: `architecture: <pattern and evidence>`

### Agent #6: Security Scanner

name: "security-scanner", model: user-selected (opus or sonnet)

OWASP-based security vulnerability scan across source files.

- Scan for injection vulnerabilities (SQL, command, XSS, template)
- Check authentication and authorization patterns
- Detect hardcoded secrets, API keys, tokens, passwords
- Identify sensitive data in logs or error messages
- Check for path traversal, SSRF, insecure redirects
- Verify cryptographic usage (weak hashes, insecure random)
- Read code from an attacker's perspective: trace data flow from input to output
- Do NOT report: theoretical vulnerabilities with no attack surface, internal-only tools
- Reason format: `security: <vulnerability type and evidence>`

### Agent #7: Dependency Analyst

name: "dependency-analyst", model: user-selected (opus or sonnet)

Analyze package manifests, lock files, and dependency usage.

- Read package.json, Gemfile, requirements.txt, go.mod, Cargo.toml, etc.
- If available, run `npm audit` / `pip-audit` / `cargo audit` / `bundler-audit` to check for known vulnerabilities
- Identify outdated major versions with breaking security fixes
- Detect unused dependencies (declared but not imported)
- Find dependency conflicts or version mismatches across workspaces
- Check lock file consistency with manifest
- Do NOT report: minor version differences, dev-only dependencies in non-production contexts
- Reason format: `dependency: <package and evidence>`

## Phase 3: Independent Scoring (Parallel Haiku)

For **each finding** from Phase 2, launch a parallel Haiku agent to score confidence.

Each scoring agent receives:
- The finding description and reason flagged
- The relevant source file content (via Read)
- All CLAUDE.md files from Phase 1
- `references/false-positives.md` content

Scoring agents should **use Read to verify** the actual code when needed. Don't just evaluate the description — check the code.

Give each scoring agent the rubric from `references/scoring-rubric.md` **verbatim**.

## Phase 4: Filter & Report

### 4.1 Threshold

Filter out findings scoring < 80. Record filtered count.
If no findings remain, output "No issues found" report and **stop**.

### 4.2 Deduplication

Merge findings on the same file within 5 lines:
- Combine reviewer labels: `[Bug Scanner + Security]`
- Keep the higher confidence score
- Merge details from both perspectives

### 4.3 Severity Classification

| Confidence | Severity |
|-----------|----------|
| 90-100 | 🔴 Critical — must fix |
| 80-89 | 🟡 Warning — recommended |

### 4.4 Report

Output structured markdown in the session language:

```markdown
## Codebase Review Report

**Scope**: Full scan / Git hotspot / Directory: src/ / Hybrid
**Files reviewed**: N files, M total lines
**Reviewers**: Rules, Bug Scanner, History, Comments, Architecture, Security, Dependency

### 🔴 Critical (N issues)

1. **[Security]** Hardcoded API key in config (security: hardcoded secret)
   - File: `src/config.ts:23`
   - Confidence: 98
   - Detail and fix suggestion

2. **[Architecture]** Circular dependency between modules (architecture: circular import)
   - File: `src/auth/index.ts:5` ↔ `src/user/index.ts:3`
   - Confidence: 95
   - Detail

### 🟡 Warning (N issues)
...

### Summary
- Critical: N | Warning: N
- Filtered: N findings (confidence < 80)
- Reviewers: 7/7 completed (or N/7 if failures)

### Top Risk Areas
- `src/auth/` — 3 issues (Security: 2, Architecture: 1)
- `src/config.ts` — 2 issues (Rules: 1, Security: 1)
```

Zero issues:

```markdown
## Codebase Review Report

**Scope**: Full scan / Git hotspot / Directory: src/ / Hybrid
**Files reviewed**: N files, M total lines

No issues found. All reviewers confirmed the codebase looks correct.
```

## False Positives

Give `references/false-positives.md` to all reviewers (Phase 2) and scoring agents (Phase 3). See the reference file for the full catalog.

## Error Handling

- **Individual reviewer failure**: Skip failed reviewer, note in Summary, generate report from remaining
- **File read failure**: Skip file, continue with remaining files
- **`gh` unavailable**: History Analyst falls back to `git log` only
- **No source files found**: Show error and stop
- **No findings above threshold**: Report "No issues found"

## Notes

- Do NOT attempt to build, typecheck, or run tests. Focus on static analysis of source files.
- Use `git` commands for history analysis, not `gh`
- Make a todo list before starting
- Cite and link every finding with file path and line number

---
name: agent-team-review
description: |
  Parallel multi-agent code review using Agent Teams. Five specialized reviewers
  (logic errors, security vulnerabilities, edge cases, regressions, infra/config)
  analyze code in parallel with broadcast cross-validation to eliminate false positives.
  Triggers on "team review", "deep review", "thorough review", "agent team review",
  "team review this PR". Use when deeper cross-validation is needed beyond
  code-review plugin or pr-review-toolkit. Supports both PRs (gh pr diff) and
  local changes (git diff).
---

# Agent Team Code Review

Parallel multi-agent code review using Agent Teams. Five specialized reviewers analyze code independently, then cross-validate via broadcast to eliminate false positives.

## Prerequisites

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` must be enabled. If not set, show the following and stop:

```
Add to settings.json:
"env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
```

## Phase 1: Review Target

Determine what to review.

1. **PR specified**: PR number or URL provided
   - Get diff via `gh pr diff <number>`
   - Get PR info via `gh pr view <number>`

2. **No PR specified**: Review local changes
   - Use AskUserQuestion: "Select review target: (1) staged changes (2) unstaged changes (3) both"
   - Run `git diff --cached`, `git diff`, or `git diff HEAD` accordingly

3. **No changes**: If diff is empty, notify user and stop

Warn user and confirm if diff exceeds 3000 lines.

## Phase 2: Context Collection

Gather review context.

1. **Project rules**: Read CLAUDE.md / REVIEW.md if they exist
2. **Changed files**: Extract file paths from diff
3. **Reviewer references**: Read files from `references/`:
   - `reviewer-logic.md` — for LOGIC reviewer
   - `reviewer-security.md` — for SECURITY reviewer
   - `reviewer-edge-cases.md` — for EDGE reviewer
   - `reviewer-regression.md` — for REGRESSION reviewer
   - `reviewer-infra-config.md` — for INFRA reviewer
   - `false-positives.md` — shared by all reviewers
   - `verification-protocol.md` — used in Phase 5

## Phase 3: Launch Agent Team

Create a team and launch five Opus reviewers in parallel.

### Team Setup

```
TeamCreate:
  team_name: "code-review-team"
  description: "Parallel multi-agent code review with cross-validation"
```

### Teammate Launch

Launch all five teammates **simultaneously** via Agent tool (five calls in a single message).

Common settings for all teammates:
- model: opus
- team_name: "code-review-team"
- Each receives: full diff + changed file list + CLAUDE.md summary + specialized reference + false-positives.md
- Output follows session language

Prompt template for each teammate:

#### LOGIC Reviewer

```
Agent:
  name: "logic-reviewer"
  team_name: "code-review-team"
  model: opus
  prompt: |
    You are the LOGIC reviewer. You specialize in detecting logic errors,
    control flow issues, null/undefined handling, and race conditions.

    ## Diff
    <paste full diff>

    ## Changed Files
    <paste file list>

    ## Project Rules
    <paste CLAUDE.md summary>

    ## Checklist
    <paste reviewer-logic.md content>

    ## False Positive Patterns (do NOT report these)
    <paste false-positives.md content>

    ## Instructions
    1. Analyze the diff line by line using the checklist
    2. Only report issues directly related to changed lines (tag off-diff bugs as [PRE-EXISTING])
    3. Assign a confidence score (0-100) to each finding
    4. Exclude anything matching false positive patterns
    5. Use Read to check surrounding context (50 lines) when needed
    6. Send results to the lead when complete

    ## Output Format (per finding)
    - **ID**: LOGIC-001
    - **File**: path/to/file.ts:45
    - **Severity**: Normal / Nit / Pre-existing
    - **Confidence**: 0-100
    - **Summary**: one-line summary
    - **Detail**: description and fix suggestion
```

#### SECURITY Reviewer

Same prompt structure as LOGIC. Replace the checklist with reviewer-security.md and adjust role-specific sections:

```
Agent:
  name: "security-reviewer"
  team_name: "code-review-team"
  model: opus
  prompt: |
    You are the SECURITY reviewer. You specialize in detecting injection,
    auth/authz flaws, secret exposure, and SSRF vulnerabilities.

    ## Diff
    <paste full diff>

    ## Changed Files
    <paste file list>

    ## Project Rules
    <paste CLAUDE.md summary>

    ## Checklist
    <paste reviewer-security.md content>

    ## False Positive Patterns (do NOT report these)
    <paste false-positives.md content>

    ## Instructions
    1-6 same as LOGIC. Additional:
    - Read code from an attacker's perspective
    - Trace data flow from user input to output/storage

    ## Output Format
    Same as LOGIC (ID prefix: SEC-)
```

#### EDGE Reviewer

Same prompt structure as LOGIC. Replace the checklist with reviewer-edge-cases.md:

```
Agent:
  name: "edge-reviewer"
  team_name: "code-review-team"
  model: opus
  prompt: |
    You are the EDGE reviewer. You specialize in detecting boundary conditions,
    empty inputs, concurrent access, and type mismatches.

    ## Diff
    <paste full diff>

    ## Changed Files
    <paste file list>

    ## Project Rules
    <paste CLAUDE.md summary>

    ## Checklist
    <paste reviewer-edge-cases.md content>

    ## False Positive Patterns (do NOT report these)
    <paste false-positives.md content>

    ## Instructions
    1-6 same as LOGIC. Additional:
    - Systematically find "works on my machine" bugs
    - Apply boundary values to each input parameter

    ## Output Format
    Same as LOGIC (ID prefix: EDGE-)
```

#### REGRESSION Reviewer

Same prompt structure as LOGIC. Replace the checklist with reviewer-regression.md:

```
Agent:
  name: "regression-reviewer"
  team_name: "code-review-team"
  model: opus
  prompt: |
    You are the REGRESSION reviewer. You specialize in detecting reverted fixes
    and broken contracts using git blame/log (last 30 commits).

    ## Diff
    <paste full diff>

    ## Changed Files
    <paste file list>

    ## Project Rules
    <paste CLAUDE.md summary>

    ## Checklist
    <paste reviewer-regression.md content>

    ## False Positive Patterns (do NOT report these)
    <paste false-positives.md content>

    ## Instructions
    1-6 same as LOGIC. Additional:
    - Run git blame and git log to analyze history context
    - Check if deleted lines were added by bug-fix commits

    ## Output Format
    Same as LOGIC (ID prefix: REG-)
```

#### INFRA Reviewer

Same prompt structure as LOGIC. Replace the checklist with reviewer-infra-config.md:

```
Agent:
  name: "infra-reviewer"
  team_name: "code-review-team"
  model: opus
  prompt: |
    You are the INFRA reviewer. You specialize in detecting missing infrastructure
    configuration, environment variable gaps, and deployment readiness issues.

    ## Diff
    <paste full diff>

    ## Changed Files
    <paste file list>

    ## Project Rules
    <paste CLAUDE.md summary>

    ## Checklist
    <paste reviewer-infra-config.md content>

    ## False Positive Patterns (do NOT report these)
    <paste false-positives.md content>

    ## Instructions
    1-6 same as LOGIC. Additional:
    - Scan for new environment variable references and config file changes
    - Cross-reference with IaC repos and secrets management when accessible
    - Check if new external resources (storage, queues, databases, etc.) are provisioned
    - Verify feature flags exist in management system
    - Identify deployment ordering requirements

    ## Output Format
    Same as LOGIC (ID prefix: INFRA-)
```

### Waiting for Results

Wait for completion messages from all five teammates. Messages are delivered automatically.

## Phase 4: Cross-Validation

**Condition**: Execute only when total findings >= 5. Skip to Phase 5 if fewer.

1. Lead creates a summary table of all findings (ID, File, Severity, Confidence, Summary)
2. Broadcast via SendMessage:

```
SendMessage:
  type: "broadcast"
  content: |
    ## Cross-Validation Request

    Below are all findings from all reviewers. From your specialized perspective,
    challenge any finding you believe is a false positive.
    Reply "no objections" if you have none.

    <findings table>

    Objection format:
    - **Target ID**: ID of the challenged finding
    - **Reason**: why you believe it is a false positive
  summary: "Cross-validation request for all findings"
```

3. Wait for replies (treat unresponsive teammates as "no objections")
4. Subtract **15 points** from confidence for any finding with objections
5. Explicit "no objections" or no response counts as agreement

## Phase 5: Verification, Dedup & CLAUDE.md Check

Follow `verification-protocol.md`.

### 5.1 Deduplication

Merge findings on the same file with overlapping line ranges (within 5 lines):
- Combine perspectives (e.g., `[LOGIC + SECURITY]`)
- Keep the higher confidence
- Merge details from both

### 5.2 False Positive Filtering

Final check against `false-positives.md` patterns. Remove matches.

### 5.3 CLAUDE.md Compliance Check

Lead checks diff against CLAUDE.md / REVIEW.md rules and adds violations as findings.

### 5.4 Confidence Threshold

Filter out findings with confidence < 80. Record filtered count.

### 5.5 Severity Classification

Classify remaining findings:

| Marker | Level | Criteria |
|--------|-------|----------|
| 🔴 | Normal | Must fix before merge (confidence 90-100) |
| 🟡 | Nit | Recommended but non-blocking (confidence 80-89) |
| 🟣 | Pre-existing | Bug not introduced by this change |

## Phase 6: Report Generation

Output a structured markdown report in the session language.

```markdown
## Code Review Report

**Target**: PR #42 / Local uncommitted changes (staged/unstaged/both)
**Files reviewed**: N files, M lines changed
**Reviewers**: LOGIC, SECURITY, EDGE, REGRESSION, INFRA
**Cross-validation**: Performed / Skipped (< 5 findings)

### 🔴 Normal (N issues)

1. **[LOGIC]** description
   - File: `path/to/file.ts:45`
   - Confidence: 95
   - Detail and fix suggestion

2. **[LOGIC + SECURITY]** merged finding example
   - File: `path/to/file.ts:23`
   - Confidence: 92
   - LOGIC: missing null check / SECURITY: unvalidated input

### 🟡 Nit (N issues)
...

### 🟣 Pre-existing (N issues)
...

### Summary
- Normal: N issues
- Nit: N issues
- Pre-existing: N issues
- CLAUDE.md compliance: No violations / N violations
- Filtered: N issues (confidence < 80)
- Cross-validated: N issues had objections (-15 confidence each)
```

If zero findings:

```markdown
## Code Review Report

**Target**: PR #42 / Local uncommitted changes
**Files reviewed**: N files, M lines changed
**Reviewers**: LOGIC, SECURITY, EDGE, REGRESSION, INFRA

No issues found. All reviewers confirmed the changes look correct.
```

## Phase 7: Cleanup

1. Send shutdown_request to each teammate:

```
SendMessage:
  type: "shutdown_request"
  recipient: "logic-reviewer"
  content: "Review complete. Shutting down."
```

2. Repeat for all five (logic-reviewer, security-reviewer, edge-reviewer, regression-reviewer, infra-reviewer)

## Error Handling

- **Agent Teams launch failure**: Show error and suggest alternatives:
  ```
  Agent Teams failed to start. Try these alternatives:
  - /code-review (simple review)
  - /pr-review-toolkit:review-pr (detailed review)
  ```
- **Individual reviewer failure**: Skip failed reviewer, generate report from remaining results. Note failure in Summary.
- **Diff retrieval failure**: Show error and stop

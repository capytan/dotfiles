---
name: dig
description: "Clarifies ambiguities in plans with structured questions. Invoked explicitly with /dig or automatically during plan mode when ambiguous requirements, underspecified behavior, or unvalidated assumptions are detected."
---

# dig - Plan Requirements Clarifier

Finds and resolves every ambiguity in the user's plan through structured interviewing using the AskUserQuestion tool.

## When to Use This Skill

**Explicit invocation:**
- `/dig` command
- User says "掘り下げて", "曖昧な点を明確にして", "要件を詰めて", etc.

**Automatic trigger (suggest to user):**
- During plan mode when you detect ambiguous requirements or underspecified behavior
- When a plan contains assumptions that need validation

## Execution Process

### Phase 1: Initial Analysis

Use the Agent tool with `subagent_type: "Explore"` to perform a comprehensive analysis:

1. Find and read the current plan file (check `.claude/plans/`, `tasks/`, or the working directory for `.md` plan files)
2. Read `CLAUDE.md` to understand project conventions and constraints
3. Scan related source code for existing patterns that may conflict with or inform the plan

If no plan file exists, stop with an error and guide the user:
> "Plan file が見つかりません。先に plan mode でプランを作成してください。"

From the analysis, identify:
- Ambiguous requirements or underspecified behavior
- Missing technical decisions (data model, API design, error handling, etc.)
- Assumptions that need validation
- Conflicts with existing patterns in CLAUDE.md or the codebase

### Phase 2: Interview Loop

For each round, use **AskUserQuestion** with 2-4 questions:

**Rules:**
- Each question has 2-4 concrete options with brief pros/cons in the description
- Prioritize by impact: architectural decisions > implementation details > cosmetic choices
- "Other" option is auto-added by AskUserQuestion — do not include it
- When a user answer references specific code, use Grep/Read to inspect relevant files before the next round
- Do NOT use the Explore subagent after Phase 1 — use Grep/Read for lightweight lookups

After receiving answers, output a summary:

```
## Decisions (Round N)

| Item | Choice | Reason | Notes |
|------|--------|--------|-------|

## Next Steps

1. ...
```

Then use AskUserQuestion to ask whether to continue:
- Default option order: "Yes, keep going" (1st) / "Done, write to plan" (2nd)
- If "Done" → proceed to Phase 3
- If "Yes" → analyze updated decisions + codebase for new ambiguities and repeat Phase 2
- When no meaningful ambiguities remain, recommend "Done" as the first option

### Phase 3: Write Results

Update the plan file by integrating dig results into the existing content:
- Add a `## Clarified Decisions` section with the consolidated Decisions table
- Update existing sections where dig results provide specificity (e.g., refine vague steps with concrete choices)
- Do NOT simply append — merge results into the plan structure

## Constraints

- **Always use AskUserQuestion** — never ask questions as plain text
- Do not skip Phase 1 analysis — reading the plan and CLAUDE.md first produces better questions
- Each round should go deeper, not repeat surface-level questions
- Use the Explore subagent only once in Phase 1; all subsequent lookups via Grep/Read

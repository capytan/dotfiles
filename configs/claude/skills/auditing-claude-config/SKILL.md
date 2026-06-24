---
name: auditing-claude-config
description: Audit Claude Code's six-layer setup (CLAUDE.md, rules, skills, hooks, subagents, verifiers) for misconfigurations. Use when Claude ignores rules, hooks misfire, MCP access fails, skills don't trigger, or context feels bloated. Tier-calibrated.
allowed-tools: Bash, Read, Agent
---

# Claude Code Configuration Health Audit

Audit the current project's Claude Code setup with the six-layer framework:
`CLAUDE.md → rules → skills → hooks → subagents → verifiers`

The goal is to find violations and identify the misaligned layer, calibrated to project complexity.

**Output language:** Check in order: (1) CLAUDE.md `## Communication` rule (global takes precedence over local); (2) language of the user's recent conversation messages; (3) default English. Apply the detected language to all output including progress lines, the report, and the stop-condition question.

**IMPORTANT:** Before the first tool call, output a progress block in the output language:

```
Step 1/3: Collecting configuration data
  · CLAUDE.md (global + local) · rules/ · settings.local.json · hooks
  · MCP servers · skills inventory + security scan
  · conversation history (up to 3 recent sessions)
```

## Step 0: Assess project tier

Pick tier:

| Tier | Signal | What's expected |
|------|--------|-----------------|
| **Simple** | <500 project files, 1 contributor, no CI | CLAUDE.md only; 0–1 skills; no rules/; hooks optional |
| **Standard** | 500–5K project files, small team or CI present | CLAUDE.md + 1–2 rules files; 2–4 skills; basic hooks |
| **Complex** | >5K project files, multi-contributor, multi-language, active CI | Full six-layer setup required |

**Apply only the detected tier's requirements.**


## Step 1: Collect all data (single bash block)

Run the bundled collector. It reads the current project's six-layer config plus recent conversation files and prints structured `=== SECTION ===` banners that Step 2 parses.

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/collect.sh"
```

The script is idempotent and best-effort: missing `jq`, `python3`, or `settings.local.json` produce `(unavailable)` markers rather than aborting the run. See `scripts/collect.sh` for the data sources collected.

> For detailed SKILL.md/agent scoring with research-backed criteria, use the `claude-config-reviewer` skill.

## Gotchas

Before interpreting Step 1 output, check these known failure modes.

**Data collection silent failures**
- `jq` not installed: conversation extraction prints `(unavailable: jq not installed or parse error)`. BEHAVIOR section will be empty -- treat as [INSUFFICIENT DATA], not a finding.
- `python3` not on PATH: all MCP/hooks/allowedTools sections print `(unavailable)`. Do not flag those areas when the data source itself failed.
- `settings.local.json` absent: hooks, MCP, and allowedTools all show `(unavailable)`. Normal for projects using global settings only -- not a misconfiguration.

**MEMORY.md path construction**
- Path built with `sed 's|[/_]|-|g'` on `pwd`. Unusual characters produce the wrong project key. If MEMORY.md shows `(none)` but the user mentions prior sessions, verify the path manually before flagging as [!].

**Conversation extract scope**
- Only the 3 most recent `.jsonl` files are sampled, skipping the active session. Findings from fewer than 3 files carry low signal -- always tag [LOW CONFIDENCE].

**MCP token estimate**
- Assumes ~25 tools/server and ~200 tokens/tool. Servers with many or few tools cause large over/under-estimates. Treat as directional, not precise.

**Tier misclassification edge cases**
- The bash block excludes `node_modules/`, `dist/`, and `build/`, but not all generators. Monorepos with `.next/`, `__pycache__/`, or `.turbo/` output can inflate the file count and trigger COMPLEX tier falsely. Recheck manually if the tier feels wrong.

## Step 2: Analyze with tier-adjusted depth

After Step 1 completes, output a summary line, then the step indicator:

```
Tier: {SIMPLE/STANDARD/COMPLEX} -- {file_count} files · {contributor_count} contributors · CI: {present/absent}
Step 2/3: {SIMPLE: "Analyzing locally" | STANDARD/COMPLEX: "Launching parallel analysis agents"}
```

SIMPLE: output "Analyzing locally" above. Do not launch subagents. Analyze from Step 1, prioritize core config checks, skip conversation-heavy cross-validation unless evidence is obvious.

STANDARD/COMPLEX: output "Launching parallel analysis agents" above, then list coverage:

```
  · Agent 1: CLAUDE.md, rules, skills, MCP context + security scan
  · Agent 2: hooks, allowedTools, behavior patterns, three-layer defense
```

Launch **two subagents** in parallel. Paste all data inline -- do not pass file paths. Before pasting, replace any credential values (API keys, tokens, passwords) with `[REDACTED]`; paste the structural data only.

### Agent 1 -- Context + Security Audit (no conversation needed)

Read `agents/agent1-context.md` from this skill's directory. It specifies which Step 1 sections to paste and the full audit checklist.

### Agent 2 -- Control + Behavior Audit (uses conversation evidence)

Read `agents/agent2-control.md` from this skill's directory. It specifies which Step 1 sections to paste and the full audit checklist.

## Step 3: Synthesize and present

Before writing the report, output a progress line in the output language:

```
Step 3/3: Synthesizing report
```

Aggregate the local analysis and any agent outputs into one report:

---

**Health Report: {project} ({tier} tier, {file_count} files)**

### Passing

Render a compact table of checks that passed. Include only checks relevant to the detected tier. Limit to 5 rows. Omit rows for checks that have findings.

| Check | Detail |
|-------|--------|
| settings.local.json gitignored | ok |
| No nested CLAUDE.md | ok |
| Skill security scan | no flags |

### Critical -- fix now

Rules violated, missing verification definitions, dangerous allowedTools, MCP overhead >12.5%, required-path `Access denied`, active cache-breakers, and security findings.

### Structural -- fix soon

CLAUDE.md content that belongs elsewhere, missing hooks, oversized skill descriptions, single-layer critical rules, model switching, verifier gaps, subagent permission gaps, and skill structural issues.

### Incremental -- nice to have

New patterns to add, outdated items to remove, global vs local placement, context hygiene, HANDOFF.md adoption, skill invoke tuning, and provenance issues.

---

If all three issue sections are empty, output one short line in the output language like: `All relevant checks passed. Nothing to fix.`

## Non-goals
- Never auto-apply fixes without confirmation.
- Never apply complex-tier checks to simple projects.
- Flag issues, do not replace architectural judgment.


**Stop condition:** After the report, ask in the output language:
> "Should I draft the changes? I can handle each layer separately: global CLAUDE.md / local CLAUDE.md / hooks / skills."

Do not make any edits without explicit confirmation.

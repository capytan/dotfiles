---
name: skill-creator
description: |
  Create new Claude Code skills from scratch, or modify and improve existing skills.
  Use when users want to create a skill, update or optimize an existing skill, or
  improve a skill's description for better triggering accuracy.
  Triggers on: "create a skill", "make a new skill", "build a skill for",
  "improve this skill", "optimize skill description", "skill triggers wrong".
  Do NOT use for: agent creation, command development, plugin scaffolding, or
  general coding tasks unrelated to skill authoring.
---

# Skill Creator

Creates and improves Claude Code skills following Anthropic's official best practices.

## Overall Flow

1. **Intent capture** — Understand what the user wants the skill to do
2. **Design** — Choose pattern, define success criteria, plan file structure
3. **Create** — Write frontmatter, instructions, and supporting files
4. **Test** — Verify triggering, functionality, and output quality
5. **Iterate** — Refine based on test results

## Phase 1: Intent Capture & Use Case Definition

Ask the user (using AskUserQuestion if needed):

1. **What does the skill do?** — Core purpose in one sentence
2. **When should it trigger?** — 2-3 concrete use cases
3. **Which category?**
   - Document & Asset generation (PDFs, reports, diagrams)
   - Workflow Automation (multi-step processes, reviews, deployments)
   - MCP Enhancement (orchestrating external tools/services)

From the answers, identify the best design pattern. See `references/patterns.md` for the 5 patterns.

## Phase 2: Success Criteria

Define measurable criteria before writing any code:

**Quantitative:**
- Triggering accuracy: skill fires on intended prompts ~90% of the time
- Expected tool calls: list which tools the skill should invoke
- Zero unhandled errors: all failure paths have graceful handling

**Qualitative:**
- User needs no manual corrections to output
- Behavior is consistent across sessions
- Skill does not over-trigger on unrelated prompts

## Phase 3: File Structure

Create the skill directory:

```
skills/[skill-name]/
  SKILL.md              # Core instructions (target: 100-250 lines)
  references/           # Optional: detailed docs loaded on demand
    [topic].md          # Pattern details, examples, troubleshooting
  scripts/              # Optional: executable scripts
    [script].sh/py      # Must handle errors internally
  assets/               # Optional: templates, schemas
    [template].md       # Static resources referenced by SKILL.md
```

**Critical**: The file MUST be named exactly `SKILL.md`. Never create a README.md in the skill directory.

## Phase 4: Frontmatter

Write the YAML frontmatter block:

```yaml
---
name: [skill-name]
description: |
  [What it does]. [When to use it — trigger phrases]. [Key capabilities].
  [Negative triggers — when NOT to use it].
---
```

**name rules:**
- kebab-case only (lowercase, hyphens)
- Must match the folder name exactly
- Max 64 characters
- Never include "claude" or "anthropic"
- Prefer gerund form: `processing-pdfs` not `pdf-processor`

**description rules:**
- Max 1024 characters
- Structure: `[What] + [When/Triggers] + [Capabilities] + [Negative triggers]`
- Be "pushy" — assertive about when to activate, not passive
- Include literal trigger phrases users would say
- Include negative triggers to prevent over-triggering
- No XML tags

**Optional fields:**
- `compatibility`: Version/environment requirements (1-500 chars)
- `metadata`: Key-value pairs for categorization
- `license`: License identifier

## Phase 5: Writing Instructions

Use this recommended structure for the SKILL.md body:

```markdown
# [Skill Name]

[1-2 sentence overview]

## When to Use This Skill
[Explicit trigger conditions and non-triggers]

## Workflow
[Numbered steps with clear actions]

## Critical Rules
[Non-negotiable constraints, early in the file]

## Output Format
[Expected output structure/template]

## Error Handling
[What to do when things go wrong — specific solutions, not generic advice]

## References
[Pointers to files in references/, scripts/, assets/]
```

**Instruction best practices:**
- Use imperative language: "Read the file", "Validate the output", "Report a FAIL"
- Never use ambiguous hedging: avoid "might", "could", "consider" for required actions
- Every instruction must be specific and testable
- Place critical rules early — not buried at the bottom
- Reference bundled resources explicitly: "See `references/patterns.md` for details"

## Phase 6: Test & Iterate

After creating the skill, verify:

**Trigger test:**
- Try 3 prompts that SHOULD trigger the skill
- Try 3 prompts that should NOT trigger it
- If undertriggering: make description more assertive, add trigger phrases
- If overtriggering: add negative triggers, narrow scope

**Functionality test:**
- Run the skill's core workflow end-to-end
- Verify all referenced files are accessible
- Check output matches the expected format

**Performance check:**
- Count total lines across all files (SKILL.md < 500 lines)
- Count total words (aim for < 5,000 words across all files)
- If too large, split into references/ for progressive disclosure

See `references/troubleshooting.md` for common issues and solutions.

## Progressive Disclosure

Organize content in 3 levels:

| Level | Location | Loaded when | Size guidance |
|-------|----------|-------------|---------------|
| 1 | Frontmatter `description` | Always (skill selection) | < 1024 chars |
| 2 | SKILL.md body | Skill triggers | 100-250 lines |
| 3 | references/, scripts/ | On demand | As needed |

When SKILL.md exceeds ~300 lines, split detailed content into `references/` files.
SKILL.md should contain the core workflow; reference files contain detailed rules, examples, and troubleshooting.

## Critical Rules

- File MUST be named `SKILL.md` (exact case)
- NEVER create README.md in the skill directory
- No XML tags in frontmatter or instructions
- SKILL.md must be under 500 lines and 5,000 words
- No nested file references (references/ files must not reference other files)
- All scripts must handle errors internally ("solve, don't punt")

## References

- Design patterns: `references/patterns.md`
- Troubleshooting: `references/troubleshooting.md`
- Good/bad examples: `references/examples.md`

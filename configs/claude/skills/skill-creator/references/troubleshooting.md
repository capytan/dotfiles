# Skill Troubleshooting Guide

## Upload/Recognition Failure

**Symptoms**: Skill does not appear in Claude Code, or is listed but marked as invalid.

**Common causes**:
- File not named exactly `SKILL.md` (case-sensitive)
- Presence of `README.md` in the skill directory (conflicts with SKILL.md)
- Invalid YAML frontmatter (missing `---` delimiters, bad indentation)
- `name` field contains uppercase, underscores, or spaces

**Solutions**:
1. Verify filename: `ls -la` in the skill directory
2. Remove any README.md files
3. Validate YAML with `yq '.name' SKILL.md`
4. Ensure name is kebab-case and matches folder name

## Trigger Not Firing (Undertriggering)

**Symptoms**: Skill exists but Claude never invokes it, even on relevant prompts.

**Common causes**:
- Description is too vague or generic
- Missing trigger phrases and example scenarios
- Description does not clearly state WHEN to use the skill
- Other skills have overlapping but stronger descriptions

**Solutions**:
1. Add explicit trigger phrases: "Use when the user says X, Y, Z"
2. Include negative triggers: "Do NOT use when..."
3. Make description "pushy" — assertive about when to activate
4. Add 2-3 example blocks showing trigger scenarios
5. Test with exact phrases from description to verify

## Over-Triggering

**Symptoms**: Skill activates on unrelated prompts, hijacking normal conversations.

**Common causes**:
- Description is too broad ("Use for any coding task")
- Trigger phrases are too common ("help", "fix", "create")
- Missing negative triggers to exclude irrelevant cases

**Solutions**:
1. Narrow the description scope with specific conditions
2. Add negative triggers: "Do NOT trigger when: general coding questions, simple file edits"
3. Use domain-specific vocabulary instead of generic terms
4. Test with unrelated prompts to verify non-activation

## Instructions Being Ignored

**Symptoms**: Skill triggers correctly but Claude doesn't follow the instructions accurately.

**Common causes**:
- Instructions buried deep in large file (>300 lines without structure)
- Ambiguous language ("might", "could", "consider doing")
- Instructions conflict with Claude's defaults or other skills
- Critical rules placed at the end instead of early in the file

**Solutions**:
1. Place critical rules and constraints early in SKILL.md
2. Use imperative language: "Always do X", "Never do Y", "Must include Z"
3. Break long instructions into progressive disclosure (SKILL.md + references/)
4. Use checklists for multi-step workflows
5. Add explicit output format templates

## Context Bloat

**Symptoms**: Skill works but consumes excessive tokens, causing slow responses or context overflow.

**Common causes**:
- SKILL.md exceeds 500 lines or 5,000 words
- Large reference files loaded unconditionally
- Embedded examples that are too verbose
- Redundant explanations of concepts Claude already knows

**Solutions**:
1. Split into SKILL.md (core) + references/ (details loaded on demand)
2. Keep SKILL.md under 250 lines for the core workflow
3. Remove explanations of basic concepts (Claude knows them)
4. Use concise examples (input/output pairs, not narratives)
5. Check total word count: SKILL.md alone < 5,000 words; aim for concise references

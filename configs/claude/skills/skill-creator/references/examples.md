# Skill Examples: Good vs Bad

## Frontmatter Examples

### Good

```yaml
---
name: processing-pdfs
description: |
  Extracts text, tables, and metadata from PDF files. Use when the user
  uploads a PDF or asks to "parse PDF", "extract from PDF", or "read this
  document". Handles multi-page documents, scanned PDFs (via OCR), and
  structured table extraction. Do NOT use for image-only files or EPUB.
---
```

```yaml
---
name: reviewing-pull-requests
description: |
  Reviews GitHub pull requests for code quality, security issues, and
  style compliance. Triggers when user says "review PR", "check this PR",
  or provides a PR URL. Runs automated checks and produces a structured
  report with severity ratings. Do NOT use for issue triage or release notes.
---
```

```yaml
---
name: generating-api-tests
description: |
  Generates integration tests for REST and GraphQL APIs. Use when the user
  asks to "test this endpoint", "write API tests", or "generate test cases
  for the API". Reads OpenAPI/Swagger specs or infers schema from code.
  Produces pytest or Jest test files with edge case coverage.
---
```

### Bad

```yaml
# Too vague — when does it trigger?
---
name: helper
description: Helps with various tasks.
---
```

```yaml
# Name violates conventions (uppercase, underscore)
---
name: PDF_Processor
description: Processes PDFs
---
```

```yaml
# No trigger phrases, no negative triggers, no capabilities
---
name: code-review
description: Reviews code for issues.
---
```

## Instruction Examples

### Good: Specific and actionable

```markdown
## Workflow

1. Read the target file using the Read tool
2. Count lines — if over 500, report a FAIL under [D]
3. Validate YAML frontmatter:
   - name: kebab-case, <= 64 chars, no "claude"/"anthropic"
   - description: non-empty, <= 1024 chars, includes trigger phrases
4. For each check item [A]-[J], output PASS/FAIL/WARNING with evidence
```

### Bad: Vague and unactionable

```markdown
## Instructions

Review the skill carefully. Check if things look right.
Consider whether the description is good enough.
You might want to validate the frontmatter too.
```

## Progressive Disclosure Example

### Level 1: Frontmatter (always loaded)
```yaml
description: |
  [Concise what + when + capabilities — this is the first thing Claude sees]
```

### Level 2: SKILL.md body (loaded when skill triggers)
```markdown
# Skill Name

## Workflow
[Core steps — the main instructions Claude follows]

## Critical Rules
[Non-negotiable constraints]

## References
For design patterns, see `references/patterns.md`.
For troubleshooting, see `references/troubleshooting.md`.
```

### Level 3: Reference files (loaded on demand)
```markdown
# references/patterns.md
[Detailed pattern catalog — only loaded when needed]
```

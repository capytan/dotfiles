---
name: commit
description: Generate a Conventional Commits message and create the commit
---

# Create Commit with Conventional Commits Format

Analyze the staged changes and create a commit following the Conventional Commits specification.

## Current Git Status

```
!git status --short
```

## Staged Changes

```
!git diff --staged
```

## Instructions

Based on the staged changes above:

1. Generate a commit message following the Conventional Commits format:
   - Format: `<type>[optional scope]: <description>`
   - Types: feat, fix, docs, style, refactor, test, chore, perf, ci, build, revert
   - Description should be imperative, present tense ("add" not "added")
   - Keep the first line under 72 characters
   - If needed, add a blank line and then a more detailed explanation

2. Create the actual commit using the generated message

Examples:

- `feat(auth): add OAuth2 authentication`
- `fix: resolve memory leak in data processing`
- `docs: update API documentation for user endpoints`

Please analyze the changes, generate an appropriate commit message, and execute the commit.


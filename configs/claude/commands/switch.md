---
name: switch
description: Analyze changes and create a new branch with an appropriate name
---

# Create and Switch to New Branch

Analyze the current changes and create a new branch with an appropriate name based on the work being done.

## Current Git Status

```
!git status --short
```

## Staged Changes

```
!git diff --staged
```

## Unstaged Changes

```
!git diff
```

## Instructions

Based on the changes above:

1. Analyze the type and scope of changes to determine an appropriate branch name
2. Follow the naming convention: `<type>/<short-description>`
   - Types: feature, fix, refactor, docs, test, chore, hotfix
   - Use kebab-case for descriptions
   - Keep it concise but descriptive

3. Create and switch to the new branch using `git switch -c <branch-name>`

Examples:

- `feature/user-authentication`
- `fix/memory-leak-data-processing`
- `refactor/api-endpoints`
- `docs/update-readme`
- `test/add-unit-tests`

Please analyze the changes and create an appropriate branch.


---
name: switch
description: Analyze changes and create a new branch with an appropriate name
---

# Create and Switch to New Branch

Analyze the current changes and create a new branch with an appropriate name based on the work being done.

## Current Git Status

```bash
!git status --short
```

## Staged Changes

```bash
!git diff --staged
```

## Unstaged Changes

```bash
!git diff
```

## Instructions

Based on the changes above:

1. Analyze the type and scope of changes to determine an appropriate branch name

2. Follow the naming convention: `<type>/<short-description>`
   - Use types aligned with Conventional Commits (see Reference below)
   - Use kebab-case for descriptions (lowercase with hyphens)
   - Keep it concise but descriptive (2-4 words typically)
   - Avoid generic names; be specific about the change

3. Create and switch to the new branch using `git switch -c <branch-name>`

Examples:

- `feat/user-authentication`
- `feat/add-dark-mode-toggle`
- `fix/memory-leak-data-processing`
- `fix/login-button-disabled-state`
- `refactor/api-endpoints`
- `docs/update-readme`
- `test/add-unit-tests`
- `perf/optimize-image-loading`

Please analyze the changes and create an appropriate branch.

---

## Reference: Branch Naming Convention

### Type Definitions

| Type       | Description      | Use Case                              |
| ---------- | ---------------- | ------------------------------------- |
| `feat`     | New feature      | Adding new functionality              |
| `fix`      | Bug fix          | Fixing broken behavior                |
| `docs`     | Documentation    | README, comments, API docs            |
| `refactor` | Code refactoring | Restructuring without behavior change |
| `perf`     | Performance      | Optimization improvements             |
| `test`     | Testing          | Adding or fixing tests                |
| `build`    | Build system     | Dependencies, build scripts           |
| `ci`       | CI/CD            | Pipeline configuration                |
| `chore`    | Maintenance      | Cleanup, tooling, configs             |
| `hotfix`   | Urgent fix       | Critical production fixes             |

### Naming Rules

1. **Format**: `<type>/<short-description>`
2. **Case**: Use kebab-case (all lowercase, words separated by hyphens)
3. **Length**: Keep descriptions concise (2-4 words, max ~50 characters total)
4. **Specificity**: Be specific about what the branch accomplishes
5. **No special characters**: Avoid spaces, underscores, or special characters except hyphens

### Good Examples

| Branch Name                     | Why It's Good                   |
| ------------------------------- | ------------------------------- |
| `feat/user-profile-page`        | Clear type and specific feature |
| `fix/null-pointer-checkout`     | Describes the bug location      |
| `refactor/extract-auth-service` | Explains the refactoring action |
| `docs/api-endpoint-examples`    | Specific documentation target   |
| `perf/lazy-load-images`         | Clear optimization technique    |
| `test/payment-integration`      | Identifies test coverage area   |
| `ci/add-lint-workflow`          | Specific CI change              |
| `hotfix/payment-timeout`        | Urgent issue identifier         |

### Bad Examples (Anti-patterns)

| Branch Name            | Problem                            | Better Alternative           |
| ---------------------- | ---------------------------------- | ---------------------------- |
| `feature/update`       | Too vague                          | `feat/add-user-search`       |
| `fix/bug`              | Not descriptive                    | `fix/login-redirect-loop`    |
| `my-changes`           | Missing type prefix                | `feat/order-history`         |
| `feat/Add_New_Feature` | Wrong case, underscores            | `feat/add-new-feature`       |
| `fix/issue-123`        | Issue number alone not descriptive | `fix/cart-total-calculation` |
| `wip`                  | No type, too vague                 | `feat/checkout-flow`         |
| `test`                 | Missing description                | `test/user-service-unit`     |

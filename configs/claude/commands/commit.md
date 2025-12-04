---
name: commit
description: Generate a Conventional Commits message and create the commit
---

# Create Commit with Conventional Commits Format

Analyze the staged changes and create a commit following the Conventional Commits specification.

## Current Git Status

```bash
!git status --short
```

## Staged Changes

```bash
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
   - Do NOT include `Co-Authored-By` footer
   - Do NOT include `🤖 Generated with Claude Code` footer
   - Use only the commit message itself, without any signatures or attributions

Examples:

- `feat(auth): add OAuth2 authentication`
- `fix: resolve memory leak in data processing`
- `docs: update API documentation for user endpoints`

Please analyze the changes, generate an appropriate commit message, and execute the commit.

---

## Reference: Conventional Commits 1.0.0 Specification

### Message Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Type Definitions

| Type | Description | SemVer |
|------|-------------|--------|
| `feat` | Introduces a new feature | MINOR |
| `fix` | Patches a bug | PATCH |
| `docs` | Documentation only changes | - |
| `style` | Code style changes (formatting, semicolons, etc.) | - |
| `refactor` | Code change that neither fixes a bug nor adds a feature | - |
| `perf` | Performance improvements | - |
| `test` | Adding or correcting tests | - |
| `build` | Changes to build system or dependencies | - |
| `ci` | Changes to CI configuration | - |
| `chore` | Other changes that don't modify src or test files | - |
| `revert` | Reverts a previous commit | - |

### Breaking Changes

- Append exclamation mark after type/scope: feat! or feat(api)!
- Or add BREAKING CHANGE: footer
- Correlates with MAJOR in SemVer

### Specification Rules

1. Commits MUST be prefixed with a type, followed by OPTIONAL scope, OPTIONAL "!", and REQUIRED colon and space
2. A scope MUST be a noun describing a section of the codebase in parenthesis: `fix(parser):`
3. A description MUST immediately follow the type/scope prefix
4. A body MAY be provided after the description, beginning one blank line after
5. Footers MAY be provided one blank line after the body, using `token: value` or `token #value` format
6. BREAKING CHANGE MUST be uppercase when used as a footer token

### Examples

```
feat(lang): add Polish language
```

```
fix: prevent racing of requests

Introduce a request id and a reference to latest request.
Dismiss incoming responses other than from latest request.
```

```
feat(shipping)!: send email to customer when product is shipped
```

```
chore(node)!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

```
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

# False Positive Patterns

Shared catalog for all reviewers and scoring agents. Do not report findings matching these patterns.

## Pre-existing Issues

- **Off-diff bugs**: Bugs on lines not in the diff (exception: tag as [PRE-EXISTING])
- **Other authors' problems**: Issues added by other authors unrelated to this change (confirmed via git blame)
- **Real issues on unmodified lines**: The user did not change these lines in this PR

## Tooling Catches

- **Linter / formatter detectable**: ESLint, Prettier, Ruff, Clippy, etc.
- **Type checker detectable**: TypeScript, mypy, Flow, etc.
- **Compiler detectable**: Syntax errors, unused imports, build-time errors
- **Test detectable**: Bugs caught by existing test suites

## Intentional Patterns

- **Intentional TODO / HACK**: Temporary workarounds with explanatory comments
- **lint-ignore / type-ignore**: Explicitly suppressed warnings — issues silenced in code should not be flagged even if CLAUDE.md calls them out
- **Intentional type casts**: `as any`, `# type: ignore` with explicit override
- **Intentional behavior changes**: Changes mentioned in PR description or commit message

## Style & Convention

- **Pedantic style**: Newlines, indentation, naming preferences (unless explicit in CLAUDE.md)
- **Missing comments**: Lack of documentation/comments (unless required by CLAUDE.md)
- **Missing tests**: Insufficient test coverage (unless required by CLAUDE.md)
- **General quality**: "Could be written better" level observations that a senior engineer wouldn't flag

## Context-Dependent

- **Framework patterns**: Code following framework-recommended patterns (React useEffect deps, Django ORM, etc.)
- **Config file values**: Environment-specific values (ports, URLs)
- **Test code exceptions**: Intentional abnormal values, mocks, stubs in test files

## Low-Signal Patterns

- **"Might break" speculation**: "This could break if X happens" but no realistic path delivers X
- **Theoretical vulnerabilities**: Security issues with no attack surface (internal tools, local-only)
- **Performance speculation**: "Might be slow" without benchmarks or evidence

# False Positive Patterns

Shared catalog for all reviewers. Do not report findings matching these patterns.

## Pre-existing Issues

- **Off-diff bugs**: Bugs on lines not in the diff. Exception: report with [PRE-EXISTING] tag
- **Pre-existing problems**: Issues added by other authors unrelated to this change (confirmed via git blame)

## Tooling Catches

- **Linter / formatter detectable**: Issues caught by ESLint, Prettier, Ruff, Clippy, etc.
- **Type checker detectable**: Type errors caught by TypeScript, mypy, Flow, etc.
- **Compiler detectable**: Syntax errors, unused imports (caught at build time)
- **Test detectable**: Bugs caught by existing test suites (when tests exist)

## Intentional Patterns

- **Intentional TODO / HACK**: Temporary workarounds with explanatory comments
- **lint-ignore / type-ignore**: Explicitly suppressed warnings
- **Intentional type casts**: `as any`, `# type: ignore` with explicit override
- **Intentional behavior changes**: Changes mentioned in PR description or commit message

## Style & Convention

- **Pedantic style**: Newlines, indentation, naming preferences (unless explicit in CLAUDE.md)
- **Missing comments**: Lack of documentation/comments (unless required by CLAUDE.md)
- **Missing tests**: Insufficient test coverage (unless required by CLAUDE.md)
- **General quality**: "Could be written better" level observations

## Context-Dependent

- **Framework-specific patterns**: Code following framework-recommended patterns
  - e.g., React useEffect dependency arrays, Django N+1 (when ORM optimizes)
- **Config file values**: Environment-specific values (port numbers, URLs)
- **Test code exceptions**: Intentional abnormal values, mocks, stubs in tests

## Low-Signal Patterns

- **"Might break" level**: "This could break if X happens" but no path delivers X
- **Theoretical vulnerabilities**: Security issues in environments with no attack surface (internal tools, local-only)
- **Performance speculation**: "Might be slow" without benchmarks

## Reviewer-Specific Exceptions

### LOGIC
- Null safety issues already guaranteed by the type system (TypeScript strict mode, etc.)
- Branch exhaustiveness issues in languages with exhaustiveness checkers

### SECURITY
- Excessive validation demands on internal APIs (authenticated-user-only access)
- Security concerns on local-dev-only code

### EDGE
- Re-validation demands on already-validated inputs
- Boundary value concerns prevented by type constraints

### REGRESSION
- Intentional code replacement via refactoring (functionally equivalent rewrites)
- Deletion due to migration from deprecated APIs

### INFRA
- Environment variables already managed by existing CI/CD pipeline (confirmed in deployment configs)
- Infrastructure changes tracked in separate PRs/repos with linked issues
- Development/test-only configuration (test service, local storage, in-memory adapters)
- Environment variables with sensible defaults or fallback behavior in code
- Existing resources being reused (no new provisioning needed)

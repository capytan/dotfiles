# REGRESSION Reviewer Checklist

Detect regressions that are invisible from the diff alone, using git blame / git log.

## Git Analysis Procedure

### Step 1: Identify Changed Files

Extract the list of changed files from the diff.

### Step 2: Git Blame Analysis

For each changed file, check git blame around modified lines (10 lines before/after):

```bash
git blame -L <start>,<end> <file>
```

Check:
- Who added the deleted/modified lines and when
- Whether the commit message mentions bug fixes or security patches
- Whether lines added in the last 30 commits are now being removed

### Step 3: Git Log Analysis

Review the last 30 commits for each changed file:

```bash
git log -30 --oneline -- <file>
```

For each commit:
- Contains keywords: fix, bugfix, hotfix, patch, security, revert
- Whether this change reverts that commit's fix

### Step 4: Revert Detection

```bash
git log -30 --diff-filter=M -- <file>
```

Check if lines deleted in this diff match lines added by past bug-fix commits.

## Regression Patterns

### Reverted Bug Fixes

- [ ] Code added by bug-fix commits is being deleted
- [ ] Part of a security patch is being reverted
- [ ] Intentional guard clauses / validations removed

### Broken Contracts

- [ ] Function signature changes breaking callers
- [ ] Return type/structure changes breaking existing dependents
- [ ] Config file / env var format changes
- [ ] Breaking API endpoint changes

### Removed Intentional Code

- [ ] Deletion of code annotated as "important" or "required" in comments
- [ ] Deletion of TODO/FIXME/HACK-commented code (removed without fixing)
- [ ] Removing one side of a code-test pair
- [ ] Premature removal of feature flags or fallbacks

### Dependency Changes

- [ ] Package version downgrades
- [ ] Dependency removal causing feature loss
- [ ] Lock file / manifest mismatch

## Confidence Scoring

- **90-100**: Git blame confirms bug-fix code is clearly being deleted
- **80-89**: Commit history shows intentionally added code changed without reason
- **60-79**: Pattern suggests possible regression, but may be intentional
- **< 60**: Speculative

## Analysis Approach

1. Run git blame on changed files to understand history of deleted/modified lines
2. Identify commits containing bug-fix keywords
3. Verify this change does not break those fixes
4. Check caller impact for function signature or API changes
5. Base confidence on git history evidence, not speculation

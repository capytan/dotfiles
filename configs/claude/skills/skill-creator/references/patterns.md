# Skill Design Patterns

## 1. Sequential Workflow

**When to use**: Multi-step tasks with a clear linear order (document generation, data processing pipelines).

**Key techniques**:
- Numbered phases with explicit entry/exit criteria
- Checkpoint validation between phases
- Rollback strategy for each phase

**Structure example**:
```
## Phase 1: Input Validation
[validate inputs, fail fast on errors]

## Phase 2: Processing
[core logic, reference scripts/ if complex]

## Phase 3: Output Generation
[produce result, verify format]
```

## 2. Multi-MCP Orchestration

**When to use**: Tasks requiring multiple external services (GitHub + Slack, database + API).

**Key techniques**:
- Fully qualified tool references: `ServerName:tool_name`
- Fallback chains when a service is unavailable
- Explicit data flow between MCP calls

**Structure example**:
```
## Tools Required
- GitHub:search_repositories — find relevant repos
- Slack:post_message — notify team

## Workflow
1. Fetch data via GitHub:list_issues
2. Transform results
3. Post summary via Slack:post_message
```

## 3. Iterative Refinement

**When to use**: Quality-critical tasks where output improves through self-review cycles (code generation, writing).

**Key techniques**:
- Define "done" criteria upfront (measurable)
- Max iteration limit (typically 3) to prevent infinite loops
- Each iteration targets specific quality dimensions

**Structure example**:
```
## Generate
[produce initial output]

## Review (max 3 iterations)
Check against criteria:
- [ ] Correctness
- [ ] Completeness
- [ ] Style compliance
If any fail, revise and re-check.
```

## 4. Context-Aware Tool Selection

**When to use**: Tasks where the right approach depends on runtime context (file type, project structure, environment).

**Key techniques**:
- Decision tree based on detected context
- Glob/Grep to detect project type before acting
- Default path + escape hatches for edge cases

**Structure example**:
```
## Detect Context
1. Check for package.json → Node.js path
2. Check for pyproject.toml → Python path
3. Check for Cargo.toml → Rust path
4. Default → ask user

## Execute (per context)
[context-specific instructions]
```

## 5. Domain-Specific Intelligence

**When to use**: Tasks requiring specialized knowledge (security audits, accessibility checks, performance optimization).

**Key techniques**:
- Embed domain rules as checklists in SKILL.md or references/
- Severity classification (Critical/Major/Minor)
- Structured output format for consistent reporting

**Structure example**:
```
## Check Items
### [A] Category One
- Rule 1: [specific, testable criterion]
- Rule 2: [specific, testable criterion]

### [B] Category Two
...

## Output Format
[structured report template]
```

# Agent Quality Criteria

> Referenced during Phase 2 (Quality Assessment) for agent file reviews.
> Derived from agent-reviewer check items A–G.
>
> **Source tags:**
> - `[official]` = Anthropic official documentation
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[custom]` = Derived from this repo's own practice
> - `[custom:derived-from-agent-reviewer]` = Derived from agent-reviewer.md check items
>
> **Note:** Phase 0 research will update tags to official sources when found.

---

## Criteria & Scoring (100 points total)

### A. Frontmatter Correctness (15 points)

Validate the YAML frontmatter between `---` markers for required fields and value constraints.
`[custom:derived-from-agent-reviewer]`

**name field:**
- Present, 3–50 chars, pattern `^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$` → PASS
- Generic name (`helper`, `assistant`, `agent`, `tool`) → -3 pts
- Missing → 0 pts for entire category

**model field:**
- Present, value in `inherit | sonnet | opus | haiku` → PASS
- Unrecognized value → -2 pts
- Missing → 0 pts for entire category

**color field:**
- Present, value in `blue | cyan | green | yellow | magenta | red` → PASS
- Unrecognized value → -2 pts
- Missing → 0 pts for entire category

**tools field (if present):**
- Valid JSON array format → PASS
- Free-form string instead of array → -3 pts
- Unrecognized tool name → -1 pt each

**15 pts**: All required fields present and valid
**10 pts**: All present, minor warnings (generic name, unusual values)
**5 pts**: One required field missing or malformed
**0 pts**: Multiple required fields missing

### B. Description & Triggering Quality (20 points)

The description determines when the agent triggers. This is the single most important factor
for agent usefulness — a well-built agent that never fires is worthless.
`[custom:derived-from-agent-reviewer]`

**Length:** 10–5,000 characters required.
- Under 10 → 0 pts for entire category
- Over 5,000 → -3 pts

**"Use this agent when..." pattern:**
- Present prominently → PASS
- Missing → -4 pts

**`<example>` blocks:**
- 3–4 examples → full marks
- 2 examples → -2 pts
- Fewer than 2 → -6 pts
- Zero examples → 0 pts for entire category

**Example structure (each must contain):**
- `Context:` line, `user:` line, `assistant:` line, `<commentary>` block
- Missing any element → -2 pts per example

**Trigger coverage:**
- At least one Explicit trigger (direct user request) → required
- At least one Proactive trigger (auto-trigger after related work) → required
- Missing either type → -2 pts

**Phrasing variety:**
- User messages vary across examples → PASS
- All examples phrased identically → -1 pt

**20 pts**: 3+ well-structured examples, both trigger types, varied phrasing
**15 pts**: 2 good examples with minor gaps
**10 pts**: Examples present but missing structure or coverage
**5 pts**: Minimal description, fewer than 2 examples
**0 pts**: No description or effectively empty

### C. System Prompt Quality (25 points)

Combines length, style, and structure checks for the content after the closing `---`.
`[custom:derived-from-agent-reviewer]`

#### C1. Length (8 points)

- Under 100 characters → 0 pts (effectively empty; skip C2 and C3)
- 100–2,999 characters → 4 pts (too short for autonomous behavior; roughly under 500 words)
- 3,000–59,999 characters → 8 pts (acceptable range; roughly 500–10,000 words)
- 60,000+ characters → 4 pts (diminishing returns; recommend trimming)

#### C2. Style — Voice & Person (8 points)

Second person is required throughout the system prompt.

- Consistent second person (`You are`, `You will`, `Your`) → 8 pts
- Mostly second person with minor mixed usage → 6 pts
- Missing all second-person phrases → 0 pts
- First-person phrases (`I will`, `I am`) present → -4 pts
- Third-person phrases (`The agent will`, `This agent is`) present → -4 pts

#### C3. Structure (9 points)

Check for the presence of these structural elements:

- **Role definition** (`You are [role] specializing in [domain]`): 1 pt
- **Core Responsibilities** (3–8 numbered items): 2 pts (absent entirely → 0 pts, fewer than 3 → 1 pt)
- **Process steps** (concrete, ordered sequence): 2 pts (absent → 0 pts)
- **Output Format** (explicit definition of expected output): 2 pts (absent → 0 pts)
- **Edge Cases** (handling instructions for failure modes): 2 pts (absent → 1 pt)

### D. Tool Restriction (10 points)

Principle of least privilege for the `tools` array.
`[custom:derived-from-agent-reviewer]`

**If `tools` is specified:**
- Each listed tool is justified by the agent's described functionality → 10 pts
- `Write` or `Bash` listed without clear justification → -3 pts per unjustified tool
- Unused tools listed → -2 pts each

**If `tools` is not specified:**
- Agent has access to all tools — assess whether that is appropriate for its purpose
- Read-only agent with full tool access → -5 pts
- Agent needing broad tool access → 10 pts (advisory NOTE only)

### E. Anti-patterns (10 points)

Check for agent-specific anti-patterns.
`[custom:derived-from-agent-reviewer]`

See [agent-anti-patterns.md](agent-anti-patterns.md) for the full catalog.

**10 pts**: No anti-patterns detected
**7 pts**: 1–2 Minor anti-patterns
**4 pts**: 1 Major anti-pattern present
**2 pts**: Multiple Major anti-patterns
**0 pts**: Any Critical anti-pattern present

### F. Behavioral Impact (10 points)

Does the system prompt actually change how the agent behaves compared to a bare Claude session?
`[custom:derived-from-agent-reviewer]`

For each major section of the system prompt:
- **High**: Information that makes the agent decide or act differently
- **Medium**: Clarifies ambiguous situations toward the right choice
- **Low/None**: Claude would do this anyway, or it has no decision implication

**10 pts**: All sections High/Medium impact
**7 pts**: Low/None ≤ 20% of sections
**4 pts**: Low/None 30–50% of sections
**0 pts**: Low/None > 50% of sections

### G. Cross-Reference Consistency (10 points)

Verify the agent file is consistent with its environment.
`[custom:derived-from-agent-reviewer]`

**Checks:**
- Agent name in frontmatter matches the filename (minus `.md`) → required (-3 pts if mismatch)
- Tools listed in `tools` array are real, recognized tool names → required (-2 pts per unknown)
- System prompt references to files/paths are valid (spot-check with Glob) → -2 pts per broken ref
- No contradictions between description and system prompt responsibilities → -3 pts if conflicting
- Model tier is appropriate for the agent's complexity → advisory NOTE

**10 pts**: Fully consistent
**7 pts**: Minor mismatches (name casing, advisory notes)
**4 pts**: Broken references or tool mismatches
**0 pts**: Fundamental contradictions (description says X, prompt does Y)

---

## Grading Scale

| Grade | Score | Meaning |
|-------|-------|---------|
| S | 95-100 | Exemplary |
| A | 85-94 | Excellent |
| B | 70-84 | Good |
| C | 50-69 | Needs improvement |
| D | 30-49 | Insufficient |
| F | 0-29 | Not functioning |

---

## Changelog

- 2026-03-29: Initial version — derived from agent-reviewer.md check items A–G. All items tagged `[custom:derived-from-agent-reviewer]` pending Phase 0 research for official source validation.

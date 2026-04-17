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
> **Note:** Phase 0 research (2026-04-17) cross-checked against code.claude.com/docs/en/sub-agents.

last_updated: 2026-04-17

---

## Criteria & Scoring (100 points total)

### A. Frontmatter Correctness (15 points)

Validate the YAML frontmatter between `---` markers for required fields and value constraints. Only `name` and `description` are required per official docs `[official]`; `model`, `color`, and `tools` are optional.
`[custom:derived-from-agent-reviewer]` + `[official]`

**name field (required):**
- Present, lowercase letters and hyphens, 3–50 chars → PASS
- Generic name (`helper`, `assistant`, `agent`, `tool`) → -3 pts
- Missing → 0 pts for entire category

**description field (required):**
- Present, non-empty → PASS
- Missing → 0 pts for entire category (scored in detail in category B)

**model field (optional):**
- Absent → PASS (defaults to `inherit`)
- Present, value in `inherit | sonnet | opus | haiku` or full model ID (e.g., `claude-opus-4-7`) → PASS
- Unrecognized value → -2 pts

**color field (optional):**
- Absent → PASS (no default required)
- Present, value in `red | blue | green | yellow | purple | orange | pink | cyan` → PASS
- Unrecognized value (e.g., `magenta`, `white`) → -2 pts
  Source: https://code.claude.com/docs/en/sub-agents (retrieved 2026-04-17)

**tools field (optional):**
- Absent → PASS (inherits all)
- Present as comma-separated string or YAML array of recognized tool names → PASS
- Unrecognized tool name → -1 pt each

**15 pts**: All present required fields valid, optional fields valid if present
**10 pts**: Minor warnings (generic name, unusual optional values)
**5 pts**: One required field missing or malformed
**0 pts**: Multiple required fields missing

### B. Description & Triggering Quality (20 points)

The description determines when the agent triggers. This is the single most important factor
for agent usefulness — a well-built agent that never fires is worthless.
`[custom:derived-from-agent-reviewer]` + `[official]` + `[community:high]`

**Two accepted styles (either satisfies this category):**

Official Anthropic examples use a **prose-only** description (no `<example>` blocks).
Many community collections use an **`<example>`-block** style (Context / user / assistant / `<commentary>`).
Both are valid. Score the style the author chose against its own rubric below.

**Length:** 10–5,000 characters.
- Under 10 → 0 pts for entire category
- Over 5,000 → -3 pts

**Trigger language (both styles):**
- Description includes a clear "when to use" clause (e.g., "Use proactively after…", "Use when…", "Use immediately after…") → required
- Missing any trigger clause → -4 pts
- Proactive trigger word (`proactively`, `immediately`, `PROACTIVELY`, `MUST BE USED`) present when auto-delegation is desired → +0 (expected)
- Note: `"use proactively"` is the only trigger phrase in official docs; `MUST BE USED` is a community convention `[community:high]`

**Action-verb specificity `[community:high]`:**
- Description contains a concrete action verb (`review`, `analyze`, `optimize`, `audit`, `debug`, `generate`, `refactor`) → PASS
- Purely capability-based description without action verb ("security expert") → -3 pts

#### B1. Prose-style scoring (official-aligned)

- Specific trigger conditions stated (what event, what file type, what user intent) → 8 pts
- Role/expertise area stated in a few words → 4 pts
- Action-verb recall hook present → 4 pts
- Length 80–600 characters (matches all four official examples) → 4 pts
- No behavioral instructions bleeding into description (routing only) → deduction-only: mixing instructions → -3 pts

#### B2. `<example>`-block scoring (community-aligned)

- 2–4 `<example>` blocks → 8 pts (3 recommended)
- Fewer than 2 → -6 pts; zero → 0 pts for entire category
- Each example contains `Context:`, `user:`, `assistant:`, and `<commentary>` → 4 pts
- At least one explicit trigger + at least one proactive trigger example → 4 pts
- User-message phrasing varies across examples → 4 pts

**20 pts**: Top-tier in either style (crisp prose OR 3+ well-formed examples covering both trigger types)
**15 pts**: Good but missing one dimension (no proactive trigger, or no action verb)
**10 pts**: Description present but vague or lacking trigger clause
**5 pts**: Minimal description, unclear when the agent fires
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

Based on the 5-part pattern shared by all four documented official example agents (code-reviewer, debugger, data-scientist, db-reader) `[official]` and the community five-layer blueprint `[community:high]`:

- **Role / Identity opener** (`You are a [qualifier] [role] [specializing in / ensuring X]`): 1 pt
- **"When invoked:" action sequence** (3–6 numbered steps, concrete and ordered): 2 pts (absent → 0 pts, fewer than 3 → 1 pt)
- **Domain checklist / key practices** (bullet list of concerns, techniques, or responsibilities): 2 pts (absent → 0 pts)
- **Output Format** (explicit priority labels, sections, or JSON/Markdown contract): 2 pts (absent → 0 pts)
- **Focus statement / edge-case handling** (single-sentence priority reminder OR conditional instructions for failure modes): 2 pts (absent → 1 pt)

The official examples omit a separate "Edge Cases" section and substitute a closing focus statement (e.g., "Focus on fixing the underlying issue, not the symptoms."). Either is acceptable.

### D. Tool Restriction (10 points)

Principle of least privilege for the `tools` array. Official guidance: "Limit tool access: grant only necessary permissions for security and focus." `[official]`
Community-standard role tiers `[community:high]`:

| Role | Recommended tools |
|------|-------------------|
| Read-only reviewer / auditor | `Read, Grep, Glob` (add `Bash` if `git diff` etc. is needed — official code-reviewer includes Bash) |
| Research / information gatherer | `Read, Grep, Glob, WebFetch, WebSearch` |
| Code writer / implementer | `Read, Write, Edit, Bash, Glob, Grep` |
| Documentation agent | `Read, Write, Edit, Glob, Grep, WebFetch, WebSearch` |

**If `tools` is specified:**
- Each listed tool is justified by the agent's described functionality → 10 pts
- `Write` or `Edit` listed on a read-only/review agent → -3 pts per unjustified tool
- `Bash` on an agent with no shell-execution responsibility → -3 pts (exception: read-only agents that `git diff` or run validators)
- Unused tools listed → -2 pts each

**If `tools` is not specified:**
- Agent inherits all tools. Scoring depends on described behavior.
- Read-only/review agent with no `tools` restriction → -5 pts (violates least-privilege; official quickstart explicitly says to deselect everything except Read-only tools for reviewers)
- Writer/coordinator agent needing broad access → 10 pts (advisory NOTE only)
- Consider `disallowedTools` denylist as an alternative (useful when mostly-full access is wanted except a few sensitive tools)

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
- 2026-04-17: Refreshed against code.claude.com/docs/en/sub-agents.
  - **A. Frontmatter**: `color` palette corrected to `red | blue | green | yellow | purple | orange | pink | cyan` (was `blue | cyan | green | yellow | magenta | red`). Clarified `model`/`color` as optional. Accept full model IDs. Accept comma-separated string for `tools` (YAML-native, not just JSON array).
  - **B. Description**: Rewrote to accept both official prose-only style and community `<example>`-block style as equally valid. Added action-verb specificity check (-3 pts for capability-only descriptions). Split scoring into B1 (prose) and B2 (`<example>`-block) branches. `MUST BE USED` flagged as community convention, not official.
  - **C3. Structure**: Replaced with the 5-part official pattern (Identity / "When invoked:" steps / Checklist / Output format / Focus or edge-case statement). Edge-case section no longer mandatory — closing focus statement is an accepted substitute.
  - **D. Tool Restriction**: Added role-tier table (read-only / research / writer / docs) sourced from VoltAgent/awesome-claude-code-subagents. Noted that official code-reviewer example includes `Bash` for `git diff` — pure `Read/Grep/Glob` is stricter but not required. Added `disallowedTools` as denylist alternative.

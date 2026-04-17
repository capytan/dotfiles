# Quality Criteria

last_updated: 2026-04-17

> Referenced during Phase 2 (Quality Assessment).
> Updated based on Phase 0 research findings.
>
> **Source tags:**
> - `[official]` = Anthropic official documentation
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[custom]` = Derived from this repo's own practice

---

## Criteria & Scoring (100 points total)

### A. Token Efficiency (20 points)

CLAUDE.md is loaded every session. Evaluate whether each line justifies its token cost.

**Line count thresholds** `[official]` + `[semi-official]` + `[community:high]`
Official docs: "target under 200 lines per CLAUDE.md file" (code.claude.com/docs/en/memory).
Boris Cherny (Claude Code creator): ~100 lines / ~2,500 tokens is his personal config. His team's `~/.claude/CLAUDE.md` is ~76 tokens; project CLAUDE.md is ~4k tokens.
HumanLayer (Nov 2025): "general consensus is that under 300 lines is best, and shorter is even better. At HumanLayer, the root CLAUDE.md file is less than sixty lines."
abhishekray07 (2026): "if your project CLAUDE.md is over 80 lines, Claude starts ignoring parts of it" — and frontier models reliably follow ~150–200 total instructions, ~50 of which are consumed by Claude Code's system prompt.
- Under 80 lines → ideal (20 pts)
- 80–150 lines → good (17 pts)
- 150–200 lines → acceptable, within official target (13 pts)
- 200–300 lines → over official target, review for trimming (8 pts)
- Over 300 lines → strongly recommend splitting (4 pts)
- Over 500 lines → immediate action needed (0 pts)

**Inferable content detection** `[official]`
Flag content Claude already knows without being told (official Exclude list):
- Anything Claude can figure out by reading code
- Standard language conventions Claude already knows
- Detailed API documentation (should link to docs instead)
- Long explanations or tutorials
- File-by-file descriptions of the codebase
- Self-evident practices like "write clean code"

Each inferable item: -2 pts (max -10 pts).

**Hook-convertible rules detection** `[semi-official]` + `[community:high]`
Flag rules that should be hooks instead of CLAUDE.md instructions:
- Absolute restrictions ("NEVER use rm -rf") — should be PreToolUse hooks
- Formatting requirements — should be PostToolUse hooks
- Security restrictions — should be enforced deterministically

Each hook-convertible rule: -1 pt (max -5 pts). Note: keeping the guidance in CLAUDE.md as documentation alongside a hook is fine; the issue is relying solely on CLAUDE.md for enforcement.

### B. Commands & Workflows (15 points)

`[official]` Are the project's essential commands documented?

**15 pts**: All essential commands covered
- Build, test, lint, dev server documented
- Commands are copy-paste ready
- Platform-specific commands (OS differences, etc.) are distinguished

**10 pts**: Most commands present, some gaps

**5 pts**: Basic commands only

**0 pts**: No commands documented

### C. Architecture Clarity (15 points)

`[official]` Can Claude quickly grasp the codebase structure?

**15 pts**: Clear structure
- Directory layout explained
- Key module relationships documented
- Entry points identifiable

**10 pts**: Basic structure overview

**5 pts**: Directory listing only (no explanation)

**0 pts**: No structure info

### D. Non-Obvious Patterns (15 points)

`[official]` Project-specific knowledge Claude can't reach by inference alone.

**15 pts**: Rich gotchas & workarounds
- Known issues and their fixes
- "Why we do it this way" for non-obvious design decisions
- Environment-specific caveats
- Dependency ordering constraints

**10 pts**: Some patterns documented

**5 pts**: Minimal

**0 pts**: None

### E. Actionability (15 points)

`[official]` Are instructions concrete and copy-paste executable?

**15 pts**: All instructions concrete
- Commands actually run
- File paths exist
- Steps are unambiguous and reproducible

**10 pts**: Mostly concrete, some vagueness

**5 pts**: Noticeable vague instructions ("properly configure", "follow best practices", etc.)

**0 pts**: Abstract or theoretical only

**Examples of vague instructions:**
- "properly format code" → specify the formatter and command
- "follow best practices" → state which practices
- "use appropriate tools" → name the tools

### F. Anti-patterns (10 points)

`[official]` + `[custom]` Does the file contain known problem patterns?

See [claude-md-anti-patterns.md](claude-md-anti-patterns.md) for the full catalog.

**10 pts**: No anti-patterns
**7 pts**: 1-2 Minor anti-patterns
**4 pts**: Major anti-pattern present
**0 pts**: Critical anti-pattern present (e.g., secrets)

### G. Behavioral Impact (10 points)

`[custom]` Does each section actually change Claude's decisions?

For each top-level section:
- **High**: Information that makes Claude decide differently
- **Medium**: Clarifies ambiguous situations toward the right choice
- **Low/None**: Claude can already infer this, or it has no decision implication

Deduct when Low/None exceeds 30% of total sections.

**10 pts**: All sections High/Medium
**7 pts**: Low/None ≤ 20%
**4 pts**: Low/None 30–50%
**0 pts**: Low/None > 50%

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

- 2025-05-01: Initial version
- 2026-03-29: Updated line count thresholds with official 200-line target and Boris Cherny's ~100-line reference. Expanded inferable content detection to match official Exclude list. Added hook-convertible rules detection sub-criterion under Token Efficiency (semi-official + community:high).
- 2026-04-17: Tightened line-count thresholds: new "ideal" bar is under 80 lines (HumanLayer 60-line benchmark + abhishekray07 "80 lines → Claude starts ignoring" finding) with a 6-tier rubric. Added note on the ~150–200 total-instruction budget (~50 used by Claude Code's system prompt). Cited specific Boris token numbers (user 76 / project 4k).

# Quality Criteria

last_updated: 2026-11-19

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

## Contents

Criteria & Scoring (100 points total):
- A. Token Efficiency (20)
- B. Commands & Workflows (15)
- C. Non-Derivable Structure (10)
- D. Non-Obvious Patterns (20)
- E. Actionability (15)
- F. Anti-patterns (10)
- G. Behavioral Impact (10)

Plus: Grading Scale

## Criteria & Scoring (100 points total)

### A. Token Efficiency (20 points)

CLAUDE.md is loaded every session. Evaluate whether each line justifies its token cost.

**Line count thresholds** `[official]` + `[semi-official]` + `[community:high]`
Official docs: "target under 200 lines per CLAUDE.md file" (code.claude.com/docs/en/memory).
Boris Cherny (Claude Code creator): ~100 lines / ~2,500 tokens is his personal config. His team's `~/.claude/CLAUDE.md` is ~76 tokens; project CLAUDE.md is ~4k tokens.
HumanLayer (Nov 2025): "general consensus is that under 300 lines is best, and shorter is even better. At HumanLayer, the root CLAUDE.md file is less than sixty lines." HumanLayer also states frontier models reliably follow ~150–200 total instructions, ~50 of which are consumed by Claude Code's system prompt (re-verified 2026-06-10, www.humanlayer.dev/blog/writing-a-good-claude-md).
abhishekray07 (2026): "if your project CLAUDE.md is over 80 lines, Claude starts ignoring parts of it".
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

**Official inferability test (added 2026-10-28)** `[official]`: "1. Could it find this by reading the code? 2. Would it actually go and look? If both are yes, leave it out." (code.claude.com/docs/en/best-practices, retrieved 2026-10-28). Deduct only when **both** answers are yes. Not inferable: facts that are in the repo "but take a few minutes of digging to find" every session (e.g. which of three test runners is canonical), and "Places where the code is misleading: an old pattern that's everywhere but that new code must not copy, or a directory that looks unused but isn't".

**Hook-convertible rules detection** `[semi-official]` + `[community:high]`
Flag rules that should be hooks instead of CLAUDE.md instructions:
- Absolute restrictions ("NEVER use rm -rf") — should be PreToolUse hooks
- Formatting requirements — should be PostToolUse hooks
- Security restrictions — should be enforced deterministically

Each hook-convertible rule: -1 pt (max -5 pts). Note: keeping the guidance in CLAUDE.md as documentation alongside a hook is fine; the issue is relying solely on CLAUDE.md for enforcement.
Now official (best-practices, retrieved 2026-10-28): "If something has to happen every time, make it a hook, a deny rule, or a managed setting. `CLAUDE.md` is for guidelines" — but "a hook is for a rule with *zero* exceptions, and `Prefer named exports` has plenty, so that one stays in `CLAUDE.md`." **Do not deduct** for preferences with legitimate exceptions; only zero-exception rules count.
**Emphasis dilution (added 2026-09-04)** `[official]`
Official best-practices now says: "If Claude keeps skipping one instruction, add emphasis such as 'IMPORTANT' to that line alone. If you emphasize many lines, none of them stands out." Widespread IMPORTANT/YOU MUST markers are scored under criterion F as the Minor anti-pattern **Emphasis Overuse** (see the catalog); do not additionally deduct here — this note exists so assessors don't treat heavy emphasis as an adherence *positive*.
**Superseded wording (2026-10-28)**: the rewritten best-practices page drops the "to that line alone" advice and lists "Add IMPORTANT or ALL CAPS to instructions Claude keeps missing" under "What you can stop doing" ("Current ones follow a plainly worded line, and piling on emphasis mostly makes Claude over-apply the rule"). Scoring is unchanged (still Minor under F for widespread use); one or two emphasized lines are now an advisory note, not a neutral practice.
Second official source (retrieved 2026-09-16): the platform prompting guide says newer models "are also more responsive to the system prompt than previous models … The fix is to dial back any aggressive language. Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'." (platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**Model-era workarounds (added 2026-09-16)** `[official]`
The large-codebases page: "Revisit after major model releases: instructions that worked around an older model's limitation may become overhead once a newer model handles the case on its own. For example, a rule that forces single-file refactors can be deleted once the limitation is gone." The Fable 5 prompting page: "Instruction-following is improved enough that you can steer most behaviors with a brief instruction rather than enumerating each behavior by name" and "Capability improvements at this level are also a good prompt to re-evaluate which instructions, tools, and guardrails are still needed."
Scoring consequence: a rule that exists only to compensate for a behavior current models no longer exhibit (forced single-file edits, "always summarize after each tool call", enumerated lists of every case a one-line instruction already covers) is **inferable/obsolete content** — apply the inferable-content deduction (-2 each, within the existing -10 cap) and flag it under F as the Stale Information detection pattern. Do not deduct twice for the same line.
**Extended 2026-09-24 with per-model official "remove this" lists** (platform.claude.com prompting pages for Opus 5, Opus 5.5, Fable 5.1, retrieved 2026-09-24): generic "verify / double-check / re-verify / use a subagent to verify" instructions (Opus 5: "cause over-verification … removing them reduces wasted tokens with no loss in quality"), "think carefully before answering" (Opus 5.5: "The model decides for itself how much to think, and effort is the main control"), narration suppression such as "hold all findings for the final response" and blanket anti-formatting rules (Fable 5.1), and "don't think/reason" rules (Opus 5). Same -2 schedule. Anthropic's blog (2026-07-24) frames the whole category: "we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills" and removed "over 80% of Claude Code's system prompt … with no measurable loss on our coding evaluations" (claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models).
**Exemptions (2026-09-24)**: (1) a concrete runnable check (`bash test.sh`, `herdr config check`) is *not* a verification workaround — it is the official "give Claude a check it can run" practice and earns B/E credit; (2) lines adapted from an official per-model prompt block (Fable 5.1 "Keep changes and tests to what the task asks for" / "Delivering work", Opus 5 scope block, Fable 5.1 surgical-edit line) are recommended additions, not inferable content — do not deduct under A. Flag them only when the block was measured on a different model than the file targets **and** the official page documents a behavioral difference ("Where a technique names a specific model, treat it as measured on that model and re-check it against your own evals before applying it to another"). For a user-global CLAUDE.md used with several models (e.g. Opus 5.5 by default, Fable 5.1 for planning), a Fable 5.1-sourced block is advisory-only: note it, no deduction.
**Extended 2026-10-28** (best-practices "What you can stop doing", retrieved 2026-10-28): "keep going / loop until done / don't be lazy" lines ("more likely to cause over-work than fix a stall") and "think hard / think harder / be thorough" ("Effort is the control for that") join the list, same -2 schedule. Exempt: `ultrathink` ("still works"), and a concrete check to pass ("Giving Claude a check to pass is different, and still worth doing").
**Reasoning-reproduction instructions** ("show your reasoning in the response") are *not* scored here — they are the Major anti-pattern under F because they can trigger `reasoning_extraction` refusals on Fable 5/5.1 and Opus 5.5.

**AGENTS.md interplay (advisory, added 2026-09-24)** `[official]`
Since v2.1.277 Claude Code reads AGENTS.md natively when no `CLAUDE.md`/`.claude/CLAUDE.md`/`CLAUDE.local.md` exists in the working directory or above; with a CLAUDE.md present, AGENTS.md is ignored unless **Project instructions** is `claude-md-and-agents-md` (memory#agents-md). No deduction under A for a thin CLAUDE.md that is only `@AGENTS.md` plus Claude-specific lines — that is the official shared-file pattern. v2.1.281 made the "large CLAUDE.md" startup notice count instruction files together ("so many mid-sized files and @-imports are caught") — when scoring line count for a CLAUDE.md with imports, note the aggregate loaded size, but keep the -points schedule on the file itself.

**Per-subagent cost (advisory, added 2026-09-16)** `[official]`
Every non-Explore/Plan subagent loads "every level of the CLAUDE.md hierarchy the main conversation loads" into its own context (sub-agents doc, retrieved 2026-09-16; the context-window page illustrates ~1,800 tokens for a project CLAUDE.md, paid again per subagent). No separate deduction — it reinforces the existing line-count schedule for repos that fan out to subagents.

**`/doctor` trim baseline (added 2026-07-25)** `[official]`
As of v2.1.206 the `/doctor` checkup proposes trims for a checked-in CLAUDE.md, and its rule matches this criterion: "it cuts content Claude can derive from the codebase, such as **directory layouts, dependency lists, and architecture overviews**, and keeps **pitfalls, rationale, and conventions that differ from tool defaults**" (code.claude.com/docs/en/memory, retrieved 2026-07-25).
Scoring consequence: this puts official weight behind trimming directory layouts and architecture overviews — the same material category C (Non-Derivable Structure, formerly Architecture Clarity) used to reward. **Resolve the tension in favor of non-inferability**: award C for structure that is *not* derivable by reading the tree (module relationships, why a boundary exists, which entry point matters), and apply the inferable-content deduction under A to a plain directory listing or dependency enumeration. Do not award C points for content that A penalizes.

### B. Commands & Workflows (15 points)

`[official]` Are the project's essential commands documented?

**15 pts**: All essential commands covered
- Build, test, lint, dev server documented
- How to run a single test file (official include list, 2026-10-28: "the exact test, typecheck, and lint commands, and how to run a single test file")
- Commands are copy-paste ready
- Platform-specific commands (OS differences, etc.) are distinguished

Check-command cap (2026-11-19; replaces the 2026-09-16 `[community:mid]` tie-breaker) `[official]` + `[custom]` for the cap value: best-practices says "If your repo already has one of these [a test file, a build's exit code, a linter, a script that diffs output against a fixture, a browser screenshot next to the mockup], the single most useful line in your `CLAUDE.md` is the command that runs it" (code.claude.com/docs/en/best-practices, retrieved 2026-11-19). A file that omits the repo's existing check command cannot score above **10** on B, whatever else it lists. The official example also lists an `Install` command, and the page says to "keep the install command in `CLAUDE.md` so Claude runs it whenever it starts in a new checkout" — count a missing install/setup command as a gap (15 → 10) when the repo needs one before tests run.

**10 pts**: Most commands present, some gaps

**5 pts**: Basic commands only

**0 pts**: No commands documented

### C. Non-Derivable Structure (10 points)

`[official]` Does the file record the structural knowledge Claude can't read from the tree? (Renamed from "Architecture Clarity" and cut from 15 to 10 points on 2026-10-28; the 5 points moved to D.)

Award only for structure that is **not** derivable by reading the tree — see the `/doctor` trim baseline under criterion A.

**Official reframe (2026-10-28)** `[official]`: best-practices now lists "Describe your architecture and file layout in `CLAUDE.md`" under "What you can stop doing" ("Claude reads the repo itself. Only write down what isn't in there."), and its include list keeps "Places where the code is misleading" and "Decisions that aren't in the repo". Score C as **structural knowledge Claude can't read from the tree**, and do not penalize a file for omitting architecture Claude can read. (Conflict note: the memory page still names "project layout" and "architectural decisions" as CLAUDE.md content — reconciled as "decisions and misleading places stay, readable layout goes".)

**10 pts**: Non-derivable structure documented
- Misleading places flagged (legacy pattern not to copy, directory that looks unused but isn't)
- Why a boundary exists / off-repo architectural decisions
- Which entry point matters when several exist

**7 pts**: Some non-derivable structure, **or** no architecture section at all where the reviewer finds no misleading area or off-repo decision the file should have mentioned (correct omission — 2026-10-28; previously 0)

**3 pts**: Thin — architecture prose that is mostly derivable, with one or two non-derivable facts

**0 pts**: A plain directory listing / dependency enumeration only (inferable content — already penalized under A; award 0 here rather than double-crediting it), **or** no structure info while the repo has a misleading area or off-repo decision the reviewer can name

### D. Non-Obvious Patterns (20 points)

`[official]` Project-specific knowledge Claude can't reach by inference alone. (Raised from 15 to 20 points on 2026-10-28: the official include list — misleading code, off-repo decisions, things corrected twice — is mostly this category.)

**20 pts**: Rich gotchas & workarounds
- Known issues and their fixes
- "Why we do it this way" for non-obvious design decisions
- Environment-specific caveats
- Dependency ordering constraints
- Anything Claude has had to be corrected on twice (official include list, 2026-10-28)

**14 pts**: Some patterns documented

**7 pts**: Minimal

**0 pts**: None

### E. Actionability (15 points)

`[official]` Are instructions concrete and copy-paste executable?

**15 pts**: All instructions concrete
- Commands actually run
- File paths exist (if the user has run `/doctor prompt-audit` (v2.1.283+), its stale-path/stale-command findings are direct evidence here)
- Steps are unambiguous and reproducible

**10 pts**: Mostly concrete, some vagueness

**5 pts**: Noticeable vague instructions ("properly configure", "follow best practices", etc.)

**0 pts**: Abstract or theoretical only

**Examples of vague instructions:**
- "properly format code" → specify the formatter and command
- "follow best practices" → state which practices
- "use appropriate tools" → name the tools

**Rationale for non-obvious rules (added 2026-09-24)** `[official]`
Official prompting guidance: "Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude better understand your goals" — "NEVER use ellipses" is the documented *less effective* form; the same rule with its reason is *more effective*, and "Claude is smart enough to generalize from the explanation" (claude-prompting-best-practices, retrieved 2026-09-24). Fable 5: "Give the reason, not only the request." Scoring: when choosing between 10 and 15, a file whose prohibitions/exceptions carry a one-clause reason where the reason isn't self-evident (e.g. "ask, not deny, because deny leaves no approval path") beats one of bare NEVER/ALWAYS rules. Cap: a file with 3+ bare, reason-less prohibitions whose rationale isn't obvious scores at most 10. Do not penalize rules whose reason is self-evident ("don't commit secrets").

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

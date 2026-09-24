# Quality Criteria

last_updated: 2026-09-24

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
- C. Architecture Clarity (15)
- D. Non-Obvious Patterns (15)
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

**Hook-convertible rules detection** `[semi-official]` + `[community:high]`
Flag rules that should be hooks instead of CLAUDE.md instructions:
- Absolute restrictions ("NEVER use rm -rf") — should be PreToolUse hooks
- Formatting requirements — should be PostToolUse hooks
- Security restrictions — should be enforced deterministically

Each hook-convertible rule: -1 pt (max -5 pts). Note: keeping the guidance in CLAUDE.md as documentation alongside a hook is fine; the issue is relying solely on CLAUDE.md for enforcement.

**Emphasis dilution (added 2026-09-04)** `[official]`
Official best-practices now says: "If Claude keeps skipping one instruction, add emphasis such as 'IMPORTANT' to that line alone. If you emphasize many lines, none of them stands out." Widespread IMPORTANT/YOU MUST markers are scored under criterion F as the Minor anti-pattern **Emphasis Overuse** (see the catalog); do not additionally deduct here — this note exists so assessors don't treat heavy emphasis as an adherence *positive*.
Second official source (retrieved 2026-09-16): the platform prompting guide says newer models "are also more responsive to the system prompt than previous models … The fix is to dial back any aggressive language. Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'." (platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**Model-era workarounds (added 2026-09-16)** `[official]`
The large-codebases page: "Revisit after major model releases: instructions that worked around an older model's limitation may become overhead once a newer model handles the case on its own. For example, a rule that forces single-file refactors can be deleted once the limitation is gone." The Fable 5 prompting page: "Instruction-following is improved enough that you can steer most behaviors with a brief instruction rather than enumerating each behavior by name" and "Capability improvements at this level are also a good prompt to re-evaluate which instructions, tools, and guardrails are still needed."
Scoring consequence: a rule that exists only to compensate for a behavior current models no longer exhibit (forced single-file edits, "always summarize after each tool call", enumerated lists of every case a one-line instruction already covers) is **inferable/obsolete content** — apply the inferable-content deduction (-2 each, within the existing -10 cap) and flag it under F as the Stale Information detection pattern. Do not deduct twice for the same line.
**Extended 2026-09-24 with per-model official "remove this" lists** (platform.claude.com prompting pages for Opus 5, Opus 5.5, Fable 5.1, retrieved 2026-09-24): generic "verify / double-check / re-verify / use a subagent to verify" instructions (Opus 5: "cause over-verification … removing them reduces wasted tokens with no loss in quality"), "think carefully before answering" (Opus 5.5: "The model decides for itself how much to think, and effort is the main control"), narration suppression such as "hold all findings for the final response" and blanket anti-formatting rules (Fable 5.1), and "don't think/reason" rules (Opus 5). Same -2 schedule. Anthropic's blog (2026-07-24) frames the whole category: "we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills" and removed "over 80% of Claude Code's system prompt … with no measurable loss on our coding evaluations" (claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models).
**Exemptions (2026-09-24)**: (1) a concrete runnable check (`bash test.sh`, `herdr config check`) is *not* a verification workaround — it is the official "give Claude a check it can run" practice and earns B/E credit; (2) lines adapted from an official per-model prompt block (Fable 5.1 "Keep changes and tests to what the task asks for" / "Delivering work", Opus 5 scope block, Fable 5.1 surgical-edit line) are recommended additions, not inferable content — do not deduct under A. Flag them only when the block was measured on a different model than the file targets **and** the official page documents a behavioral difference ("Where a technique names a specific model, treat it as measured on that model and re-check it against your own evals before applying it to another"). For a user-global CLAUDE.md used with several models (e.g. Opus 5.5 by default, Fable 5.1 for planning), a Fable 5.1-sourced block is advisory-only: note it, no deduction.
**Reasoning-reproduction instructions** ("show your reasoning in the response") are *not* scored here — they are the Major anti-pattern under F because they can trigger `reasoning_extraction` refusals on Fable 5/5.1 and Opus 5.5.

**AGENTS.md interplay (advisory, added 2026-09-24)** `[official]`
Since v2.1.277 Claude Code reads AGENTS.md natively when no `CLAUDE.md`/`.claude/CLAUDE.md`/`CLAUDE.local.md` exists in the working directory or above; with a CLAUDE.md present, AGENTS.md is ignored unless **Project instructions** is `claude-md-and-agents-md` (memory#agents-md). No deduction under A for a thin CLAUDE.md that is only `@AGENTS.md` plus Claude-specific lines — that is the official shared-file pattern. v2.1.281 made the "large CLAUDE.md" startup notice count instruction files together ("so many mid-sized files and @-imports are caught") — when scoring line count for a CLAUDE.md with imports, note the aggregate loaded size, but keep the -points schedule on the file itself.

**Per-subagent cost (advisory, added 2026-09-16)** `[official]`
Every non-Explore/Plan subagent loads "every level of the CLAUDE.md hierarchy the main conversation loads" into its own context (sub-agents doc, retrieved 2026-09-16; the context-window page illustrates ~1,800 tokens for a project CLAUDE.md, paid again per subagent). No separate deduction — it reinforces the existing line-count schedule for repos that fan out to subagents.

**`/doctor` trim baseline (added 2026-07-25)** `[official]`
As of v2.1.206 the `/doctor` checkup proposes trims for a checked-in CLAUDE.md, and its rule matches this criterion: "it cuts content Claude can derive from the codebase, such as **directory layouts, dependency lists, and architecture overviews**, and keeps **pitfalls, rationale, and conventions that differ from tool defaults**" (code.claude.com/docs/en/memory, retrieved 2026-07-25).
Scoring consequence: this puts official weight behind trimming directory layouts and architecture overviews — the same material category C (Architecture Clarity) rewards. **Resolve the tension in favor of non-inferability**: award C for structure that is *not* derivable by reading the tree (module relationships, why a boundary exists, which entry point matters), and apply the inferable-content deduction under A to a plain directory listing or dependency enumeration. Do not award C points for content that A penalizes.

### B. Commands & Workflows (15 points)

`[official]` Are the project's essential commands documented?

**15 pts**: All essential commands covered
- Build, test, lint, dev server documented
- Commands are copy-paste ready
- Platform-specific commands (OS differences, etc.) are distinguished

Tie-breaker (added 2026-09-16, `[community:mid]`): when deciding between 10 and 15, weigh the **exact test command** most heavily — community guidance calls it "the single highest-ROI line" (dev.to/nishilbhave), and it maps to the official Include row "Testing instructions and preferred test runners".

**10 pts**: Most commands present, some gaps

**5 pts**: Basic commands only

**0 pts**: No commands documented

### C. Architecture Clarity (15 points)

`[official]` Can Claude quickly grasp the codebase structure?

Award only for structure that is **not** derivable by reading the tree — see the `/doctor` trim baseline under criterion A.

**15 pts**: Clear structure
- Key module relationships documented
- Why a boundary exists / which entry point matters
- Entry points identifiable

**10 pts**: Basic structure overview

**5 pts**: Some non-inferable context, but thin

**0 pts**: No structure info, **or** a plain directory listing / dependency enumeration only (inferable content — already penalized under A; award 0 here rather than double-crediting it)

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

---

## Changelog

- 2025-05-01: Initial version
- 2026-03-29: Updated line count thresholds with official 200-line target and Boris Cherny's ~100-line reference. Expanded inferable content detection to match official Exclude list. Added hook-convertible rules detection sub-criterion under Token Efficiency (semi-official + community:high).
- 2026-04-17: Tightened line-count thresholds: new "ideal" bar is under 80 lines (HumanLayer 60-line benchmark + abhishekray07 "80 lines → Claude starts ignoring" finding) with a 6-tier rubric. Added note on the ~150–200 total-instruction budget (~50 used by Claude Code's system prompt). Cited specific Boris token numbers (user 76 / project 4k).
- 2026-05-30: No material change to scoring criteria. 2026-05-30 research confirmed official line-count thresholds (under 200) and the ~150–200 instruction budget are unchanged. New community insight (CLAUDE.md churn invalidates prompt cache — community:mid) noted in community-practices but not strong enough to alter Token Efficiency scoring; recorded as awareness only. last_updated bumped to 2026-05-30.
- 2026-06-10: No scoring changes. Attribution fix: the ~150–200 instruction budget is primarily sourced to HumanLayer's "Writing a good CLAUDE.md" (`[community:high]`, re-verified 2026-06-10); abhishekray07 retained for the 80-line adherence cliff. Official under-200-line target re-verified against code.claude.com/docs/en/memory (retrieved 2026-06-10). last_updated bumped to 2026-06-10.
- 2026-06-24: Freshness re-run (14 days stale). No scoring changes. The official under-200-line authoring target is unchanged; the only 2026-06 development is that Claude Code's in-product "too long" *warning* now scales with the model context window (changelog v2.1.169) — this affects when the tool nags, not the authoring target, so the line-count rubric stays as-is. All thresholds and sub-criteria re-verified current. last_updated bumped to 2026-06-24.
- 2026-06-26: Freshness re-run (2 days stale). No scoring changes. Late-June 2026 changelog activity (v2.1.181–v2.1.193) added recovery tools (`/rewind`, network-drive fixes, `autoMode.classifyAllShell`) and auto-mode guardrails (destructive git command blocking) but did NOT alter any CLAUDE.md authoring guidance — line-count thresholds, inferable-content list, hook-convertible-rules deduction, and the 7-category weighting are all still current. last_updated bumped to 2026-06-26.
- 2026-07-25: Refresh against code.claude.com/docs/en/memory (retrieved 2026-07-25) and changelog v2.1.196–v2.1.218. **No weight changes; one adjudication rule added.** Criterion A gains a `/doctor` trim baseline (v2.1.206): official guidance now explicitly cuts directory layouts, dependency lists, and architecture overviews while keeping pitfalls, rationale, and non-default conventions — added an explicit rule resolving the A↔C tension so a plain directory listing is not simultaneously rewarded under C and penalized under A. **`.claude/rules/` facts for assessors (no scoring change)**: path-scoped rules now match through **symlinked paths** into the project (v2.1.198) — relevant to symlink-based dotfiles repos, where rules previously appeared not to fire; a rule's whole `paths` list shares a budget of **1,000 expanded brace patterns / 4 MiB**, and an over-budget pattern is used unexpanded so its literal braces match nothing (v2.1.217); an unparseable `[` bracket expression makes that one pattern match nothing while the rule's other patterns keep working (v2.1.207); project rules are skipped when `project` is excluded from `--setting-sources` (v2.1.211). **MEMORY.md**: the 200-line/25KB check now strips YAML frontmatter and block-level HTML comments before measuring (v2.1.211), and Claude Code stamps a `modified` ISO-8601 frontmatter field on memory files that already have frontmatter (v2.1.214). last_updated bumped to 2026-07-25.
- 2026-08-12: Refreshed against code.claude.com/docs/en/memory (retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. **No scoring-weight changes**; all criteria re-verified against the current doc page. Advisory only: auto-compaction now constrains sessions to the assumed context window (v2.1.223) and `CLAUDE_CODE_DISABLE_1M_CONTEXT` caps 1M models at 200K, so the under-200-line size criterion is if anything more load-bearing than before - keep the existing deduction schedule. last_updated bumped to 2026-08-12.
- 2026-09-16: Refreshed against memory + best-practices docs, the new context-window / large-codebases / sub-agents pages, the platform prompting guide (retrieved 2026-09-16), and changelog v2.1.261–v2.1.273. **No weight changes; one adjudication rule added under criterion A**: *Model-era workarounds* — official guidance (large-codebases "Revisit after major model releases"; Fable 5 "steer most behaviors with a brief instruction rather than enumerating each behavior by name") makes rules that only compensate for an older model's limitation inferable/obsolete content; deduct under the existing inferable-content schedule and flag via the Stale Information detection pattern, never both for one line. Emphasis dilution gained a second official source (platform guide: "dial back any aggressive language"). Advisory notes: every non-Explore/Plan subagent re-loads the full CLAUDE.md hierarchy (`omitClaudeMd` opts out, v2.1.271), so line count is paid per subagent; criterion B tie-breaker favors the exact test command (`[community:mid]`). Line-count thresholds, `/doctor` trim baseline, inferable-content list, and hook-convertible deduction all re-verified unchanged. last_updated bumped to 2026-09-16.
- 2026-09-04: Refreshed against memory + best-practices docs (retrieved 2026-09-04) and changelog v2.1.229–v2.1.260. **No weight changes; one adjudication note added under criterion A**: emphasis dilution — official guidance now limits emphasis to the single skipped line, and blanket emphasis is scored via the new Minor anti-pattern **Emphasis Overuse** under criterion F (single-deduction rule noted to avoid double-counting). Line-count thresholds, `/doctor` trim baseline, inferable-content list, and hook-convertible deduction all re-verified unchanged. Advisory facts for assessors: a CLAUDE.md over 4 MiB is skipped entirely; `/context` (not `/memory`) is now the official way to verify what loaded. last_updated bumped to 2026-09-04.
- 2026-09-24: Refreshed against memory + best-practices docs, the platform prompting guide and per-model pages (Opus 5, Opus 5.5, Fable 5, Fable 5.1), the Anthropic "new rules of context engineering for Claude 5" blog (retrieved 2026-09-24), and changelog v2.1.274–v2.1.281. **No weight changes. Two scoring rules added, one extended**: (1) **A — model-era workarounds extended** with the official per-model removal lists (generic verify/double-check, "think carefully", narration suppression, anti-formatting, no-thinking rules) under the existing -2/-10 schedule, plus two **exemptions**: concrete runnable checks, and lines adapted from official per-model prompt blocks (Fable 5.1 scope/"Delivering work", Opus 5 scope, surgical-edit) — advisory-only in a multi-model user-global CLAUDE.md. (2) **E — rationale rule**: official "NEVER use ellipses" example + Fable 5 "Give the reason, not only the request" → a file with 3+ bare, non-obvious prohibitions caps at 10/15. (3) Reasoning-reproduction instructions routed to the new Major anti-pattern under F (refusal risk on Fable 5/5.1 and Opus 5.5, the default Opus since v2.1.280). Advisory: native AGENTS.md reading (v2.1.277) — a CLAUDE.md that is `@AGENTS.md` + Claude-specific lines is not penalized; v2.1.281 startup notice now aggregates instruction files and @-imports. Line-count thresholds, `/doctor` trim baseline, and hook-convertible deduction re-verified unchanged. last_updated bumped to 2026-09-24.

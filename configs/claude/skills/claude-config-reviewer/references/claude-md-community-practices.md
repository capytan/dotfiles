# Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only, not in scoring)

last_updated: 2026-09-16
sources:
  - https://www.eesel.ai/blog/claude-code-best-practices
  - https://dev.to/nishilbhave/claudemd-best-practices-the-complete-2026-guide-435j
  - https://qiita.com/suwa_nobu/items/b465ef863f8d8608f497
  - https://dev.classmethod.jp/articles/20260915-cc-updates-v2-1-272/
  - https://rahuulmiishra.medium.com/your-claude-md-is-doing-too-much-heres-how-to-fix-it-2cc495ed3599
  - https://github.com/anthropics/claude-code/issues/21858
  - https://howborisusesclaudecode.com/
  - https://github.com/shanraisshan/claude-code-best-practice
  - https://github.com/FlorianBruniaux/claude-code-ultimate-guide
  - https://github.com/trailofbits/claude-code-config
  - https://github.com/abhishekray07/claude-md-templates
  - https://github.com/ykdojo/claude-code-tips
  - https://github.com/hesreallyhim/awesome-claude-code
  - https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know
  - https://github.com/rohitg00/awesome-claude-code-toolkit
  - https://www.builder.io/blog/claude-code-tips-best-practices
  - https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/
  - https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560
  - https://www.humanlayer.dev/blog/writing-a-good-claude-md
  - https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are
  - https://claudify.tech/blog/claude-code-best-practices
  - https://ccforpms.com/fundamentals/project-memory
  - https://dev.to/_46ea277e677b888e0cd13/claude-code-vs-codex-2026-what-500-reddit-developers-really-think-31pb
  - https://buildtolaunch.substack.com/p/claude-code-token-optimization
  - https://www.analyticsvidhya.com/blog/2026/05/tips-for-claude-code-token-saving/
  - https://qiita.com/kirozero/items/66ebe44f9bd09d5e97b0
  - https://zenn.dev/imohuke/articles/claude-code-best-practices-2026
  - https://www.firecrawl.dev/blog/best-claude-code-skills

---

## Contents

- Collected Insights
- Incorporation into Scoring Criteria
- Rejected / Deferred Insights

## Collected Insights

### Structure & Design

#### Keep CLAUDE.md under ~100 lines / ~2,500 tokens `[semi-official]`

Boris Cherny's (Claude Code creator) CLAUDE.md is "only about 2,500 tokens (~100 lines), yet it outperforms most people's 800-line configs."

Explicit token breakdown from Boris's team (2026-04): `~/.claude/CLAUDE.md` ~76 tokens; project `CLAUDE.md` ~4k tokens.

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-04-17)
> Corroborated: https://mindwiredai.com/2026/03/25/claude-code-creator-workflow-claudemd/, https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560

#### HumanLayer: under 60 lines ideal, under 300 lines hard ceiling `[community:high]`

> "general consensus is that under 300 lines is best, and shorter is even better. At HumanLayer, the root CLAUDE.md file is less than sixty lines."

> Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md (Kyle, 2025-11-25, retrieved 2026-04-17)
> Corroborated: https://github.com/abhishekray07/claude-md-templates ("if your project CLAUDE.md is over 80 lines, Claude starts ignoring parts of it")

#### 150–200 instruction budget before compliance drops `[community:high]`

Frontier models reliably follow roughly 150–200 instructions. Claude Code's default system prompt already consumes ~50 of them, leaving ~100–150 for your CLAUDE.md, skills metadata, and conversation instructions combined.

> Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md (re-verified 2026-06-10 — HumanLayer's "Writing a good CLAUDE.md" states frontier models reliably follow ~150-200 instructions and the Claude Code system prompt uses ~50 of them)
> Also: https://github.com/abhishekray07/claude-md-templates (retrieved 2026-04-17)
> Corroborated: https://zenn.dev/tmasuyama1114/articles/claude_code_best_practice_guide

#### WHAT / WHY / HOW structure `[community:high]`

HumanLayer recommends organizing CLAUDE.md around three pillars:
- **WHAT**: tech stack, project structure, codebase map (essential in monorepos)
- **WHY**: purpose and function of different parts of the project
- **HOW**: how Claude should work — tools (e.g., `bun` vs `node`), how to verify changes, how to run tests/typechecks

> Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md (retrieved 2026-04-17)

#### Progressive disclosure: link to agent_docs/ instead of inlining `[community:high]`

> Organize supplementary documentation in separate files under `agent_docs/` (e.g., `building_the_project.md`, `running_tests.md`, `code_conventions.md`) and reference them with `file:line` pointers from CLAUDE.md. Keeps the root file lean and points to authoritative code rather than copying snippets that become outdated.

> Source: https://www.humanlayer.dev/blog/writing-a-good-claude-md (retrieved 2026-04-17)

#### Document mistakes in CLAUDE.md, not just rules `[semi-official]`

> "Each team at Anthropic maintains a CLAUDE.md in git to document mistakes, so Claude can improve over time, and best practices."

After correcting Claude: "Update your CLAUDE.md so you don't repeat this." Claude creates precise rules from its own mistakes.

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)

#### CLAUDE.md is advisory (~80% adherence); hooks are deterministic (100%) `[semi-official]`

> "CLAUDE.md is advisory — Claude follows it about 80% of the time. Hooks are deterministic, 100%. If something must happen every time without exception (formatting, linting, security checks), make it a hook. If it's guidance Claude should consider, CLAUDE.md is fine."

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)

#### Bullet points over paragraphs `[community:mid]`

> "Concise bullet-point instructions are 40% more likely to be followed than long paragraphs."

> Source: https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29)
> **Re-checked 2026-09-16**: the SFEIR page (updated 2026-06-05) no longer carries the percentage; its good/bad-practice table now reads "Bullet points" vs "Long paragraphs" → "Better compliance", and "Concise (80-150 lines)" vs "> 500 lines". The principle stands (and matches the official "Structure: use markdown headers and bullets" guidance); the 40% figure is withdrawn (kirozero's Qiita survey, updated 2026-08-02, reports the page briefly showed 35% before the number was dropped).

#### Leave formatting to linters `[community:mid]`

> "Don't put code formatting rules in CLAUDE.md — leave formatting to linters."

> Source: https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29; **no longer on the page as of 2026-09-16**)
> Re-sourced 2026-09-16: https://dev.to/nishilbhave/claudemd-best-practices-the-complete-2026-guide-435j (2026-05-29, edited 2026-07-09) lists "Style rules enforced by linters" and "Rules a formatter handles deterministically" under Exclude. Consistent with the official "Code style rules that differ from defaults" Include row and the hooks-for-formatting guidance.

#### The exact test command is the single highest-ROI line `[community:mid]`

> Include the "Exact test command" — identified as the "single highest-ROI line"; write rules in imperative language ("Use Pest" rather than "we generally prefer").

> Source: https://dev.to/nishilbhave/claudemd-best-practices-the-complete-2026-guide-435j (retrieved 2026-09-16)
> Matches the official Include row "Testing instructions and preferred test runners"; useful as a concrete tie-breaker when scoring criterion B.

#### CLAUDE.md is context, not access control `[community:mid]`

> "CLAUDE.md is context, not access control. It can tell Claude Code not to deploy. It cannot prevent deployment when the active permissions and credentials allow it."

> Source: https://www.eesel.ai/blog/claude-code-best-practices (Kenneth Pangan, 2026-09-09, retrieved 2026-09-16)
> Corroborates the official line, now on the memory page itself: "To block an action regardless of what Claude decides, use a PreToolUse hook instead." Same article: put "detailed rules next to the code they govern when that makes the scope clearer, rather than making one enormous root file" — matches the official per-directory CLAUDE.md guidance on the large-codebases page.

#### Iterate on CLAUDE.md like a prompt `[community:high]`

> "Your CLAUDE.md files become part of Claude's prompts, so they should be refined like any frequently used prompt. A common mistake is adding extensive content without iterating on its effectiveness."

> Source: https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know (retrieved 2026-03-29)

### Token Efficiency

#### Use skills for on-demand knowledge instead of CLAUDE.md bloat `[community:high]`

> "Skills are more token-efficient because Claude Code only loads them when needed. If you want something simpler, you can put a condensed version in ~/.claude/CLAUDE.md instead, but that gets loaded into every conversation whether you need it or not."

Each skill uses only ~100 tokens during metadata scanning to determine relevance; when activated, full content loads at <5k tokens.

> Source: https://github.com/ykdojo/claude-code-tips (retrieved 2026-03-29)
> Corroborated: https://github.com/travisvn/awesome-claude-skills
> Corroborated (2026-06-10): https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05 `[community:mid]` — "CLAUDE.md = always-on context, skills = on-demand"; misplacing workflows in CLAUDE.md wastes context every turn

#### Context thresholds for long sessions `[community:mid]`

> "At 70% context, Claude starts losing precision. At 85%, hallucinations increase. At 90%+, responses become erratic."

Strategy: 0-50% (work freely), 50-70% (attention), 70-90% (/compact), 90%+ (/clear mandatory).

> Source: https://github.com/FlorianBruniaux/claude-code-ultimate-guide (retrieved 2026-03-29)

#### HTML comments for zero-token maintainer notes `[community:mid]`

Use `<!-- -->` in CLAUDE.md for notes visible to humans but stripped before injection into Claude's context. (This is now also officially documented.)

> Source: multiple community references, confirmed official at code.claude.com/docs/en/memory

#### A stable CLAUDE.md improves prompt caching `[community:mid]`

A lean, stable CLAUDE.md sits in the cacheable prefix of every turn, so keeping it unchanged across sessions improves cache hit rate. Cited reductions: cached input tokens cost ~$0.30/M vs ~$3.00/M uncached on Sonnet (10x), with one team reporting a "40% reduction in input tokens per session just by maintaining a well-structured CLAUDE.md."

> Source: https://buildtolaunch.substack.com/p/claude-code-token-optimization, https://www.analyticsvidhya.com/blog/2026/05/tips-for-claude-code-token-saving/ (retrieved 2026-05-30)
> Caveat: the 40% figure is a single-team self-report; the caching mechanism itself is sound. Implication: frequent edits to CLAUDE.md invalidate the cache prefix, so churn has a token cost beyond the lines themselves.

### Workflow Patterns

#### Explore -> Plan -> Code -> Commit `[semi-official]`

Boris Cherny's workflow: "I will use Plan mode, and go back and forth with Claude until I like its plan. From there, I switch into auto-accept edits mode and Claude can usually 1-shot it. A good plan is really important!"

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)
> Corroborated: https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know

#### Use @.claude tag on PRs to add learnings (Compounding Engineering) `[semi-official]`

> "Cherny often uses the @.claude tag on coworkers' PRs to add learnings to CLAUDE.md, ensuring knowledge from each PR is preserved."

Install via `/install-github-action`. Claude automatically updates CLAUDE.md and commits learnings when tagged. Boris calls this **"Compounding Engineering"** — iteratively building institutional knowledge so the agent gets smarter with every PR review.

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-04-17), https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560
> Corroborated: https://venturebeat.com/technology/the-creator-of-claude-code-just-revealed-his-workflow-and-developers-are (Jan 2026, viral coverage)

#### "Every mistake becomes a rule" (Anthropic internal practice) `[semi-official]`

> "Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time."

Aakash Gupta (product leader) summarized the effect: "Every mistake becomes a rule. The longer the team works together, the smarter the agent becomes."

> Source: Boris Cherny via VentureBeat, Jan 2026 (retrieved 2026-04-17)

#### Periodically prune CLAUDE.md as models improve `[community:mid]`

> "いま効いている設定が次のモデルでも効くとは限りません。以前のモデル向けに書いた指示が、新しいモデルには過剰な制約になる例もあり、3〜6か月ごと、あるいは大きなモデル更新のあとに、設定の棚卸しをするべき" (Settings that work now may not work for the next model. Instructions written for an older model can become over-constraints for a newer one — do an inventory every 3-6 months or after major model updates, removing "training wheels" the new model no longer needs.)

> Source: https://qiita.com/kirozero/items/66ebe44f9bd09d5e97b0, https://zenn.dev/imohuke/articles/claude-code-best-practices-2026 (retrieved 2026-05-30)
> Reinforces the official "treat CLAUDE.md like code, prune it regularly" guidance with a concrete cadence and a model-evolution rationale.
> **Now official (2026-09-16)**: the large-codebases page says "Revisit after major model releases: instructions that worked around an older model's limitation may become overhead once a newer model handles the case on its own. For example, a rule that forces single-file refactors can be deleted once the limitation is gone", and the Fable 5 prompting page says "Capability improvements at this level are also a good prompt to re-evaluate which instructions, tools, and guardrails are still needed." Recorded in official-best-practices; the anti-pattern catalog's Stale Information entry gained a matching detection pattern.

#### Stable CLAUDE.md on main; branch-specific rules in `.claude/rules/` `[community:low]`

> "Maintain a stable CLAUDE.md on main and add specific modular rule files on feature branches when necessary. This approach avoids merge conflicts on CLAUDE.md while adapting behavior to the branch context."

> Source: https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29; **removed from the page by its 2026-06-05 update — downgraded to `[community:low]` on 2026-09-16**, no longer scoring-relevant)

#### Subagents inherit the whole CLAUDE.md hierarchy `[community:mid]` → now `[official]`

> Verified with a sentinel phrase in CLAUDE.md: by default every delegated subagent can read user, project and local CLAUDE.md content; on 2.1.270 `omitClaudeMd: true` was silently ignored, on 2.1.271 it works. It does not affect a session started with `--agent`.

> Source: https://qiita.com/suwa_nobu/items/b465ef863f8d8608f497 (2026-09-15, 23 likes), https://dev.classmethod.jp/articles/20260915-cc-updates-v2-1-272/ (石川覚, 2026-09-15) (retrieved 2026-09-16)
> Both articles said the field was undocumented; as of 2026-09-16 the sub-agents doc documents it (quoted in official-best-practices). Scoring relevance: every CLAUDE.md line is paid again per subagent, which strengthens criterion A.

#### Start simple, add complexity only when proven needed `[community:mid]`

> "Start with basic CLAUDE.md + a few commands. Test in production for 2 weeks. Add agents/skills only if need is proven."

> Source: https://github.com/FlorianBruniaux/claude-code-ultimate-guide (retrieved 2026-03-29)

#### Commit early, commit often for token savings `[community:low]`

> "Every time the agent completes a logical unit of work, it commits to git."

Saves tokens because git history provides context recovery without re-reading files.

> Source: https://dev.to/yurukusa/the-token-per-dollar-math-running-claude-max-for-30-days-2k1o (retrieved 2026-03-29)

### Tool Integration

#### Hooks > CLAUDE.md for enforcement `[community:high]`

> "An instruction in your CLAUDE.md saying 'never use rm -rf' can be forgotten or overridden by context pressure. A PreToolUse hook that blocks rm -rf fires every single time, with the error message right at the point of decision."

> Source: https://github.com/trailofbits/claude-code-config (retrieved 2026-03-29)
> Corroborated: Boris Cherny's tips (semi-official)

#### PostToolUse hooks for auto-formatting `[semi-official]`

> "Every time Claude edits a file, your formatter should run automatically. Add a PostToolUse hook in .claude/settings.json that runs Prettier (or your formatter) on any file after Claude edits or writes it."

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)
> Corroborated: https://github.com/shanraisshan/claude-code-best-practice

#### LSP plugins for automatic diagnostics `[semi-official]`

> "LSP plugins give Claude automatic diagnostics after every file edit — type errors, unused imports, missing return types. Claude sees and fixes issues before you even notice them. This is the single highest-impact plugin you can install."

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)

#### Global CLAUDE.md for cross-tool workflows `[community:low]`

> "My global CLAUDE.md tells it to send diffs to Gemini and Codex for review before committing. High catch rate."

> Source: Reddit (via https://dev.to/_46ea277e677b888e0cd13/claude-code-vs-codex-2026-what-500-reddit-developers-really-think-31pb, retrieved 2026-03-29)

#### Auto-generate CLAUDE.md with `/init` or custom commands `[community:mid]`

awattar/claude-code-best-practices provides a `/custom-init` command that "automatically generates comprehensive CLAUDE.md files for any project by analyzing project structure, technology stack, and development patterns."

> Source: https://github.com/awattar/claude-code-best-practices (retrieved 2026-03-29)

### Parallel & Scaling Patterns

#### Multiple git checkouts for parallel Claude sessions `[semi-official]`

Boris runs 5 terminal instances + 5-10 web sessions simultaneously, each in its own git checkout to avoid conflicts.

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)

#### Subagents for code review to preserve context `[semi-official]`

> "His code review command spawns several subagents at once: one checks style guidelines, another combs through the project's history, another flags obvious bugs."

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)

#### Agent Skills is now a cross-tool standard `[community:mid]`

> "The Agent Skills specification is adopted by Claude Code, OpenAI Codex CLI, Cursor, Gemini CLI, and GitHub Copilot, so a skill you write or install works across all of these tools without modification."

Strengthens the "move on-demand knowledge to skills, not CLAUDE.md" recommendation: skills are now portable across agents, lowering the cost of extracting domain knowledge out of CLAUDE.md.

> Source: https://www.firecrawl.dev/blog/best-claude-code-skills (retrieved 2026-05-30)

#### Systematize learnings into reusable skills `[community:mid]`

> "口頭の指示はスキルへ、手動の作業はスクリプトへ、踏んだ地雷は learned スキルへ" (Verbal instructions become skills, manual tasks become scripts, mistakes become learned skills.)

> Source: https://qiita.com/shimo4228/items/1513ae9a3a11769df170 (retrieved 2026-03-29)

---

## Incorporation into Scoring Criteria

When a community insight is reflected in `claude-md-quality-criteria.md`, record it here.

| Date | Insight | Reflected In | Credibility |
|------|---------|--------------|-------------|
| 2026-03-29 | 200-line target matches official; ~100 lines ideal per Boris | A. Token Efficiency thresholds | `[semi-official]` |
| 2026-03-29 | Bullet points > paragraphs for adherence | A. Token Efficiency / E. Actionability | `[community:mid]` |
| 2026-03-29 | Hooks for enforcement, CLAUDE.md for guidance | G. Behavioral Impact (convert hook-worthy items) | `[semi-official]` + `[community:high]` |
| 2026-03-29 | Iterate on CLAUDE.md like a prompt | New consideration for all criteria | `[community:high]` |
| 2026-04-17 | Instruction budget (~150–200 total, ~50 used by system prompt) | A. Token Efficiency (tightens "ideal" threshold) | `[community:high]` |
| 2026-04-17 | HumanLayer under-60-line benchmark and "80 lines → Claude starts ignoring" | A. Token Efficiency thresholds | `[community:high]` |
| 2026-04-17 | WHAT/WHY/HOW structure | C. Architecture Clarity / E. Actionability | `[community:high]` |
| 2026-04-17 | Progressive disclosure via agent_docs/ with file:line pointers | A. Token Efficiency / D. Non-Obvious Patterns | `[community:high]` |
| 2026-09-16 | Prune model-era workarounds after major model releases (community cadence → now official on large-codebases + Fable 5 pages) | A. Token Efficiency adjudication note; F via Stale Information detection pattern | `[official]` (was `[community:mid]`) |
| 2026-09-16 | Exact test command is the highest-ROI line; imperative phrasing | B. Commands & Workflows (tie-breaker note) | `[community:mid]` |

---

## Rejected / Deferred Insights

Insights found during research but not adopted, for reasons such as:
- Conflicts with official documentation
- Low reproducibility
- Too environment-specific

| Date | Insight | Rejection Reason | Source |
|------|---------|-----------------|--------|
| 2026-03-29 | Global CLAUDE.md for cross-tool workflows (send diffs to Gemini/Codex) | Too environment-specific; niche workflow | Reddit via dev.to |
| 2026-03-29 | "40% more likely to be followed" stat for bullet points | Exact number unverifiable; principle is sound but stat deferred. 2026-09-16: the number has since been removed from the source page | SFEIR Institute |
| 2026-09-16 | Symlink a canonical rules repo into every project's `.claude/rules/` to share security/coding standards | **Conflicts with official docs (retrieved 2026-09-16)**: a symlink whose target is outside the working directory is treated as an external import — it does not load until external-import approval (which symlinks alone never trigger), and path-scoped linked rules never load even after approval. Official alternatives: `~/.claude/rules/` for personal sharing, a plugin for team sharing | https://rahuulmiishra.medium.com/your-claude-md-is-doing-too-much-heres-how-to-fix-it-2cc495ed3599 (2026-04) |
| 2026-09-16 | Rules with `paths:` in `~/.claude/rules/` are ignored (GitHub #21858) | Issue is closed with no fix version stated; the memory page documents user-level rules without a `paths` restriction, so treat as "verify with `InstructionsLoaded`" rather than a rule. Recorded as a caveat in the modularization guide, not adopted for scoring | https://github.com/anthropics/claude-code/issues/21858 |

---

## Changelog

- 2025-05-01: Initial version (empty template)
- 2026-03-29: First research run. Added 20+ insights across Structure & Design, Token Efficiency, Workflow Patterns, Tool Integration, and Parallel & Scaling Patterns. Sources include Boris Cherny (semi-official), Trail of Bits (community:high), FlorianBruniaux guide (community:mid), SFEIR Institute (community:mid), ykdojo tips (community:high), wesammustafa guide (community:high), awattar best practices (community:mid), and Japanese community (Qiita/Zenn, community:mid/low).
- 2026-05-30: Research run. Added three new `[community:mid]` insights: stable CLAUDE.md improves prompt caching (build-to-launch / AnalyticsVidhya; 10x cached-token saving, 40% single-team self-report — implies CLAUDE.md churn invalidates cache); periodically prune CLAUDE.md as models improve, 3-6 month cadence (kirozero Qiita / imohuke Zenn — reinforces official "prune like code"); Agent Skills now a cross-tool standard adopted by Codex CLI/Cursor/Gemini CLI/Copilot (Firecrawl — strengthens "move on-demand knowledge to skills"). Confirmed official best-practices and line-limit consensus unchanged since 2026-05-15. last_updated bumped to 2026-05-30.
- 2026-04-17: Added HumanLayer "Writing a good CLAUDE.md" (Kyle, Nov 2025) with WHAT/WHY/HOW structure, 60-line benchmark, and agent_docs/ progressive-disclosure pattern. Added abhishekray07/claude-md-templates insight on the 150–200 instruction budget and 80-line adherence cliff. Added rohitg00/awesome-claude-code-toolkit "CLAUDE.md Bible" (stack-specific 80–150 line templates). Added Boris Cherny token breakdown (user 76 / project 4k tokens) and "Compounding Engineering" term for @.claude PR workflow, plus VentureBeat Jan 2026 viral coverage ("Every mistake becomes a rule"). Refreshed Boris howborisusesclaudecode retrieval date.

- 2026-06-05: Freshness re-run (references were 6 days stale). Re-read official skills + sub-agents docs and a 2026-06 CLAUDE.md best-practices survey (Medium/orchestrator.dev/substack, community:mid). No material change: ~80-120 line practical limit / under-200 / 150-200 instruction budget, the "five things", custom-commands-merged-into-skills, agentskills.io open standard, and auto memory / MEMORY.md (200-line auto-load, routing rules stay in CLAUDE.md) all already captured. last_updated bumped to 2026-06-05.
- 2026-06-10: Re-verified the 150–200 instruction budget against HumanLayer's "Writing a good CLAUDE.md" and promoted HumanLayer to the primary `[community:high]` source for it (abhishekray07 kept as secondary). Added levelup.gitconnected mental-model article (`[community:mid]`) as corroboration for "use skills for on-demand knowledge". No threshold or scoring changes. last_updated bumped to 2026-06-10.
- 2026-06-24: Freshness re-run (14 days stale). Surveyed 2026-06 community articles (Medium "Complete Guide to CLAUDE.md", TECHSY "9 Rules for 2026", Firecrawl token-efficiency, branch8 cost-optimization). No new community insights: under-200 / ~60-line / 150–200-instruction-budget consensus, "two strikes before adding a note," "treat it like code not docs," HTML-comments-are-free, prompt-cache 0.1x cache-read benefit, and skills-for-on-demand-knowledge all already captured. New tooling surfaced this run (`--safe-mode`, `/cd`, MEMORY.md compaction) is official-doc/changelog material, recorded in official-best-practices, not a community practice. last_updated bumped to 2026-06-24.
- 2026-06-26: Freshness re-run (2 days stale). No material change. Re-verified key community insights against late-June 2026 sources — under-100 / under-60 / under-300-line consensus, WHAT/WHY/HOW, agent_docs/ pattern, "compounding engineering" / "every mistake becomes a rule," prompt-cache stability, and 3-6 month pruning cadence all still consensus. New tooling shipped this period (`/rewind` v2.1.191, network-drive Edit fixes v2.1.181, `autoMode.classifyAllShell` v2.1.193) is official-doc material, recorded there. last_updated bumped to 2026-06-26.
- 2026-07-25: Freshness re-run (29 days stale). Surveyed 2026-07 sources (uxplanet, dev.to 2026 guide, iwoszapar, ranthebuilder, shanraisshan). No new community insights worth adopting - under-200-line consensus, progressive disclosure / 'map not territory', WHAT-WHY-HOW, convert always-must-happen rules into hooks, never duplicate what a linter enforces, and explicit off-limits boundaries (legacy/, generated, vendored) are all already captured. One framing worth keeping in mind when scoring: community now consistently pairs the CLAUDE.md size discipline with scoping context (plan mode, `/permissions`, `/sandbox`) rather than treating the file as the only lever. last_updated bumped to 2026-07-25.
- 2026-09-04: Freshness re-run (23 days stale). Surveyed Aug–Sep 2026 EN sources (Medium "Complete Guide to CLAUDE.md", iwoszapar, productbuilder, claudecode101, maketocreate) and JA sources (Zenn farstep "効果的なCLAUDE.mdの書き方", Qiita kirozero updated 2026-08-02, izanami). **No new community practices worth adopting** — under-200 / ~300-hard-ceiling / 150–200-instruction-budget consensus, "correct twice → write it down", hooks-for-enforcement, monthly-to-quarterly maintenance cadence, and lost-in-the-middle rationale all already captured. Two notes: (1) the community guidance "use IMPORTANT / YOU MUST only for genuine hard constraints — overusing them dilutes impact" is now **official** (best-practices page, retrieved 2026-09-04: emphasize the one skipped line alone) — promoted to official-best-practices and the anti-pattern catalog. (2) JA community (kirozero) correctly attributes the 300-line figure to HumanLayer, not Anthropic — matches our sourcing. last_updated bumped to 2026-09-04.
- 2026-09-16: Freshness re-run (12 days stale). Surveyed Sep 2026 EN sources (eesel.ai 2026-09-09, dev.to nishilbhave, preporato, techsy, buildcamp) and JA sources (Qiita suwa_nobu 2026-09-15, DevelopersIO 2026-09-15, kirozero updated 2026-08-02, tamashiro_nobuyuki 2026-08-14; no Zenn articles dated Sep 2026 surfaced). **Adopted**: "CLAUDE.md is context, not access control" (eesel, `[community:mid]`, corroborates the official PreToolUse line); "exact test command is the highest-ROI line" (nishilbhave, `[community:mid]`, tie-breaker for criterion B); subagents inherit the whole CLAUDE.md hierarchy + `omitClaudeMd` verification (suwa_nobu/DevelopersIO, now official). **Promoted to official**: prune-after-model-updates cadence (large-codebases + Fable 5 prompting pages). **Source drift**: the SFEIR page (updated 2026-06-05) dropped the "40%" stat, the "leave formatting to linters" tip (re-sourced to nishilbhave), and the "stable CLAUDE.md on main" tip (downgraded to `[community:low]`). **Rejected**: symlinking a canonical rules repo into `.claude/rules/` (Medium) — conflicts with the new official external-import semantics for symlinks; GitHub #21858 (user-level path-scoped rules ignored) recorded as a verify-don't-assume caveat. last_updated bumped to 2026-09-16.
- 2026-08-12: Freshness re-run (18 days stale). Community sources re-checked (mcp.directory "Claude Code Best Practices: From Vibe Coding to Agentic Engineering (2026)", SmartScope advanced-practices article, Totalum skills-vs-hooks-vs-subagents guide; `[community:mid]` or better). **No new practices worth adopting.** The dominant 2026 framing is a surface-selection decision tree - "if a rule must be enforced, use hooks or permissions; if it's contextual knowledge, use skills; if it's a delegation boundary, use subagents; if it's always-on project guidance, keep it short in CLAUDE.md" - which matches guidance already recorded here and in the modularization guide. last_updated bumped to 2026-08-12.

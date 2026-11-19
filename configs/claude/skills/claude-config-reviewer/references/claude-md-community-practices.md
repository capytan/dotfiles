# Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only, not in scoring)

last_updated: 2026-11-19
sources:
  - https://www.geeky-gadgets.com/anthropic-claude-code-workflow/
  - https://repowise.dev/blog/guides/claude-md-agents-md-guide
  - https://max.nardit.com/articles/prompt-audit-claude-md
  - https://arte.itlibra.com/en/articles/claude-code-doctor-prompt-audit
  - https://www.alexdunlop.com/writing/claude-md-best-practices
  - https://wmedia.es/en/tips/claude-code-opus-5-prompting-tips
  - https://www.mindstudio.ai/blog/claude-fable-5-1-prompting-rules-changed
  - https://charlesjones.dev/blog/claude-opus-5-context-engineering-what-to-delete
  - https://explainx.ai/blog/claude-opus-5-5-prompting-guide-2026
  - https://note.com/gaku_tachibana/n/n46a0dfd9ee1e
  - https://gihyo.jp/article/2026/09/claude-code-support-agents-md
  - https://www.theregister.com/ai-and-ml/2026/09/18/anthropic-decides-to-support-openais-markdown-instructions-spec/5297588
  - https://gist.github.com/yurukusa/d36197848911f025add142abefcde685
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

#### The exact test command is the single highest-ROI line `[community:mid]` → now `[official]`

> **Promoted 2026-11-19**: best-practices now says "If your repo already has one of these, the single most useful line in your `CLAUDE.md` is the command that runs it." — https://code.claude.com/docs/en/best-practices (retrieved 2026-11-19). Scoring weight now comes from the official source (criterion B).

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

### Claude 5-Generation Pruning (added 2026-09-24)

#### Grep your config for leftover verification instructions `[community:mid]`

> "grep -rns -i "verify\|double-check\|re-check" ~/.claude/CLAUDE.md ./CLAUDE.md ./.claude/agents/ ./.claude/skills/" — the article notes custom agents and skills are where such lines hide ("written once, working fine, never opened again").

> Source: https://wmedia.es/en/tips/claude-code-opus-5-prompting-tips (2026-07-25, tip #145; retrieved 2026-09-24). Operationalizes the official Opus 5 "remove verification instructions" guidance; Charles Jones (https://charlesjones.dev/blog/claude-opus-5-context-engineering-what-to-delete, 2026-07-24, `[community:low]`) gives the same advice: "Pull every 'verify,' 'double-check,' and 're-verify' instruction out of your prompts. Trim CLAUDE.md to the things Claude can't derive from the repository."
> Scoring: the official source already carries the deduction (criterion A model-era workarounds); this entry supplies the *detection method* and the reminder to sweep agents/skills too (see cross-artifact check 23).

#### All-caps CRITICAL/MUST/ALWAYS now over-trigger `[community:mid]`

> MindStudio (2026-09-11): words like "critical," "must," or "always" in all caps now cause over-triggering rather than compliance; leave default reasoning alone and use the effort setting to manage cost rather than adding verification language.

> Source: https://www.mindstudio.ai/blog/claude-fable-5-1-prompting-rules-changed (retrieved 2026-09-24). Corroborates the official Emphasis Overuse entry; no separate scoring.

#### Remove leftover "think carefully" lines `[community:low]`

> explainx.ai: the most useful immediate step for Opus 5.5 is deleting leftover "think carefully" instructions from CLAUDE.md, system prompts and templates built for prior models.

> Source: https://explainx.ai/blog/claude-opus-5-5-prompting-guide-2026 (retrieved 2026-09-24). Restates the official Opus 5.5 page; reference only.

#### Model-routing rules in CLAUDE.md `[community:low]`

> Gaku Tachibana's Fable 5.1 CLAUDE.md example (2026-09-02, JA): use Fable 5.1 only for hard reasoning / large refactors / deep debugging / long implementations; don't spawn Fable 5.1 subagents for research or routine edits; batch independent reads in one turn; propose rather than implement unrequested refactors/tests; when an instruction has two readings, list both and pick one with a reason.

> Source: https://note.com/gaku_tachibana/n/n46a0dfd9ee1e (retrieved 2026-09-24 via search snippet). Reference only. **Partial conflict with official**: "list both readings and pick one" vs official Fable 5.1 scope block "implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well" — official wins; both agree on stating the assumption.

### AGENTS.md Native Support Coverage (added 2026-09-24)

#### "Claude Code now reads AGENTS.md" — news coverage `[community:mid]`

> gihyo.jp (2026-09-19), Publickey, InfoWorld, The Register (2026-09-18), DevOps.com: v2.1.277 reads AGENTS.md when no CLAUDE.md exists; CLAUDE.md wins by default; `/config` → Project instructions → `claude-md-and-agents-md` loads both. Thariq Shihipar (Anthropic, `[semi-official]`): "Starting today in version 2.1.277, if there is no CLAUDE.md in a folder, Claude will check for and use AGENTS.md" and it is "built off of Claude Code mods, our upcoming way to customize the Claude Code harness."

> Sources: https://gihyo.jp/article/2026/09/claude-code-support-agents-md, https://www.theregister.com/ai-and-ml/2026/09/18/anthropic-decides-to-support-openais-markdown-instructions-spec/5297588, https://devops.com/claude-code-adds-agents-md-fallback-cutting-instruction-file-sprawl/ (retrieved 2026-09-24). All consistent with the official memory page; official-best-practices carries the scoring-relevant detail.

### `/doctor prompt-audit` Field Reports (added 2026-10-28)

#### What the audit flags, and what it keeps `[community:mid]`

> Targets "capitalized MUST, NEVER, ALWAYS, CRITICAL, IMPORTANT, especially with no reason beside them", replaced scaffolds ("think step by step", scratchpad tags), step-by-step choreography for judgment work, long prohibition lists, workarounds for a retired model, stale paths/commands (which "now lead the report"), contradictions, and "history narratives" (past tense, incident IDs, pinned model names). Keeps prohibitions against current, reproducible failures and the reasons behind constraints. "Switch to the target model first" — config is audited against the session's model; "an audit that finds nothing should change nothing."

> Source: https://max.nardit.com/articles/prompt-audit-claude-md (published 2026-10-05, retrieved 2026-10-28). Independently corroborated by wmedia.es, note.com/dialogs_develop, claudcod.com (retrieved 2026-10-28 via search). Consistent with the official memory page; scoring weight comes from the official source. Detection-method value: "history narratives" maps to the Stale Information pattern.

#### Move incident records instead of deleting them `[community:mid]`

> Hands-on run (2026-10-03, Claude Code 2.1.286, Opus 5.5, ~10,700 chars of CLAUDE.md + AGENTS.md): 9 findings, 7 applied; "Most findings were about stale or inconsistent config references", almost no older-model prompting. Five medium-confidence findings proposed deleting dated incident records; the author judged them evidence that prevents repeated mistakes and moved them to a separate records file instead. Recommendation: check each finding against the original, move text that exists for a reason rather than deleting it, and re-check real work after removing an instruction.

> Source: https://arte.itlibra.com/en/articles/claude-code-doctor-prompt-audit (published 2026-10-03, updated 2026-10-23; retrieved 2026-10-28). Feeds Phase 4 fix principle: a dated incident line in CLAUDE.md is a *relocate* candidate (to a rules file, skill, or doc), not a *delete* candidate, when it encodes a still-reproducible failure.

#### Oct 2026 JA sources

No Zenn/Qiita article dated October 2026 on CLAUDE.md authoring surfaced (search 2026-10-28); the newest JA items (kanrinin-blog, ~2026-10-12) restate the official "add a rule after correcting twice" loop. No change.

### Nov 2026 Survey (added 2026-11-19)

#### Anthropic engineer talk: drop emphatic rules, audit against the current model `[community:mid]`

> Lydia Hallie (Anthropic) via a Nate Herk video, as written up by Geeky Gadgets: "Keep CLAUDE.md focused on information Claude cannot infer from the code"; "emphatic rules can work against strong models"; run `/doctor prompt-audit` to find instructions the model no longer needs; "audit CLAUDE.md and skills against the model you use". Unneeded material "takes up space" and can make the model drift and make more tool calls. No line limit is given.

> Source: https://www.geeky-gadgets.com/anthropic-claude-code-workflow/ (published 2026-11-18, retrieved 2026-11-19); underlying video https://youtu.be/8Pg6G5h05hk. Tagged `[community:mid]`, not `[semi-official]`: these are second-hand paraphrases, not her own post. Every point restates the official best-practices page, so it adds no scoring weight.

#### Nov 2026 EN/JA sources

Repowise "CLAUDE.md vs AGENTS.md" (updated 2026-11-17), xtrusio (citing the official page as read 2026-11-03), dev.to mohd_yusufkhan, and Qiita future_ta (Nov 2026, beginner rules intro) all restate official guidance: under 200 lines, the check command as the most useful line, hooks for must-happen rules, `@AGENTS.md` import with Claude-only lines below it, and removing the SessionStart-print hook. No new practice. No Reddit r/ClaudeAI thread from Nov 2026 on CLAUDE.md surfaced in search.

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
| 2026-09-24 | Grep CLAUDE.md + agents + skills for verify/double-check leftovers (detection method for official Opus 5 guidance) | A. model-era workarounds (detection); cross-artifact check 23 | `[community:mid]` (deduction itself is `[official]`) |
| 2026-09-24 | All-caps CRITICAL/MUST/ALWAYS over-trigger on Claude 5 models | F. Emphasis Overuse (corroboration only) | `[community:mid]` |
| 2026-10-28 | Incident/history records flagged by prompt-audit: relocate rather than delete when they encode a reproducible failure | F. Stale Information (Fix note) | `[community:mid]` |
| 2026-11-19 | Exact test/check command is the most useful line (community tie-breaker → now official) | B. Commands & Workflows (missing check command caps B at 10) | `[official]` (was `[community:mid]`) |

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
| 2026-09-24 | "Claude Code reads CLAUDE.md, not AGENTS.md — the 'reads it as a fallback' claim is wrong" (yurukusa gist, #6235 cluster); older Zenn articles saying AGENTS.md is unsupported | **Stale since v2.1.277** — official memory page now documents native AGENTS.md reading. Do not cite as a reason to require a CLAUDE.md/symlink, except on Bedrock/Vertex/Foundry or flag-fetch-disabled sessions | https://gist.github.com/yurukusa/d36197848911f025add142abefcde685 |
| 2026-09-24 | "When an instruction has two readings, list both and pick one" as a CLAUDE.md rule | Conflicts with official Fable 5.1 scope block ("implement the reading … most directly support, state that assumption … don't build for the other readings") — the official form wins | https://note.com/gaku_tachibana/n/n46a0dfd9ee1e |
| 2026-10-28 | "File length, rule position, and file arrangement did not change rule-following" (Damon McMillan, arXiv 2605.10039, 1,650 sessions, via Alex Dunlop 2026-08-12) | `[community:low]` — single-author non-peer-reviewed preprint, TypeScript/single-turn only; **conflicts with official** "Longer files consume more context and reduce adherence". Official wins; line-count schedule unchanged | https://www.alexdunlop.com/writing/claude-md-best-practices |
| 2026-11-19 | CLAUDE.md as a "routing map" to wikis, brand assets and finance files (non-code knowledge-work use) | `[community:low]`: second-hand paraphrase from a video write-up; out of scope for code-repo CLAUDE.md scoring | https://www.geeky-gadgets.com/anthropic-claude-code-workflow/ |
| 2026-11-19 | Keep AGENTS.md under Codex's 32 KiB combined default when it is shared with Codex | About OpenAI Codex, not Claude Code; the Claude-side limits (under 200 lines, 4 MiB, on-demand per-file limits) already apply | https://repowise.dev/blog/guides/claude-md-agents-md-guide |
| 2026-09-16 | Rules with `paths:` in `~/.claude/rules/` are ignored (GitHub #21858) | Issue is closed with no fix version stated; the memory page documents user-level rules without a `paths` restriction, so treat as "verify with `InstructionsLoaded`" rather than a rule. Recorded as a caveat in the modularization guide, not adopted for scoring | https://github.com/anthropics/claude-code/issues/21858 |

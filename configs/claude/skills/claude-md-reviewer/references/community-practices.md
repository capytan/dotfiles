# Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only, not in scoring)

last_updated: 2026-03-29
sources:
  - https://howborisusesclaudecode.com/
  - https://github.com/shanraisshan/claude-code-best-practice
  - https://github.com/FlorianBruniaux/claude-code-ultimate-guide
  - https://github.com/trailofbits/claude-code-config
  - https://github.com/abhishekray07/claude-md-templates
  - https://github.com/ykdojo/claude-code-tips
  - https://github.com/hesreallyhim/awesome-claude-code
  - https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know
  - https://www.builder.io/blog/claude-code-tips-best-practices
  - https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/
  - https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560
  - https://dev.to/_46ea277e677b888e0cd13/claude-code-vs-codex-2026-what-500-reddit-developers-really-think-31pb

---

## Collected Insights

### Structure & Design

#### Keep CLAUDE.md under ~100 lines / ~2,500 tokens `[semi-official]`

Boris Cherny's (Claude Code creator) CLAUDE.md is "only about 2,500 tokens (~100 lines), yet it outperforms most people's 800-line configs."

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)
> Corroborated: https://mindwiredai.com/2026/03/25/claude-code-creator-workflow-claudemd/, https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560

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

#### Leave formatting to linters `[community:mid]`

> "Don't put code formatting rules in CLAUDE.md — leave formatting to linters."

> Source: https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29)

#### Iterate on CLAUDE.md like a prompt `[community:high]`

> "Your CLAUDE.md files become part of Claude's prompts, so they should be refined like any frequently used prompt. A common mistake is adding extensive content without iterating on its effectiveness."

> Source: https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know (retrieved 2026-03-29)

### Token Efficiency

#### Use skills for on-demand knowledge instead of CLAUDE.md bloat `[community:high]`

> "Skills are more token-efficient because Claude Code only loads them when needed. If you want something simpler, you can put a condensed version in ~/.claude/CLAUDE.md instead, but that gets loaded into every conversation whether you need it or not."

Each skill uses only ~100 tokens during metadata scanning to determine relevance; when activated, full content loads at <5k tokens.

> Source: https://github.com/ykdojo/claude-code-tips (retrieved 2026-03-29)
> Corroborated: https://github.com/travisvn/awesome-claude-skills

#### Context thresholds for long sessions `[community:mid]`

> "At 70% context, Claude starts losing precision. At 85%, hallucinations increase. At 90%+, responses become erratic."

Strategy: 0-50% (work freely), 50-70% (attention), 70-90% (/compact), 90%+ (/clear mandatory).

> Source: https://github.com/FlorianBruniaux/claude-code-ultimate-guide (retrieved 2026-03-29)

#### HTML comments for zero-token maintainer notes `[community:mid]`

Use `<!-- -->` in CLAUDE.md for notes visible to humans but stripped before injection into Claude's context. (This is now also officially documented.)

> Source: multiple community references, confirmed official at code.claude.com/docs/en/memory

### Workflow Patterns

#### Explore -> Plan -> Code -> Commit `[semi-official]`

Boris Cherny's workflow: "I will use Plan mode, and go back and forth with Claude until I like its plan. From there, I switch into auto-accept edits mode and Claude can usually 1-shot it. A good plan is really important!"

> Source: https://howborisusesclaudecode.com/ (retrieved 2026-03-29)
> Corroborated: https://github.com/wesammustafa/Claude-Code-Everything-You-Need-to-Know

#### Use @.claude tag on PRs to add learnings `[semi-official]`

> "Cherny often uses the @.claude tag on coworkers' PRs to add learnings to CLAUDE.md, ensuring knowledge from each PR is preserved."

> Source: https://medium.com/data-science-collective/10-claude-code-tips-from-the-creator-boris-cherny-36d5a8af2560 (retrieved 2026-03-29)

#### Stable CLAUDE.md on main; branch-specific rules in `.claude/rules/` `[community:mid]`

> "Maintain a stable CLAUDE.md on main and add specific modular rule files on feature branches when necessary. This approach avoids merge conflicts on CLAUDE.md while adapting behavior to the branch context."

> Source: https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29)

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

#### Systematize learnings into reusable skills `[community:mid]`

> "口頭の指示はスキルへ、手動の作業はスクリプトへ、踏んだ地雷は learned スキルへ" (Verbal instructions become skills, manual tasks become scripts, mistakes become learned skills.)

> Source: https://qiita.com/shimo4228/items/1513ae9a3a11769df170 (retrieved 2026-03-29)

---

## Incorporation into Scoring Criteria

When a community insight is reflected in `quality-criteria.md`, record it here.

| Date | Insight | Reflected In | Credibility |
|------|---------|--------------|-------------|
| 2026-03-29 | 200-line target matches official; ~100 lines ideal per Boris | A. Token Efficiency thresholds | `[semi-official]` |
| 2026-03-29 | Bullet points > paragraphs for adherence | A. Token Efficiency / E. Actionability | `[community:mid]` |
| 2026-03-29 | Hooks for enforcement, CLAUDE.md for guidance | G. Behavioral Impact (convert hook-worthy items) | `[semi-official]` + `[community:high]` |
| 2026-03-29 | Iterate on CLAUDE.md like a prompt | New consideration for all criteria | `[community:high]` |

---

## Rejected / Deferred Insights

Insights found during research but not adopted, for reasons such as:
- Conflicts with official documentation
- Low reproducibility
- Too environment-specific

| Date | Insight | Rejection Reason | Source |
|------|---------|-----------------|--------|
| 2026-03-29 | Global CLAUDE.md for cross-tool workflows (send diffs to Gemini/Codex) | Too environment-specific; niche workflow | Reddit via dev.to |
| 2026-03-29 | "40% more likely to be followed" stat for bullet points | Exact number unverifiable; principle is sound but stat deferred | SFEIR Institute |

---

## Changelog

- 2025-05-01: Initial version (empty template)
- 2026-03-29: First research run. Added 20+ insights across Structure & Design, Token Efficiency, Workflow Patterns, Tool Integration, and Parallel & Scaling Patterns. Sources include Boris Cherny (semi-official), Trail of Bits (community:high), FlorianBruniaux guide (community:mid), SFEIR Institute (community:mid), ykdojo tips (community:high), wesammustafa guide (community:high), awattar best practices (community:mid), and Japanese community (Qiita/Zenn, community:mid/low).

# Skill Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects SKILL.md-related insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only)

last_updated: 2026-11-19

---

## Contents

- File References Are Read-Tool Instructions, Not @ Imports
- Tighter Body Target: 1,500-2,000 Words
- Context Hygiene & Lean SKILL.md
- Description as Trigger, Not Summary
- Measured Description Optimization ("Use when...", Examples)
- Pushy Descriptions
- Curate Aggressively: 8-12 Skills, Monthly Audit
- Pruning with `/skill-doctor` (Sep 2026)
- Early `/doctor prompt-audit` Reports (Oct 2026)
- Retiring Skills, Anti-Triggers, and the `verify` Name (Nov 2026)
- Frontmatter Field Inventory: 20 Claude Code Fields vs 6 Spec Fields
- CLAUDE.md = Always-On, Skills = On-Demand (Mental Model)
- Evaluation-Driven Skill Creation
- Token Economics at Scale
- Organization Patterns for References
- Japanese Community Consensus (Zenn / Qiita)
- Security: Treat Skills as Code
- Ecosystem Adoption
- Practical Community Checklist

## File References Are Read-Tool Instructions, Not `@` Imports

`[community:high]` Multiple 2026 guides (MindStudio skill-architecture post, sidsaladi "secret weapon" guide) emphasize a Claude-Code-specific gotcha:

- In SKILL.md, a file reference like `See reference/finance.md` is **not** an `@`-import — it is an instruction for Claude to read the file on demand with the Read/bash tools. `@path` imports only work in CLAUDE.md.
- Practical consequence: name the path explicitly inside the step that needs it. Vague or buried references cause "missed connections" where Claude never reads the file.
- "Process in SKILL.md, context in reference files" — ordered steps belong in SKILL.md; background/domain knowledge/examples belong in `references/`, written literally for the model, not for humans.

> Sources:
> - https://www.mindstudio.ai/blog/claude-code-skills-architecture-skill-md-reference-files (retrieved 2026-05-30)
> - https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md (retrieved 2026-05-30)

## Tighter Body Target: 1,500-2,000 Words

`[semi-official]` Anthropic's own `plugin-dev/skill-development` skill (bundled in `anthropics/claude-code`) targets a tighter range than the 500-line ceiling:

> "Keep SKILL.md lean: Target 1,500-2,000 words for the body."

It also ships a pre-share checklist: "Check references: All referenced files exist. Validate examples: Examples are complete and correct. Test scripts: Scripts are executable and work correctly."

> Source: https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md (retrieved 2026-05-30)

## Context Hygiene & Lean SKILL.md

`[community:high]` `mgechev/skills-best-practices` (GitHub, March 2026) — treats SKILL.md as "the brain for high-level logic":

- Limit SKILL.md to **<500 lines**; use it for navigation and primary procedures
- **Flat subdirectories only**: files exactly one level deep (`references/schema.md`, not `references/db/v1/schema.md`)
- **Just-in-Time (JiT) loading**: explicitly instruct the agent when to read each file (e.g., "See `references/auth-flow.md` for specific error codes")
- **Skills are for agents, not humans**: do not create `README.md`, `CHANGELOG.md`, or `INSTALLATION_GUIDE.md` inside a skill — they waste tokens without changing agent behavior

Recommended directory shape:
```
skill-name/
├── SKILL.md          # Metadata + core instructions, <500 lines
├── scripts/          # Executable tiny CLIs
├── references/       # Schemas, cheatsheets (one level deep)
└── assets/           # Templates, static files
```

> Source: https://github.com/mgechev/skills-best-practices (retrieved 2026-04-17)

## Description as Trigger, Not Summary

`[community:high]` `shanraisshan/claude-code-best-practice` (GitHub):

- "The skill description field is a trigger, not a summary — write it for the model ('when should I fire?')"
- "Don't state the obvious in skills — focus on what pushes Claude out of its default behavior"
- "Don't railroad Claude in skills — give goals and constraints, not prescriptive step-by-step instructions"
- Build a **"Gotchas" section** in every skill — add Claude's observed failure points over time

> Source: https://github.com/shanraisshan/claude-code-best-practice (retrieved 2026-04-17)
> 2026-09-24: "don't railroad" is now echoed officially (Anthropic blog: "Avoid making them overconstrained, except in highly important areas"; see skill-official-best-practices "Claude 5-Generation Skill Authoring").

**"Do NOT use for…" line** `[community:low]` (added 2026-09-24): one 2026 guide argues the negative-boundary line in a description matters more than "Use when…", because it stops a skill from hijacking unrelated conversations; a related GitHub issue notes the Skill tool's proactive-invocation rule defines only the positive case (https://github.com/anthropics/claude-code/issues/17327). Reference only — consistent with, but not stronger than, the existing "explicit negative boundaries" checklist item. Retrieved 2026-09-24 via search snippets.

**Sweep skills for verify/double-check leftovers** `[community:mid]` (added 2026-09-24): wmedia.es (2026-07-25) recommends `grep -rns -i "verify\|double-check\|re-check"` over `.claude/skills/` and `.claude/agents/` as well as CLAUDE.md, since skills are "written once, working fine, never opened again" — detection method for the official Opus 5 removal guidance (skill anti-pattern "Generic Self-Verification Steps"). https://wmedia.es/en/tips/claude-code-opus-5-prompting-tips

## Measured Description Optimization ("Use when...", Examples)

`[community:mid]` Testing across 200+ prompts (mellanon gist, 2026):

- Optimized descriptions improve skill activation from ~20% to ~50% of relevant prompts
- Adding concrete examples to the description/when_to_use improves activation from ~72% to ~90%
- "Use when..." phrasing recommended as the trigger-clause template

First quantified evidence for the long-standing "description is the trigger" and "pushy descriptions" guidance; numbers are one author's benchmark, so treat the deltas as directional, not exact.

> Source: https://gist.github.com/mellanon/50816550ecb5f3b239aa77eef7b8ed8d (retrieved 2026-06-10)

## Pushy Descriptions

`[semi-official]` Anthropic's official `skill-creator`:

> "currently Claude has a tendency to 'undertrigger' skills -- to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit 'pushy'. So for instance, instead of 'How to build a simple fast dashboard to display internal Anthropic data.', you might write 'How to build a simple fast dashboard to display internal Anthropic data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a "dashboard."'"
> — https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md (retrieved 2026-04-17)

> **Conflict noted 2026-09-24 — official prompting guide pulls the other way.** "Claude Opus 4.5 and Claude Opus 4.6 are also more responsive to the system prompt than previous models. If your prompts were designed to reduce undertriggering on tools or skills, these models may now overtrigger. The fix is to dial back any aggressive language." and "Remove over-prompting. Tools that undertriggered in previous models are likely to trigger appropriately now. Instructions like 'If in doubt, use [tool]' will cause overtriggering." — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (retrieved 2026-09-24). **Resolution (official wins):** keep descriptions *specific and trigger-oriented* (concrete "Use when…" contexts, named synonyms), but do not reward pushiness for its own sake — "make sure to use this skill whenever…", "even if they don't explicitly ask", "if in doubt, use" are over-triggering risks on current models. Assessors: do not deduct a description for *lacking* pushy language; flag only when a pushy clause widens scope beyond the skill's real domain.

## Curate Aggressively: 8-12 Skills, Monthly Audit

`[community:mid]` 2026 skill-roundup consensus (Firecrawl, Developers Digest):

- 8-12 well-chosen skills cover most needs; large installed collections dilute the listing budget and trigger accuracy
- Run a monthly skill audit; delete skills that haven't triggered in 30 days
- Complements the official skill-listing budget mechanics (1% of context window; least-invoked descriptions dropped first on overflow) — fewer, better skills keep full descriptions in context

> Sources: https://www.firecrawl.dev/blog/best-claude-code-skills , https://www.developersdigest.tech/blog/best-claude-code-skills-2026 (retrieved 2026-06-10)

## Pruning with `/skill-doctor` (Sep 2026)

`[community:low]` Early coverage of the bundled `/skill-doctor` command (changelog v2.1.261, 2026-09-04) turns the "monthly audit" practice above into a concrete workflow:

- getclaudeskills.com (published 2026-09-05): for skills you maintain, "rewrite the description or add `disable-model-invocation: true`"; for skills you don't, use `skillOverrides` with `"name-only"` (keeps `/name` invocation) or `"off"`. Caution recorded: "a skill flagged unused isn't necessarily broken or badly written, it may just not have come up in your recent sessions."
- Joe Njenga (Medium, Sep 2026, title "I Tried (New) Claude Code /skill-doctor (And Found Most Skills Are Dead Weight)") — same conclusion from the search snippet; page returned HTTP 403 on fetch, so no direct quote.

Conflict with official: getclaudeskills states the minimum version as v2.1.261; the docs say `/skill-doctor` "requires Claude Code v2.1.252 or later" and is feature-flag-gated. Official wins; the changelog entry is v2.1.261. No scoring impact — the tool is recorded in the official file and criteria as an advisory diagnostic.

> Sources: https://www.getclaudeskills.com/blog/claude-code-skill-doctor-command (retrieved 2026-09-16); https://medium.com/@joe.njenga/i-tried-new-claude-code-skill-doctor-and-found-most-skills-are-dead-weight-2c2c3d0aaf2d (search snippet only, 2026-09-16)

## Early `/doctor prompt-audit` Reports (Oct 2026)

`[community:low]` First write-ups of `/doctor prompt-audit` (v2.1.283; official entry in skill-official-best-practices.md):

- max.nardit.com (published 2026-10-05) groups what it flags as dated prompt text ("Pressure language comes first: capitalized MUST, NEVER, ALWAYS, CRITICAL, IMPORTANT"), scaffolds ("think step by step", scratchpad tags), over-specification ("step-by-step choreography for judgment work"), and fossils ("workarounds for a retired model's habits"); recommends re-running it on every model change.
- arte.itlibra.com (published 2026-10-03, updated 2026-10-23), hands-on run on AGENTS.md/CLAUDE.md: 9 findings, 7 applied; "The first surprise was that it found almost no prompting written for older models." The one high-confidence finding was a stale explanation — "a real drift."

Takeaway for assessors (not scored): on already-curated configs the audit's yield is mostly stale facts/drift, not emphasis. Treat it as a complement to this reviewer, not a substitute.

> Sources: https://max.nardit.com/articles/prompt-audit-claude-md (retrieved 2026-10-28); https://arte.itlibra.com/en/articles/claude-code-doctor-prompt-audit (retrieved 2026-10-28)

## Retiring Skills, Anti-Triggers, and the `verify` Name (Nov 2026)

`[community:high]` FlorianBruniaux/claude-code-ultimate-guide (GitHub, ~6.5k stars; `guide/learning-path/05-skills.md`, last changed 2026-09-30, not captured by earlier runs):
- "Do not archive a retired skill under `.claude/skills/`, because nested discovery can keep it visible." Keep retired skills in git history, or move them outside discovered skill directories with a dated retirement note. The mechanism is not stated in the official docs (official nested discovery covers `.claude/skills` folders in subdirectories), so the reason is unverified; the advice itself is harmless.
- Write the description "as a routing rule": what the skill does, when to use it, and "Important anti-triggers when adjacent tasks belong elsewhere". Echoes the existing `[community:low]` "Do NOT use for…" item with a stronger source; still not a deduction for absence.
- On `/skill-doctor`: "Treat an unused flag as a review signal, not an automatic deletion order." Consistent with the official file and the getclaudeskills caution above.

> Source: https://github.com/FlorianBruniaux/claude-code-ultimate-guide/blob/main/guide/learning-path/05-skills.md (retrieved 2026-11-19; star count via GitHub API)

`[community:low]` skills-hub.ai ("Name a Skill verify and Claude Code Will Run It Before Committing", 2026): if an existing skill called `verify` does something else, rename it to a scoped name (e.g. `verify-pipeline`) and keep `verify` for the repo's commit check. Consistent with the official v2.1.286 behavior and the 2026-11-16 Anthropic verification post (both in the official file). Retrieved 2026-11-19 via search snippet only.

> Source: https://skills-hub.ai/blog/claude-code-verify-skill-name-convention-2026 (search snippet, 2026-11-19)

## Frontmatter Field Inventory: 20 Claude Code Fields vs 6 Spec Fields

`[community:mid]` Serverworks engineer blog (Kenji Kubo, published 2026-08-31, "Claude CodeのSkill frontmatterガイド—全20項目とベストプラクティス"): "2026年8月28日時点で、Claude Codeが受け付けるトップレベルのfrontmatterは全部で20項目です。ただし、オープン仕様のAgent Skillsで定義されているのは6項目だけです。" The 20 match the official table verbatim (`name`…`compatibility`); the 6 are the portability set. Practitioner rules it adds, all consistent with official:

- "Skill auto-execution accuracy depends primarily on `description`" — include concrete scenarios and boundary cases.
- `disable-model-invocation` for deployments, commits, external sends, resource modifications.
- `allowed-tools` "grants temporary authority for a single turn; unlisted tools remain usable but require approval" — corrects the recurring "restricts capabilities" misreading noted 2026-09-04.
- **Separate firing tests from output tests** — build test cases that distinguish "did it trigger" from "was the output good"; matches the 2026-09-16 official wording ("measure separately whether Claude invokes it … and whether the output matches").
- `context: fork` for large-codebase / PR-review / security-analysis tasks, not for reference knowledge.

> Source: https://blog.serverworks.co.jp/claude-code-skill-frontmatter (retrieved 2026-09-16)

## CLAUDE.md = Always-On, Skills = On-Demand (Mental Model)

`[community:mid]` Widely-shared 2026 mental model: CLAUDE.md is always-on context, skills are on-demand capability. Misplacing workflows in CLAUDE.md wastes context every turn; misplacing always-true facts in a skill means Claude often won't see them.

> Source: https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05 (retrieved 2026-06-10)
> Corroborates official guidance ("a skill's body loads only when it's used") and the Japanese-community 使い分け rule above.

## Evaluation-Driven Skill Creation

`[semi-official]` skill-creator eval pipeline (Anthropic, 2026-03 release per Tessl blog):

- 4 modes: **Create, Eval, Improve, Benchmark**
- Eval pipeline uses 4 sub-agents: **executor**, **grader**, **comparator** (blind A/B), **analyzer** (pattern detection)
- Each test case = JSON pairing a realistic user prompt with specific assertions
- Description optimization iterates 20 realistic trigger/non-trigger queries across up to 5 rounds

> Sources:
> - https://tessl.io/blog/anthropic-brings-evals-to-skill-creator-heres-why-thats-a-big-deal (retrieved 2026-04-17)
> - https://deepwiki.com/anthropics/skills/4.1-skill-creator-workflow (retrieved 2026-04-17)

## Token Economics at Scale

`[community:high]` Multiple 2026 surveys (agentskills.io, Microsoft Agent Framework wiki, academic survey arxiv/2602.12430v3) report:

- Median ~80 tokens per skill for metadata (range ~55-235 across Anthropic's 17 official skills)
- 132 skills without progressive disclosure would cost 100,000+ tokens (exceeds most context windows)
- With progressive disclosure: ~7,000-13,000 tokens for all metadata combined at startup

> Source: https://deepwiki.com/microsoft/agent-skills/5.3-progressive-disclosure-pattern (retrieved 2026-04-17)

## Organization Patterns for References

`[community:high]` Microsoft agent-skills wiki consensus patterns:

**Cross-language pattern** (when skill supports multiple technologies):
```
azure-service-skill/
├── SKILL.md          # Overview + language selection
└── references/
    ├── python.md
    ├── dotnet.md
    ├── java.md
    └── typescript.md
```

**Feature-area pattern** (when skill has distinct feature surfaces):
```
azure-ai-agents/
├── SKILL.md          # Core workflow
└── references/
    ├── tools.md
    ├── streaming.md
    ├── async-patterns.md
    └── error-handling.md
```

> Source: https://deepwiki.com/microsoft/agent-skills (retrieved 2026-04-17)

## Japanese Community Consensus (Zenn / Qiita)

`[community:mid]` 2026 Japanese practitioner posts converge on:

1. **description は 250文字前後を意識して前半にキーワード** — though per 2026-04 official docs the per-entry cap in listings is now 1,536 chars, community articles still recommend front-loading within the first ~250 chars for reliable triggering
2. **副作用のあるスキル（deploy, commit など）は `disable-model-invocation: true` 必須** — skills with side effects must opt out of auto-invocation
3. **Personal (`~/.claude/skills/`) = 個人汎用, Project (`.claude/skills/`) = チーム共有 (Git 管理)** — use personal for cross-project, project for team-shared
4. **「最初から完璧を目指さない、箇条書きから育てる」** — start with bullet-point workflow, iterate from real-world feedback
5. **CLAUDE.md と Skills の使い分け**: 常に適用したいルール = CLAUDE.md, 特定作業のみ = Skills

> Sources:
> - https://zenn.dev/yamato_snow/articles/3cd6ed9ac340a2 (retrieved 2026-04-17)
> - https://qiita.com/nogataka/items/ad9995fb1b3db7055740 (retrieved 2026-04-17)
> - https://qiita.com/nogataka/items/c59defafd0dfb88c4a90 (retrieved 2026-04-17)
> - https://zenn.dev/tmasuyama1114/books/claude_code_basic/viewer/skills-creation (retrieved 2026-04-17)

## Security: Treat Skills as Code

`[community:high]` `travisvn/awesome-claude-skills` & Cisco researcher reports:

- Skills can execute arbitrary code in Claude's environment — install only from trusted sources
- Before installing any community skill, read every file (especially `scripts/`)
- Pay attention to instructions that tell the agent to make outbound network calls or send data to external services (prompt-injection-driven exfiltration has been demonstrated)

> Source: https://github.com/travisvn/awesome-claude-skills (retrieved 2026-04-17)

## Ecosystem Adoption

`[community:high]` As of March 2026 (multiple tracker sources):

- 490,000+ skills across three major marketplaces (SkillsMP, Skills.sh, ClawHub)
- OpenAI Codex CLI adopted the Agent Skills standard; official Skills Catalog: `openai/skills` (13K+ stars, 35 curated skills)
- Microsoft GitHub Copilot adopted the same format

Updates as of 2026-06-10:
- obra/superpowers skill library now at ~40.9k GitHub stars — strongest single ecosystem signal for skill-based workflows `[community:high]` (https://github.com/obra/superpowers, retrieved 2026-06-10)
- Vercel maintains skills.sh as a searchable skill directory `[community:mid]` (https://skills.sh, retrieved 2026-06-10)

---

## Practical Community Checklist

Consolidated from the sources above:

1. **Keep SKILL.md under 500 lines** — it's the brain, not the encyclopedia
2. **Description is the trigger** — third-person, front-loaded key terms, slightly pushy
3. **References one level deep** — flat `references/`, `scripts/`, `assets/`
4. **JiT loading** — explicit "see X for Y" pointers
5. **Prefer scripts** for deterministic/repetitive operations
6. **Gotchas section** — append observed failures over time
7. **Use `allowed-tools`** to pre-approve tools in read-only or scoped skills
8. **No README/CHANGELOG** inside skill folders
9. **Build evals first** — ≥3 realistic trigger/non-trigger cases before writing body
10. **Security review** before using community skills — treat as executable code
11. **Reference files explicitly by path** in the step that needs them — they're Read-tool instructions, not `@` imports

# Skill Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects SKILL.md-related insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only)

last_updated: 2026-06-26

---

## Contents

- File References Are Read-Tool Instructions, Not @ Imports
- Tighter Body Target: 1,500-2,000 Words
- Context Hygiene & Lean SKILL.md
- Description as Trigger, Not Summary
- Measured Description Optimization ("Use when...", Examples)
- Pushy Descriptions
- Curate Aggressively: 8-12 Skills, Monthly Audit
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

## Curate Aggressively: 8-12 Skills, Monthly Audit

`[community:mid]` 2026 skill-roundup consensus (Firecrawl, Developers Digest):

- 8-12 well-chosen skills cover most needs; large installed collections dilute the listing budget and trigger accuracy
- Run a monthly skill audit; delete skills that haven't triggered in 30 days
- Complements the official skill-listing budget mechanics (1% of context window; least-invoked descriptions dropped first on overflow) — fewer, better skills keep full descriptions in context

> Sources: https://www.firecrawl.dev/blog/best-claude-code-skills , https://www.developersdigest.tech/blog/best-claude-code-skills-2026 (retrieved 2026-06-10)

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

---

## Changelog

- 2026-05-30: Added two sections: file references are Read-tool instructions (not `@` imports) `[community:high]`, and Anthropic's own `plugin-dev/skill-development` 1,500-2,000-word body target + pre-share checklist `[semi-official]`. Extended consolidated checklist with item 11. Re-verified existing sources (mgechev, shanraisshan, skill-creator, Japanese consensus, security) — no material change; description-as-trigger, pushy descriptions, JiT loading, and side-effect `disable-model-invocation` rule all reconfirmed by 2026-05 community posts.
- 2026-03-30: Initial skeleton
- 2026-04-17: Populated with community research. Added sections: context hygiene (mgechev/skills-best-practices), description-as-trigger (shanraisshan), pushy descriptions (semi-official skill-creator), evaluation-driven development (skill-creator 4-mode pipeline), token economics at scale, cross-language/feature-area reference patterns, Japanese practitioner consensus (Zenn/Qiita), security (awesome-claude-skills + Cisco prompt-injection warning), ecosystem adoption, consolidated 10-item checklist.

- 2026-06-05: Freshness re-run (references were 6 days stale). Re-read official skills + sub-agents docs and a 2026-06 CLAUDE.md best-practices survey (Medium/orchestrator.dev/substack, community:mid). No material change: ~80-120 line practical limit / under-200 / 150-200 instruction budget, the "five things", custom-commands-merged-into-skills, agentskills.io open standard, and auto memory / MEMORY.md (200-line auto-load, routing rules stay in CLAUDE.md) all already captured. last_updated bumped to 2026-06-05.
- 2026-06-10: Added three sections: **Measured Description Optimization** (mellanon gist, 200+ prompt benchmark: 20%→50% activation from optimized descriptions, 72%→90% from examples, "Use when..." phrasing) `[community:mid]`; **Curate Aggressively** (8-12 skills, monthly audit, delete untriggered-in-30-days — Firecrawl/Developers Digest) `[community:mid]`; **CLAUDE.md = always-on / skills = on-demand mental model** (levelup.gitconnected) `[community:mid]`. Ecosystem Adoption updated: obra/superpowers ~40.9k stars `[community:high]`, Vercel skills.sh directory `[community:mid]`. last_updated bumped to 2026-06-10.
- 2026-06-26: Freshness re-run (16 days stale). No new community insights worth adopting. Re-verified existing items against late-June 2026 sources: SKILL.md <500-line consensus, 1,500-2,000 word target (Anthropic plugin-dev), description-as-trigger, pushy descriptions, JiT loading, "skills are for agents not humans" (no README/CHANGELOG), security review of community skills, 8-12 skill curation, monthly audit — all current. Notable ecosystem updates in this window are official/tooling (skill-creator promoted to official plugin at `anthropics/claude-plugins-official`; `/reload-skills` shipped; kebab/snake/camelCase frontmatter tolerance v2.1.186) — recorded in official-best-practices, not community. last_updated bumped to 2026-06-26.
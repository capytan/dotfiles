# Skill Community Best Practices

> This file is auto-updated in Phase 0 (Research).
> Collects SKILL.md-related insights not found in official docs but backed by community traction.
>
> **Credibility tags:**
> - `[semi-official]` = Anthropic employee personal posts, official repo comments
> - `[community:high]` = GitHub 50+ stars, cited in multiple independent articles
> - `[community:mid]` = GitHub 10-50 stars, verified in a tech blog
> - `[community:low]` = Individual report, unverified but reasonable (reference only)

last_updated: 2026-04-17

---

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

## Pushy Descriptions

`[semi-official]` Anthropic's official `skill-creator`:

> "currently Claude has a tendency to 'undertrigger' skills -- to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit 'pushy'. So for instance, instead of 'How to build a simple fast dashboard to display internal Anthropic data.', you might write 'How to build a simple fast dashboard to display internal Anthropic data. Make sure to use this skill whenever the user mentions dashboards, data visualization, internal metrics, or wants to display any kind of company data, even if they don't explicitly ask for a "dashboard."'"
> — https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md (retrieved 2026-04-17)

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

---

## Changelog

- 2026-03-30: Initial skeleton
- 2026-04-17: Populated with community research. Added sections: context hygiene (mgechev/skills-best-practices), description-as-trigger (shanraisshan), pushy descriptions (semi-official skill-creator), evaluation-driven development (skill-creator 4-mode pipeline), token economics at scale, cross-language/feature-area reference patterns, Japanese practitioner consensus (Zenn/Qiita), security (awesome-claude-skills + Cisco prompt-injection warning), ecosystem adoption, consolidated 10-item checklist.

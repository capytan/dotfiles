# Cross-Artifact Checks

> Referenced during Phase 3 (Report) for Cross-Artifact Summary.
> These checks detect issues spanning multiple configuration artifact types.

last_updated: 2026-09-16

---

## Contents

- Check Categories 1-21: Reference Existence, Description Consistency, Circular References, Tool Consistency, Stale References, Subagent Skill-Preload Validity, Duplicate Agent Names, Skill/Bundled-Skill Name Collision, Agent `background: true`, Unresolvable Agent `tools` List, Non-Preloadable Bundled Skills, Stale `/agents` Wizard Guidance, Body Step Requires an Unavailable Tool, Skill Portability (conditional), Personal-Skill Availability in Cloud Contexts, Pool-Wide Agent Description Token Budget, Subagent Model Env Override, `omitClaudeMd` vs CLAUDE.md-Dependent Agent Body, Rules Reachability (symlinks + compaction), Command-Level Restriction in Agent `disallowedTools`, Frontmatter Hooks Trust/Lifetime Asymmetry
- Severity Classification (per-check severity table)
- Changelog

## Check Categories

### 1. Reference Existence
[Verify that referenced skills/agents exist on the filesystem]
- Agent description mentions a skill name → check `.claude/skills/{name}/SKILL.md` exists
- SKILL.md references an agent → check `.claude/agents/{name}.md` exists
- CLAUDE.md mentions a skill/agent by name → verify it exists
- Detection: Grep for skill/agent names across all discovered files, then Glob to verify targets

### 2. Description Consistency
[Check for contradictions between CLAUDE.md and skill/agent descriptions]
- CLAUDE.md states a workflow → skill/agent for that workflow should align
- Agent description claims capabilities → system prompt should support them
- Detection: Extract key claims from each file and cross-compare

### 3. Circular References
[Detect skill→agent→skill reference chains]
- A skill's workflow invokes an agent that invokes the same skill
- Detection: Build a reference graph from all discovered files, check for cycles
- Note: Not all cycles are bugs — some are intentional (e.g., meta-review). Flag for human review.

### 4. Tool Consistency
[Verify tool declarations match actual usage]
- Agent frontmatter `tools:` field lists tools not mentioned in system prompt
- Agent system prompt describes using tools not in `tools:` field
- Skill `tools:` field lists tools not used in any phase
- Detection: Parse tools from frontmatter, grep for tool names in body content

### 5. Stale References
[Detect references to deleted/renamed artifacts]
- References to old skill/agent names that no longer exist
- CLAUDE.md mentions commands or workflows tied to removed skills
- Detection: Collect all referenced names, diff against discovered file list

### 6. Subagent Skill-Preload Validity `[official]` (2026-06)
[Verify agent `skills:` frontmatter entries are preloadable]
- Each skill listed in an agent's `skills:` field exists as a discoverable skill
- No listed skill sets `disable-model-invocation: true` — such skills "cannot be preloaded… Claude Code skips it and logs a warning to the debug log" (https://code.claude.com/docs/en/sub-agents, retrieved 2026-06-10)
- Detection: Parse `skills:` from agent frontmatter, Glob for each SKILL.md, grep its frontmatter for `disable-model-invocation`

### 7. Duplicate Agent Names Within a Scope `[official]` (2026-06)
[Agents dirs are scanned recursively; identity comes only from `name`]
- "if two files within one scope declare the same name, Claude Code keeps one and discards the other without warning" (https://code.claude.com/docs/en/sub-agents, retrieved 2026-06-10)
- Detection: Collect `name:` values across all `.md` files under `.claude/agents/` (recursive) and `~/.claude/agents/` (recursive) per scope; flag duplicates within the same scope
- **Tie-break exception (added 2026-06-26, changelog v2.1.178):** for nested project `.claude/agents/` directories along the cwd walk to the repo root, the closest-to-cwd definition wins deterministically — not silent discard. Downgrade severity to Minor for this specific case.

### 8. Skill Name Collides with Bundled Skill `[official]` (2026-06)
[A project/personal/plugin skill silently overrides a bundled skill with the same name]
- "A skill at any of these levels also overrides a bundled skill with the same name. For example, a `code-review` skill in your project's `.claude/skills/` replaces the bundled `/code-review`." (https://code.claude.com/docs/en/skills, retrieved 2026-06-26)
- Bundled skill names to check against: `code-review`, `batch`, `debug`, `loop`, `claude-api`, `run`, `verify`, `run-skill-generator`, `init`, `review`, `security-review`
- Detection: Glob each `<scope>/skills/<name>/SKILL.md`; warn if `<name>` matches any bundled name. Plugin skills are namespaced (`plugin:name`) and cannot collide.
- **Alias carve-out (2026-09)**: the override does **not** capture a bundled skill's alias — a local `code-review` skill replaces `/code-review` but `/review` still runs the bundled one. Flag config text that assumes the alias follows the override. (Fix version: the changelog places the alias-keyed `skillOverrides` / nested `Skill(name)` deny fixes at v2.1.248, the skills page at v2.1.260 — docs win; either way current.)
- **Alias-keyed `skillOverrides` scope (2026-09-16)**: alias keys work only in managed settings and `--settings` files. "In user, project, and local settings, Claude Code matches entries against skill names only. If you set an entry for `review` there, it applies to a skill named `review`, not to the bundled `/code-review` through its `/review` alias." (https://code.claude.com/docs/en/skills, retrieved 2026-09-16). Flag a user/project/local `skillOverrides` entry keyed by an alias as inert (Minor).

### 9. Agent `background: true` No Longer a Permission Risk `[official]` (2026-06)
[Since changelog v2.1.186, background subagent permission prompts surface in main session]
- Do not flag `background: true` agents for "will silently auto-deny on permission prompts" — that behavior was fixed.
- Still flag a `background: true` agent that has no `tools` allowlist + relies on Bash for irreversible operations (high-blast-radius pattern, separate concern).
- **Updated 2026-07**: background is the *default* as of v2.1.198, and background subagents receive a **narrower built-in tool set** (forks exempt). Flag Major only when the agent's core workflow provably needs an excluded tool; advisory NOTE otherwise. Use this single threshold — it supersedes any flat-Major wording elsewhere.
- **Note (2026-09)**: injected-command abort semantics apply to skills preloaded into forked/background subagents too — a skill whose `` !`cmd` `` exits non-zero aborts the invocation there as well (see skill pool references).
- **Forced-foreground conditions (2026-09-16)**: a `context: fork` skill runs in the foreground regardless of `background` "In non-interactive mode, with the `-p` flag or the Agent SDK; When you set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` to `1`…; When you invoke a forked skill while an earlier invocation of the same skill is still running; When a scheduled task fires with the skill as its prompt" (https://code.claude.com/docs/en/skills, retrieved 2026-09-16). Do not flag a skill for "always runs in background" when one of these applies; check settings.json `env` for `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`.

### 10. Unresolvable Agent `tools` List `[official]` (2026-07)
[A `tools` list where nothing resolves means the agent cannot launch at all]
- As of changelog v2.1.208, when no entry in `tools` resolves to a real tool, Claude Code refuses to launch the subagent and the Agent tool returns an error naming the unresolved entries. Before v2.1.208 it launched with no tools and returned empty/confusing output.
- Detection: parse `tools:` from every agent frontmatter, diff each entry against the tool names actually available to subagents; flag the agent Critical if *every* entry is unresolvable, Major if some are.
- Note the subagent-unavailable set (`Agent` without nested spawning, `AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode` unless `permissionMode: plan`) — these resolve as names but are filtered out, so an agent listing *only* these is effectively in the zero-tools case.

### 11. Non-Preloadable Bundled Skills in `skills:` `[official]` (2026-07)
[Extends Check 6 to the user-invoke-only bundled skills]
- As of v2.1.215, `/verify` and `/code-review` run only when the user invokes them, so they cannot be preloaded into a subagent via `skills:` and Claude cannot auto-run them.
- Detection: flag any agent whose `skills:` names `verify` or `code-review`, and any skill/agent body instructing Claude to run `/verify` or `/code-review` on its own.
- **Carve-out (see Check 8)**: a project/personal/plugin skill of the same name *replaces* the bundled one and is model-invocable again. Before flagging, confirm no local or enabled-plugin skill owns that name — otherwise this false-positives on any repo that ships its own `code-review`.

### 12. Stale `/agents` Wizard Guidance `[official]` (2026-07)
[As of v2.1.198 `/agents` no longer opens the interactive creation wizard]
- `/agents` now prints a reminder to ask Claude or edit `.claude/agents/` directly. Directories, frontmatter fields, and file locations are unchanged.
- Detection: grep CLAUDE.md, SKILL.md, and agent bodies for instructions to "run `/agents`" to create or edit a subagent. Classify Minor (stale documentation, not a functional break).
- **Stale "restart to load" guidance (2026-09-16)**: agents dirs are now hot-reloaded — "Claude Code watches `~/.claude/agents/` and `.claude/agents/` … detects the change within a few seconds … no restart needed" (https://code.claude.com/docs/en/sub-agents, retrieved 2026-09-16), with three exceptions (first file in a brand-new agents dir, `--add-dir` / `/add-dir` directories, `--disable-slash-commands`). Config text telling users to restart after editing an agent file is stale in the same way; Minor.

### 13. Body Step Requires a Tool the Subagent Cannot Have `[custom]` (2026-07)
[Generalizes Checks 10-12: prose instructing a step whose tool is filtered out at launch]
- A subagent's effective tool pool is its declared `tools:` (or all tools if absent) **minus** the always-filtered set in Check 10. A body step that needs a tool outside that pool silently never fires — the subagent skips it or invents an answer.
- Most common instance: a skill phase or agent body telling a subagent to ask the user via `AskUserQuestion`. Hoist the question into the main session and pass the answer into the subagent's prompt.
- Detection: for each skill phase dispatched to a subagent and each agent body, list the tools its steps require and diff against that agent's effective pool. Classify Major.

### 14. Skill Portability — Conditional `[official]` (2026-08)
[Only applies to skills declared as intended for export; skipped otherwise]
- **Precondition**: the skill's own text (SKILL.md, its README, or CLAUDE.md) states it is meant for claude.ai upload, the Skills API, or `package_skill.py` packaging. If no such declaration exists, **skip this check entirely** — do not run it speculatively.
- On those export paths, any frontmatter key outside `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` is a **hard error**. Claude Code-only fields (`when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`) are the usual offenders.
- For Claude Code-only skills those same fields are **correct** — never deduct.
- Detection: grep the skill's text for an export declaration; if found, diff its frontmatter keys against the six-key allowlist. Classify Major.

### 15. Personal-Skill Availability in Cloud/Routine Contexts `[official]` (2026-09)
[Cowork, cloud sessions, and routines do not read `~/.claude/skills/`]
- A workflow declared to run as a routine, scheduled cloud agent, or Cowork session that depends on a personal skill (`~/.claude/skills/`) will not find it — the skill must be enabled via claude.ai or committed to the repo (`.claude/skills/`).
- Detection: grep CLAUDE.md, agent bodies, and skill bodies for routine/cloud/Cowork usage claims; if a referenced skill resolves only under `~/.claude/skills/`, flag Major. Skip when no cloud/routine usage is declared.

### 16. Pool-Wide Agent Description Token Budget `[official]` (2026-09)
[All loaded agent `description` fields share a ~15,000-token budget; exceeding triggers a startup warning]
- This is inherently a cross-file check — no single agent file can violate it alone.
- Detection: estimate total tokens across every discovered agent's `description` (word count × ~1.3 English / ~2.0 Japanese). Flag Minor when the total approaches or exceeds 15,000, naming the largest contributors.

### 17. Subagent Model Env Override `[official]` (2026-09)
[settings.json `env` can silently neutralize agent `model:` frontmatter]
- `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (v2.1.257) overrides every agent's `model:` field; `CLAUDE_CODE_SUBAGENT_MODEL` is only a default below frontmatter in the v2.1.251 resolution order (per-invocation > frontmatter > env default > main). Related env: `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (default 3), `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (default 20), `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`.
- Detection: read `env` from discovered settings.json files; if `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is set while agents declare `model:`, flag Minor (frontmatter is inert, likely surprising). Note depth/concurrency env values when delegation-chain checks (Check 13) assume defaults.

### 18. `omitClaudeMd` vs CLAUDE.md-Dependent Agent Body `[official]` (2026-09)
[Agent frontmatter can opt a subagent out of the CLAUDE.md hierarchy; rules that live only there then never reach it]
- Subagents normally load "every level of the CLAUDE.md hierarchy the main conversation loads, including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, and managed policy files". "Set to `true` to launch this subagent without the user, project, and local CLAUDE.md files; managed policy files still load … Use it for subagents that take everything they need from the delegation prompt." Requires v2.1.271+. (https://code.claude.com/docs/en/sub-agents, retrieved 2026-09-16)
- Built-in Explore/Plan still skip CLAUDE.md with no opt-in; main-session auto memory never reaches subagents except forks.
- Detection: for each agent with `omitClaudeMd: true`, check whether its body or the CLAUDE.md/rules text assumes the agent follows a convention documented only in CLAUDE.md or `.claude/rules/` (e.g. "follow the project's commit rules"). Flag Major when such a dependency exists; advisory otherwise. Conversely, a CLAUDE.md rule phrased as "all subagents must…" is unenforceable for `omitClaudeMd` agents and Explore/Plan — note it.

### 19. Rules Reachability — Symlinks and Compaction `[official]` (2026-09)
[Two ways a `.claude/rules/` file can silently stop applying]
- **Outside-tree symlinks**: a rules symlink whose target is outside the working directory is treated as an external import. "The linked rules don't load until you approve external imports for the project, and after that only the ones without a `paths` field load. Claude Code asks for that approval only when a project memory file imports a file outside the working directory with `@path`, not for symlinks alone." Official alternative: `~/.claude/rules/` or a plugin. (https://code.claude.com/docs/en/memory, retrieved 2026-09-16)
- **Compaction**: project-root CLAUDE.md and **unscoped** rules re-inject from disk after compaction; path-scoped rules and nested CLAUDE.md are summarized away — "If a rule must persist across compaction, drop the `paths:` frontmatter". (https://code.claude.com/docs/en/context-window, retrieved 2026-09-16)
- Detection: `find .claude/rules -type l` and resolve each target against the repo root — flag Major when the target is outside the working directory (rule may never load, and never loads if it has `paths:`). For each rule with `paths:`, check whether its wording is a must-always-hold constraint rather than file-type guidance — flag Minor. Note that `~/.claude/CLAUDE.md` / `~/.claude/skills` / `~/.claude/agents` symlinks (dotfiles layouts) are unaffected; only `.claude/rules/` entries are.

### 20. Command-Level Restriction in Agent `disallowedTools` `[official]` (2026-09)
[A specifier in an agent's `disallowedTools` removes the whole tool]
- "A `disallowedTools` entry with a specifier, such as `Bash(git push *)`, still removes the whole tool from the subagent, not only the matching commands. To keep Bash and block specific commands, add a Bash deny rule such as `Bash(git push *)` to `permissions.deny` in your settings. The rule applies to the main conversation and to subagents." (https://code.claude.com/docs/en/sub-agents, retrieved 2026-09-16)
- Detection: parse `disallowedTools:` from every agent; any entry containing `(` is a specifier → flag Major and point at settings.json `permissions.deny` (check whether an equivalent deny rule already exists there — if so, the agent entry is redundant *and* harmful).

### 21. Frontmatter Hooks — Trust and Lifetime Asymmetry Between Skills and Agents `[official]` (2026-09)
[Hooks declared in a skill and hooks declared in an agent behave differently; config text that treats them alike is wrong]
- Skill hooks: "Frontmatter hooks in a project skill follow the same workspace trust rule as hooks in settings files. Claude Code registers them when you or Claude invoke the skill, including in a `-p` run in a folder you haven't trusted." They persist for the rest of the session unless `once: true`.
- Agent hooks: "Frontmatter hooks in a project subagent run only after you accept the workspace trust dialog for the folder the agent file came from. A `-p` session doesn't count as accepting it." They are removed when the subagent finishes, and `Stop` is converted to `SubagentStop`. (both: https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents, retrieved 2026-09-16)
- Agent-team teammates: "Claude Code doesn't apply the definition's `skills` to a teammate in either display mode. The teammate loads skills from your project and user settings." (https://code.claude.com/docs/en/agent-teams, retrieved 2026-09-16) — an agent's `skills:` preload does not reach it when spawned as a teammate.
- Detection: for each skill/agent with `hooks:` in frontmatter, compare against settings.json hooks for duplication or contradiction; flag a repo-committed skill whose side-effecting hooks are unscoped (no `once: true`, no matcher) as Major (see skill anti-patterns); flag docs that say agent hooks "persist for the session" or that an agent's `skills:` applies to teammates as Minor. Skip the teammate clause when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` / `teammateMode` are absent.

---

## Severity Classification

| Check | Severity if Failed |
|-------|-------------------|
| Reference Existence | Major |
| Description Consistency | Minor |
| Circular References | Minor (flag for review) |
| Tool Consistency | Major |
| Stale References | Major |
| Subagent Skill-Preload Validity | Major |
| Duplicate Agent Names Within a Scope | Major (silent discard); Minor for nested cwd-walk tie-break |
| Skill Name Collides with Bundled Skill | Minor (advisory — silent override) |
| Unresolvable Agent `tools` List | Critical if all entries unresolvable (agent cannot launch); Major if some |
| Non-Preloadable Bundled Skills in `skills:` | Major (this table is the single source for this rule's severity) |
| Stale `/agents` Wizard Guidance | Minor (this table is the single source for this rule's severity) |
| Body Step Requires a Tool the Subagent Cannot Have | Major |
| Skill Portability (conditional) | Major when the skill declares an export target; not run otherwise |
| Personal-Skill Availability in Cloud Contexts | Major when cloud/routine usage is declared; not run otherwise |
| Pool-Wide Agent Description Token Budget | Minor (startup warning, not a functional break) |
| Subagent Model Env Override | Minor (advisory — frontmatter silently inert) |
| `omitClaudeMd` vs CLAUDE.md-Dependent Agent Body | Major when the body depends on CLAUDE.md/rules-only conventions; advisory otherwise |
| Rules Reachability (symlinks + compaction) | Major for outside-tree rules symlink; Minor for `paths:` on a must-always-hold rule |
| Command-Level Restriction in Agent `disallowedTools` | Major (whole tool removed) |
| Frontmatter Hooks Trust/Lifetime Asymmetry | Major for unscoped side-effecting hooks in a repo-committed skill; Minor for stale wording / teammate `skills:` assumption |

---

## Changelog

- 2026-03-30: Initial version
- 2026-06-10: Added `last_updated` header (was missing). Added two new checks from code.claude.com/docs/en/sub-agents (retrieved 2026-06-10): Subagent Skill-Preload Validity (skills with `disable-model-invocation: true` are silently skipped at preload) and Duplicate Agent Names Within a Scope (recursive scan; one file silently discarded). Both classified Major.
- 2026-06-26: Added two new checks and one rule refinement. **Check 8 (new)**: Skill Name Collides with Bundled Skill — project/personal/plugin skills silently override bundled ones (`code-review`, `batch`, `debug`, `loop`, `claude-api`, `run`, `verify`, `run-skill-generator`, plus Skill-tool-callable built-ins `init`, `review`, `security-review`); classified Minor (advisory only — sometimes intentional). **Check 9 (new)**: Agent `background: true` is no longer a permission-auto-deny risk since changelog v2.1.186 — guidance for reviewers, not a check. **Check 7 refinement (changelog v2.1.178)**: nested project `.claude/agents/` along the cwd walk now have a deterministic closest-wins tie-break — downgrade severity to Minor for that specific case (within-one-scope silent-discard stays Major). last_updated bumped to 2026-06-26.
- 2026-07-25: Added three checks from code.claude.com/docs/en/{skills,sub-agents} (retrieved 2026-07-25) and changelog v2.1.196–v2.1.218. **Check 10 (new)**: Unresolvable Agent `tools` List — as of v2.1.208 an all-unresolvable `tools` list makes Claude Code refuse to launch the subagent (previously it launched tool-less), so this is Critical, not cosmetic; the subagent-filtered tool set (`Agent`, `AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode`) counts toward the zero-tools case. **Check 11 (new)**: Non-Preloadable Bundled Skills in `skills:` — v2.1.215 made `/verify` and `/code-review` user-invoke-only, extending Check 6's preload exclusion beyond `disable-model-invocation: true`; classified Major. **Check 12 (new)**: Stale `/agents` Wizard Guidance — v2.1.198 removed the interactive creation wizard, so config text telling users to run `/agents` to create a subagent is stale; Minor. Checks 1–9 re-verified current. last_updated bumped to 2026-07-25.
- 2026-09-04: Refreshed from pool research against code.claude.com/docs/en/{memory,skills,sub-agents,best-practices} + changelog v2.1.229-v2.1.260 (retrieved 2026-09-04). **Check 8 alias carve-out**: bundled-skill override does not capture the alias (`/review` stays bundled even with a local `code-review`); v2.1.248 fixed alias-keyed `skillOverrides` and `Skill(name)` deny on nested `<dir>:name`. **Check 9 note**: injected-command abort semantics reach fork/background-preloaded skills. **Check 15 (new)**: personal skills (`~/.claude/skills/`) are not read by Cowork/cloud/routine sessions — Major when such usage is declared. **Check 16 (new)**: pool-wide ~15,000-token budget for agent descriptions (startup warning) — Minor. **Check 17 (new)**: `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` silently neutralizes agent `model:` frontmatter; depth/concurrency env vars can shift Check 13 assumptions — Minor. Evaluated but not check-affecting: `claudeMdExcludes` symlink both-path matching (v2.1.243), `/context` as the load-verification command, Emphasis Overuse anti-pattern (single-file concern). last_updated bumped to 2026-09-04.
- 2026-09-16: Refreshed from pool research against code.claude.com/docs/en/{memory,skills,sub-agents,hooks,context-window,agent-teams} + changelog v2.1.261–v2.1.273 (retrieved 2026-09-16). **Check 18 (new)**: `omitClaudeMd: true` (v2.1.271) agents lose user/project/local CLAUDE.md and project rules — Major when the body depends on them. **Check 19 (new)**: `.claude/rules/` symlinks pointing outside the working dir are external imports (never load without `@path` approval; `paths:`-scoped ones never load) — Major; `paths:`-scoped rules do not survive compaction while unscoped rules re-inject from disk — Minor for must-always-hold rules. **Check 20 (new)**: a specifier in agent `disallowedTools` removes the whole tool; command-level denies belong in settings `permissions.deny` — Major. **Check 21 (new)**: skill frontmatter hooks are not trust-gated and persist for the session, agent hooks are trust-gated and die with the subagent; agent `skills:` preload is not applied to teammates — Major/Minor. **Check 8**: alias-keyed `skillOverrides` only honored in managed settings / `--settings` files; fix-version discrepancy (changelog v2.1.248 vs docs v2.1.260) noted, docs win. **Check 9**: forced-foreground conditions for `context: fork` skills (`-p`/SDK, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, same skill already running, scheduled task). **Check 12**: extended to stale "restart after editing agents" guidance (agents dirs hot-reload now). Evaluated but not adopted as cross-artifact checks: skill compaction truncation keeps the top of SKILL.md (single-file concern, recorded in skill pool); Stop-hook 8-consecutive-block override (hook material, out of this skill's pools). last_updated bumped to 2026-09-16.
- 2026-08-12: Refreshed against code.claude.com/docs/en/skills and /sub-agents (both retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. **All existing checks re-verified valid.** Wording updates: the nested-subagent budget referenced by delegation-chain checks is now **depth 3 by default** (v2.1.219, was 5); the 200-subagent-per-session spawn cap referenced nowhere here was removed (v2.1.224). **Check 14 (new, conditional) - Skill Portability**: if a skill is declared as intended for claude.ai upload, the Skills API, or `package_skill.py` packaging, any frontmatter key outside `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` is a hard error on that path (Major). For Claude Code-only skills this check does not apply and Claude Code-only fields must not be flagged. last_updated bumped to 2026-08-12.

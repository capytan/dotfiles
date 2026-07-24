# Cross-Artifact Checks

> Referenced during Phase 3 (Report) for Cross-Artifact Summary.
> These checks detect issues spanning multiple configuration artifact types.

last_updated: 2026-07-25

---

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

### 9. Agent `background: true` No Longer a Permission Risk `[official]` (2026-06)
[Since changelog v2.1.186, background subagent permission prompts surface in main session]
- Do not flag `background: true` agents for "will silently auto-deny on permission prompts" — that behavior was fixed.
- Still flag a `background: true` agent that has no `tools` allowlist + relies on Bash for irreversible operations (high-blast-radius pattern, separate concern).

### 10. Unresolvable Agent `tools` List `[official]` (2026-07)
[A `tools` list where nothing resolves means the agent cannot launch at all]
- As of changelog v2.1.208, when no entry in `tools` resolves to a real tool, Claude Code refuses to launch the subagent and the Agent tool returns an error naming the unresolved entries. Before v2.1.208 it launched with no tools and returned empty/confusing output.
- Detection: parse `tools:` from every agent frontmatter, diff each entry against the tool names actually available to subagents; flag the agent Critical if *every* entry is unresolvable, Major if some are.
- Note the subagent-unavailable set (`Agent` without nested spawning, `AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode` unless `permissionMode: plan`) — these resolve as names but are filtered out, so an agent listing *only* these is effectively in the zero-tools case.

### 11. Non-Preloadable Bundled Skills in `skills:` `[official]` (2026-07)
[Extends Check 6 to the user-invoke-only bundled skills]
- As of v2.1.215, `/verify` and `/code-review` run only when the user invokes them, so they cannot be preloaded into a subagent via `skills:` and Claude cannot auto-run them.
- Detection: flag any agent whose `skills:` names `verify` or `code-review`, and any skill/agent body instructing Claude to run `/verify` or `/code-review` on its own.

### 12. Stale `/agents` Wizard Guidance `[official]` (2026-07)
[As of v2.1.198 `/agents` no longer opens the interactive creation wizard]
- `/agents` now prints a reminder to ask Claude or edit `.claude/agents/` directly. Directories, frontmatter fields, and file locations are unchanged.
- Detection: grep CLAUDE.md, SKILL.md, and agent bodies for instructions to "run `/agents`" to create or edit a subagent. Classify Minor (stale documentation, not a functional break).

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
| Non-Preloadable Bundled Skills in `skills:` | Major |
| Stale `/agents` Wizard Guidance | Minor |

---

## Changelog

- 2026-03-30: Initial version
- 2026-06-10: Added `last_updated` header (was missing). Added two new checks from code.claude.com/docs/en/sub-agents (retrieved 2026-06-10): Subagent Skill-Preload Validity (skills with `disable-model-invocation: true` are silently skipped at preload) and Duplicate Agent Names Within a Scope (recursive scan; one file silently discarded). Both classified Major.
- 2026-07-25: Added three checks from code.claude.com/docs/en/{skills,sub-agents} (retrieved 2026-07-25) and changelog v2.1.196–v2.1.218. **Check 10 (new)**: Unresolvable Agent `tools` List — as of v2.1.208 an all-unresolvable `tools` list makes Claude Code refuse to launch the subagent (previously it launched tool-less), so this is Critical, not cosmetic; the subagent-filtered tool set (`Agent`, `AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode`) counts toward the zero-tools case. **Check 11 (new)**: Non-Preloadable Bundled Skills in `skills:` — v2.1.215 made `/verify` and `/code-review` user-invoke-only, extending Check 6's preload exclusion beyond `disable-model-invocation: true`; classified Major. **Check 12 (new)**: Stale `/agents` Wizard Guidance — v2.1.198 removed the interactive creation wizard, so config text telling users to run `/agents` to create a subagent is stale; Minor. Checks 1–9 re-verified current. last_updated bumped to 2026-07-25.
- 2026-06-26: Added two new checks and one rule refinement. **Check 8 (new)**: Skill Name Collides with Bundled Skill — project/personal/plugin skills silently override bundled ones (`code-review`, `batch`, `debug`, `loop`, `claude-api`, `run`, `verify`, `run-skill-generator`, plus Skill-tool-callable built-ins `init`, `review`, `security-review`); classified Minor (advisory only — sometimes intentional). **Check 9 (new)**: Agent `background: true` is no longer a permission-auto-deny risk since changelog v2.1.186 — guidance for reviewers, not a check. **Check 7 refinement (changelog v2.1.178)**: nested project `.claude/agents/` along the cwd walk now have a deterministic closest-wins tie-break — downgrade severity to Minor for that specific case (within-one-scope silent-discard stays Major). last_updated bumped to 2026-06-26.

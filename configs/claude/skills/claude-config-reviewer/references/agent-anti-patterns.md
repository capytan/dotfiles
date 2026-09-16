# Agent Anti-Pattern Catalog

> Referenced during Phase 2, criterion E (Anti-patterns) for agent file reviews.
> Each pattern has a severity: Critical / Major / Minor.

last_updated: 2026-09-16

---

## Contents

- Critical — Immediate Action Required
- Major — Strongly Recommended to Fix
- Minor — Recommended to Improve

## Critical — Immediate Action Required

### Empty or Near-Empty System Prompt `[custom:derived-from-agent-reviewer]`

System prompt under 100 characters provides no meaningful guidance for autonomous behavior.

**Detection patterns:**
- Character count of content after closing `---` is under 100
- Only a single sentence or placeholder text

**Fix:** Write a full system prompt with role definition, responsibilities, process steps, and output format. See agent-quality-criteria.md category C for minimum expectations.

### No Resolvable Entry in `tools` `[official]` (added 2026-07-25)

As of changelog v2.1.208, when nothing in the `tools` list resolves to a real tool, Claude Code **refuses to launch the subagent** and the Agent tool returns an error naming the unresolved entries. Before v2.1.208 it launched tool-less and returned confusing output.

**Detection patterns (groups per the errors reference, retrieved 2026-09-16):**
- *Unrecognized*: every `tools:` entry is misspelled or invented
- *Not available to subagents*: every entry is in the always-filtered set (`AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode` unless `permissionMode: plan`, `ScheduleWakeup`, `TaskOutput`, `WaitForMcpServers`, `Workflow`) **or** is a built-in outside the background tool set (e.g. `LSP`) — since interactive spawns run in the background by default, foreground-only built-ins resolve to nothing in normal use
- *Matched no tools in this session*: every entry is an MCP pattern for a server that isn't connected (`mcp__github__*`), `Agent` alone on an agent at the depth limit, or (Sep 2026) `TodoWrite`/`TaskCreate`/`TaskGet`/`TaskUpdate`/`TaskList` on a Claude 5-family model without `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`

**Fix:** Correct the tool names, or drop `tools:` entirely to inherit all tools. For a background-dropped tool, remove it or (per the docs) turn fork mode off and run the agent in the foreground. Score under agent-quality-criteria.md criterion A (0 pts) — do not also zero criterion E.

### Empty `tools` List `[official]` (added 2026-09-16)

The refusal above has a blind spot the errors page spells out: "If you leave the `tools` list empty, or `disallowedTools` removes every entry in it, Claude Code also skips the refusal and launches the subagent without tools." No error, no warning — an agent that can only emit text.

**Detection patterns:**
- `tools:` present with no value, `tools: []`, or `tools: ""`
- `disallowedTools` lists every tool that `tools` lists

**Fix:** Delete the `tools` field to inherit, or list the tools the body actually needs. Score under criterion A (0 pts, Critical), same as the refusal case.

### Agent File That Never Loads `[official]` (added 2026-09-04; extended 2026-09-16)

These defects make Claude Code skip the file entirely, so the agent silently doesn't exist. The official list ("Subagent files Claude Code skips", https://code.claude.com/docs/en/sub-agents, retrieved 2026-09-16) is: no `name`; opening `---` not on line 1; `name` starting with `-` or containing `:`; `name` without `description`; YAML that doesn't parse. None is reported in the session — only the debug log (`--debug`).

1. **`name` contains `:`** — reserved for plugin-scoped identifiers ("Claude Code doesn't load a file whose name contains one and logs an error to the debug log"; behavior since v2.1.218). Plugin scope prefixes (`my-plugin:reviewer`) are assigned by the loader, never written in `name`.
2. **`name` starts with `-`** (added 2026-09-16) — same treatment: "skips the file and writes an error to the debug log".
3. **`name` present but `description` missing** (added 2026-09-16) — "Claude Code skips the file and writes the reason to the debug log".
4. **Opening `---` is not the first line** (added 2026-09-16) — a leading blank line, comment, or stray bytes: "Claude Code reads the file as having no frontmatter and treats it as documentation".
5. **YAML that doesn't parse** (added 2026-09-16) — tabs, an unquoted `:` inside a value, bad indentation: "Claude Code reads no fields from the file, skips it, and writes the parse error to the debug log".
6. **UTF-8 BOM at the start of the `.md` file** — silently ignored before v2.1.239 (changelog: "Fixed agents, skills, and commands whose `.md` file starts with a UTF-8 BOM being silently ignored"). Loads on current versions, but breaks teammates on older Claude Code.

(A file with **no `name`** is also skipped, but that is the documented way to keep a README beside your agents — flag it only when the file was obviously meant to be an agent.)

**Detection patterns:**
- `name:` value containing `:` or beginning with `-`
- `description:` absent or empty while `name:` is present
- `head -1 <file>` is not exactly `---`
- The frontmatter block fails a YAML parse (e.g. `description: Use when: foo` with an unquoted colon)
- First 3 bytes of the file are `EF BB BF` (`head -c 3 <file> | xxd`)

**Fix:** Rename to lowercase-and-hyphens without `:` or a leading `-`; add a `description`; make `---` the first line; quote YAML values that contain `:`; re-save the file without a BOM. Score cases 1–5 under agent-quality-criteria.md criterion A (0 pts, Critical); the BOM case is -2 pts under criterion G on current versions.

---

## Major — Strongly Recommended to Fix

### `isolation: worktree` Body That Redirects Git Back to the Main Checkout `[official]` (added 2026-07-25)

An `isolation: worktree` agent gets its own worktree. As of v2.1.216 the working-directory check covers the whole containing repository and, for Bash, the command text itself is inspected — a body instructing `git -C <main>`, `--git-dir`, `GIT_DIR`/`GIT_WORK_TREE`, or a `cd` out of the worktree now **fails outright**, as does a command too complex to check.

**Detection patterns:**
- `isolation: worktree` in frontmatter plus body text containing `git -C`, `--git-dir`, `GIT_DIR=`, `GIT_WORK_TREE=`, or `cd <repo root> && git …`

**Fix:** Operate on the worktree with plain `git <subcommand>`; if the agent genuinely needs the main checkout, drop `isolation: worktree`.

Added 2026-09-16: the check also refuses a command "when it can't verify from the command text that any git the command runs stays inside the worktree, for example when the command name is computed at runtime" — so `$GIT status`, `eval "$cmd"`, or a wrapper script that shells out to git is refused, not inspected. And in *every* subagent (worktree or not), "`cd` commands don't persist between Bash or PowerShell tool calls" — a body that `cd`s in one step and relies on it in the next is wrong regardless of isolation.

### Specifier in `disallowedTools` `[official]` (added 2026-09-16)

`disallowedTools: Bash(git push *)` reads as "Bash, minus git push" but does the opposite of what the author intended: "A `disallowedTools` entry with a specifier, such as `Bash(git push *)`, still removes the whole tool from the subagent, not only the matching commands." The agent loses Bash entirely, and if Bash was its only shell tool the body's command steps silently never run.

**Detection patterns:**
- Any `disallowedTools` entry containing `(` — `Bash(...)`, `Edit(...)`, `mcp__x__y(...)`
- Body steps that run shell commands while `disallowedTools` names `Bash(...)`

**Fix:** Keep `disallowedTools` to bare tool names. Put command-level restrictions in `settings.json` under `permissions.deny` (e.g. `Bash(git push *)`), which "applies to the main conversation and to subagents". Severity: Major (the tool pool is silently narrower than designed).

### `omitClaudeMd: true` With a CLAUDE.md-Dependent Body `[custom]` (added 2026-09-16; derived from official field semantics)

`omitClaudeMd: true` (v2.1.271) strips user, project, and local CLAUDE.md from the subagent's context; only managed policy files remain. The official intent: "Use it for subagents that take everything they need from the delegation prompt." A body that then says "follow the conventions in CLAUDE.md", "apply the project's coding rules", or otherwise leans on rules it never restates has removed its own inputs.

**Detection patterns:**
- `omitClaudeMd: true` in frontmatter plus body text referencing `CLAUDE.md`, "project rules", "repository conventions", `.claude/rules`, or similar without restating them
- `omitClaudeMd: true` on an agent whose README/description promises project-convention enforcement

**Fix:** Either drop `omitClaudeMd`, or move the rules the agent needs into its body (or into a preloaded skill via `skills:`). Severity: Major; scored as -3 pts under criterion G.

### `permissionMode: bypassPermissions` Relied On as an Escalation `[official]` (added 2026-09-16; generalizes the 2026-08-12 org-policy note)

Since v2.1.267 "A subagent that declares `bypassPermissions` keeps the main conversation's mode instead" whenever the parent is in `default`/`dontAsk`/`plan`; and when the parent is in bypass, acceptEdits, or auto mode the frontmatter value is ignored anyway. There is no situation in which the field grants more than the parent has. A body written on the assumption that "this agent runs without prompts" (e.g. unattended destructive git, mass file rewrites with no confirmation step) is broken by design.

**Detection patterns:**
- `permissionMode: bypassPermissions` plus body language like "you run unattended", "no permission prompts will appear", "do not stop to ask"

**Fix:** Remove the field (advisory when harmless) and rewrite the body to tolerate prompts or auto-mode classifier denials. Severity: Major when the body depends on it; otherwise advisory NOTE under criterion A.


### Wrong Voice in System Prompt `[custom:derived-from-agent-reviewer]`

First-person or third-person voice instead of second person. System prompts must address the agent as "you".

**Detection patterns:**
- First person: `I will`, `I am`, `I should`, `My task is`
- Third person: `The agent will`, `This agent is`, `It should`, `The assistant`

**Fix:** Rewrite in second person: `You are`, `You will`, `Your task is`.

### Generic Agent Name `[custom:derived-from-agent-reviewer]`

Names like "helper", "assistant", "agent", or "tool" provide no signal about purpose and risk collision.

**Detection patterns:**
- `name:` value is one of: `helper`, `assistant`, `agent`, `tool`, `bot`, `utility`
- Name does not hint at the agent's domain or function

**Fix:** Use a descriptive name that reflects the agent's purpose (e.g., `code-reviewer`, `migration-planner`, `test-generator`).

### Description Without Trigger Conditions `[official]` + `[community:high]`

Description fails to state **when** the agent should fire. The router can't delegate if it doesn't know the trigger.

**Detection patterns:**
- No "when…" / "after…" / "immediately after…" / "proactively…" / "use to…" phrasing
- Description is purely capability-based ("security expert", "test runner") with no triggering condition
- No action verb (`review`, `analyze`, `optimize`, `debug`, etc.)
- For agents intended to auto-fire: no proactive keyword (`proactively`, `immediately`, `PROACTIVELY`, `MUST BE USED`)

**Fix:** Rewrite the description to state when to use the agent. Either style is acceptable:
- **Prose** (official style): "Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code."
- **`<example>`-block** (community style): 2–4 `<example>` blocks with `Context:`, `user:`, `assistant:`, `<commentary>`.

**Note:** Anthropic's own documented agents use prose-only descriptions. The `<example>`-block convention is a community pattern — not required.

### Unjustified Write/Bash Tools `[custom:derived-from-agent-reviewer]`

`Write` or `Bash` listed in the `tools` array without clear justification from the agent's described functionality.

**Detection patterns:**
- `tools` array contains `Write` or `Bash`
- System prompt describes read-only or analysis-only responsibilities
- No mention of file creation, modification, or command execution in the process steps

**Fix:** Remove unjustified tools. If the agent only reads and reports, restrict to `["Read", "Grep", "Glob"]`. Add tools back only when the system prompt explicitly describes write or execution behavior.

### Behavioral Instructions in Description `[community:high]`

The description contains behavioral instructions ("Always do X", "You will…", step-by-step procedures) instead of routing signals.

**Detection patterns:**
- Description contains second-person/imperative instructions meant for the agent (e.g., `"You are a reviewer. When invoked, you will…"`) — official guidance is to write the description in **third person** ("Always write in third person", Skills authoring best-practices, https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- Description contains numbered procedure steps
- Description describes *how* the agent works rather than *when* it should fire

**Fix:** Move all behavioral content into the system prompt (body). The description should be routing-only and third person ("Reviews code…", "Debugging specialist…"); the body stays second person ("You are…"). "Crystal-clear descriptions guide the router; crystal-clear prompts guide the specialist." (https://github.com/vijaythecoder/awesome-claude-agents)

### Thin System Prompt for Autonomous Agent `[custom:derived-from-agent-reviewer]`

System prompt under 500 words (~3,000 characters) for an agent expected to operate autonomously.

**Detection patterns:**
- Character count between 100 and 2,999
- Agent description implies autonomous decision-making or multi-step workflows
- Lacks process steps, output format, or edge case handling

**Fix:** Expand the system prompt to cover: role definition, core responsibilities (3–8 items), ordered process steps, explicit output format, and edge case handling.

---

## Minor — Recommended to Improve

### Identical Example Phrasing `[custom:derived-from-agent-reviewer]`

All `<example>` blocks use the same phrasing pattern for the user message, reducing trigger variety.

**Detection patterns:**
- User messages across examples start with the same words
- Synonyms or rephrasings are not represented

**Fix:** Vary user message phrasing across examples. Mix direct requests, indirect references, and different vocabulary.

### Stale `/agents` Wizard Guidance `[official]` (added 2026-07-25)

Agent or doc text telling the user to "run `/agents`" to create a subagent. The interactive creation wizard was removed in v2.1.198; `/agents` now only prints a reminder to ask Claude or edit `.claude/agents/` directly. Directories, frontmatter, and file format are unchanged.

**Detection patterns:**
- Body text matching `/agents` near "create", "new agent", or "wizard"

**Fix:** Point the reader at `.claude/agents/` (or `~/.claude/agents/`) directly.

### Stale "Restart to Load" Guidance `[official]` (added 2026-09-16)

Agent or README text telling users to restart Claude Code after editing an agent file. Current docs: "Claude Code watches `~/.claude/agents/` and `.claude/agents/`. When you add or edit a subagent file on disk… Claude Code detects the change within a few seconds and the next delegation uses the updated definition, with no restart needed." Only three cases still need a restart: the first file in a brand-new `agents` directory, `.claude/agents/` inside `--add-dir`/`/add-dir` directories, and sessions started with `--disable-slash-commands`.

**Detection patterns:**
- Body or README text matching "restart" near "agent", "reload", "take effect", "session"
- Guidance that does *not* name one of the three exceptions

**Fix:** Drop the restart instruction, or narrow it to the three exceptions.

### Missing Proactive Trigger Example `[custom:derived-from-agent-reviewer]`

No example demonstrates the agent firing without an explicit user request (auto-trigger after related work).

**Detection patterns:**
- All examples show the user directly asking for the agent's service
- No example where the assistant proactively invokes the agent

**Fix:** Add at least one example where the assistant auto-triggers the agent after completing related work (e.g., reviewing an agent file after helping write one).

### No Edge Case Handling Instructions `[custom:derived-from-agent-reviewer]`

System prompt lacks guidance for failure modes or unusual inputs.

**Detection patterns:**
- No section mentioning edge cases, errors, or fallback behavior
- No "if X is missing" or "if Y fails" conditional instructions

**Fix:** Add an Edge Cases section covering: file not found, malformed input, empty content, and any domain-specific failure modes.

---

## Changelog

- 2026-03-29: Initial version — derived from agent-reviewer.md check items. All items tagged `[custom:derived-from-agent-reviewer]` pending Phase 0 research for official source validation.
- 2026-04-17: Refreshed against code.claude.com/docs/en/sub-agents and community sources.
  - Renamed **"Description Without Sufficient Examples"** → **"Description Without Trigger Conditions"**. Rewrote so the anti-pattern is missing *trigger conditions / action verbs / when-clauses* rather than missing `<example>` blocks. Anthropic's documented agents use prose-only descriptions, so the `<example>`-block count should not be a Major anti-pattern. Now tagged `[official]` + `[community:high]`.
  - Added new Major anti-pattern: **"Behavioral Instructions in Description"** — description should be routing signals only; behavior belongs in the system prompt.
  - Added `last_updated: 2026-04-17` header.
- 2026-05-30: Refresh against code.claude.com/docs/en/sub-agents + Skills authoring best-practices (2026-05-30). Reinforced the **"Behavioral Instructions in Description"** anti-pattern with the official third-person rule ("Always write in third person") — second-person/imperative descriptions are now explicitly called out, with the fix clarifying the third-person-description / second-person-body split. No new anti-patterns added; existing catalog re-verified current.
- 2026-06-10: Freshness re-run against code.claude.com/docs/en/sub-agents (retrieved 2026-06-10). No new anti-patterns; catalog re-verified current. Note for assessors: `fable` model alias and `auto`/`dontAsk` permission modes are now official — not anti-patterns (see agent-quality-criteria.md / agent-official-best-practices.md).
- 2026-06-26: Freshness re-run against code.claude.com/docs/en/sub-agents (retrieved 2026-06-26). No new anti-patterns; catalog re-verified current. **Assessor notes (de-flag previously-uncertain patterns)**: (1) **`background: true`** is NOT a permission-auto-deny risk since changelog v2.1.186 — background subagent permission prompts now surface in the main session. (2) **Nested subagent spawning** is now officially allowed up to depth 5 (changelog v2.1.172) — an agent that lists `Agent` in `tools` to delegate further is not an anti-pattern unless the depth budget is clearly being abused. (3) Old anti-pattern "Subagents cannot spawn other subagents" wording is now outdated guidance from third-party sources — do not penalize agents that rely on official depth-5 nesting.
- 2026-07-25: Freshness re-run against sub-agents docs (retrieved 2026-07-25) + changelog v2.1.196-v2.1.218. **One new Critical anti-pattern**: a `tools` list in which no entry resolves to a real tool - as of v2.1.208 Claude Code refuses to launch the subagent and returns an error naming the unresolved entries (before v2.1.208 it launched tool-less and returned confusing output). Remember the always-filtered set (`Agent` without nested spawning, `AskUserQuestion`, `EndConversation`, `EnterPlanMode`, `ExitPlanMode` unless `permissionMode: plan`) counts toward this. **One new Major**: an `isolation: worktree` agent whose body instructs a git redirect back into the main checkout (`git -C`, `--git-dir`, `GIT_DIR`/`GIT_WORK_TREE`, or a `cd` first) now fails outright (v2.1.216); a command too complex to check also fails. **One new Minor**: agent text telling users to run `/agents` to create a subagent is stale - the interactive wizard was removed in v2.1.198. **One de-escalation**: do not flag the absence of a per-subagent thinking setting; subagents inherit the main conversation's extended-thinking config as of v2.1.198 and no such field exists. last_updated bumped to 2026-07-25.
- 2026-08-12: Freshness re-run against code.claude.com/docs/en/sub-agents (retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. No new anti-patterns. **Correction to the 2026-06-26 assessor note**: the nested-subagent budget is **depth 3 by default** as of v2.1.219, superseding the depth-5 figure recorded then. Delegation-chain designs assuming 4-5 levels are now over budget; still advisory, not a deduction. **De-flag**: the 200-subagent-per-session spawn cap was removed (v2.1.224), so orchestrator agents are not a resource-exhaustion smell on that basis. **New advisory**: an agent body that relies on `permissionMode: bypassPermissions` to work around organization policy is now broken by design - v2.1.223 closed that gap. last_updated bumped to 2026-08-12.
- 2026-09-04: Refreshed against code.claude.com/docs/en/sub-agents (retrieved 2026-09-04) + changelog v2.1.229-v2.1.260. **One new Critical anti-pattern**: "Agent File That Never Loads" — a `name` containing `:` (reserved for plugin scopes, file skipped with only a debug-log error, since v2.1.218) or a UTF-8 BOM at the start of the `.md` (silently ignored before v2.1.239). **Assessor notes**: (1) an agent body that depends on `CLAUDE_CODE_SUBAGENT_MODEL` overriding its `model:` frontmatter is stale — since v2.1.251 the env var is a default, not an override (`CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, v2.1.257, is the explicit override). (2) Do not flag `maxTurns` as risking silent truncation: since v2.1.246 output stopped at the limit is marked partial and the subagent is resumable. (3) The background tool set is now enumerated (19 built-ins + all MCP tools; forks exempt) — check body tool dependencies against it since interactive spawns run in the background by default. (4) Very long descriptions now carry a documented cost: 15,000-token combined description budget with a startup warning. (5) Nesting depth remains 3 by default but is configurable via `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`; a concurrent cap of 20 subagents exists (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`) — both platform limits, advisory only. last_updated bumped to 2026-09-04.
- 2026-09-16: Refreshed against code.claude.com/docs/en/sub-agents, /errors, /agent-teams, /tools-reference (retrieved 2026-09-16) + changelog v2.1.261-v2.1.273. **Critical**: (1) "Agent File That Never Loads" extended with the official skipped-file list — `name` starting with `-`, `name` without `description`, opening `---` not on line 1, unparseable YAML (all silent, debug log only). (2) **New "Empty `tools` List"** — an empty list, or one that `disallowedTools` empties, launches tool-less with *no* refusal (errors page). (3) "No Resolvable Entry in `tools`" detection rewritten around the three official failure groups, adding background-dropped built-ins (interactive default) and the model-gated `TodoWrite`/`TaskCreate`… tools on Claude 5 models. **Major (new)**: "Specifier in `disallowedTools`" (`Bash(git push *)` removes all of Bash; use `permissions.deny`); "`omitClaudeMd: true` With a CLAUDE.md-Dependent Body" `[custom]` (-3 under G); "`permissionMode: bypassPermissions` Relied On as an Escalation" (never grants more than the parent, v2.1.267). Worktree anti-pattern extended: unverifiable/computed git invocations are refused, and `cd` never persists across Bash calls in any subagent. **Minor (new)**: "Stale 'Restart to Load' Guidance" — agents dirs are hot-reloaded (three exceptions). **Assessor notes**: `memory:` auto-enables Read/Write/Edit (not an unjustified-tools finding — the docs define it, but note it on read-only agents); `SubagentHandback` (v2.1.271, auto mode) is injected regardless of `tools`/`disallowedTools` — listing or denying it is a no-op; under a parent in auto mode (the Pro/Max/Team default) every frontmatter `permissionMode` is ignored and the classifier reviews the subagent's final report; a definition reused as an agent-team teammate never gets its `skills` preloaded; `background: true` errors when the spawner is an in-process teammate. last_updated bumped to 2026-09-16.

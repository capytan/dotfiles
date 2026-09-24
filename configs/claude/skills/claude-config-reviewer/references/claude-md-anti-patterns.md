# Anti-Pattern Catalog

last_updated: 2026-09-24

> Referenced during Phase 2, criterion F (Anti-patterns).
> Each pattern has a severity: Critical / Major / Minor.

---

## Contents

- Critical — Immediate Action Required
- Major — Strongly Recommended to Fix
- Minor — Recommended to Improve

## Critical — Immediate Action Required

### Hardcoded Secrets `[official]`

API keys, tokens, passwords, or credentials in the file.
CLAUDE.md is typically git-tracked, making this a high-risk leak vector.

**Detection patterns:**
- Prefixes: `sk-`, `ghp_`, `gho_`, `Bearer `
- Assignments containing `password`, `secret`, `token`, `api_key`
- Long Base64-encoded strings

**Fix:** Remove immediately. Recommend scrubbing from git history.

---

## Major — Strongly Recommended to Fix

### Instruction to Reproduce Reasoning in the Response `[official]` (added 2026-09-24)

A standing instruction telling Claude to write out, echo, transcribe, or "show" its internal reasoning as response text ("think step by step and show your reasoning", "explain your thinking before answering", "write your reasoning in a <thinking> block"). On models with always-on thinking this is no longer a harmless style preference — it can trigger a safety-classifier refusal.

> "Don't instruct Claude to reproduce its reasoning in the response. Prompts, skills, or harness instructions that tell the model to echo, transcribe, or explain its internal reasoning as response text can trigger the `reasoning_extraction` refusal category on Claude Fable 5, causing elevated fallbacks to Claude Opus 4.8. Audit existing skills and system prompts for reflection or show-your-thinking instructions when migrating."
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 (retrieved 2026-09-24)

> "Reasoning extraction: Requests that push the model to reproduce its internal reasoning in the response text can be declined with the `reasoning_extraction` category, which is new if you're coming from Claude Opus 5. If your prompts ask the model to write out its reasoning in the response, remove those instructions"
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5 (retrieved 2026-09-24)

**Detection patterns:**
- "show your reasoning / thinking", "explain your thought process before answering", "write out your chain of thought", "reason step by step in your reply"
- Instructions to wrap reasoning in `<thinking>` / `<reasoning>` tags in the visible output
- Distinguish from legitimate asks: "state the assumption you made", "give the reason for the recommendation", "cite the evidence" ask for a *justification of the result*, not a transcript of internal reasoning — do not flag those

**Fix:** Delete the line. If visibility is the goal, ask for the conclusion plus its evidence (test output, file:line) instead. Severity Major because on Fable 5 / 5.1 and Opus 5.5 (the current default Opus) the failure mode is a refusal, not just wasted tokens.

### Over-Specified CLAUDE.md `[official]`

> "The over-specified CLAUDE.md. If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

Files exceeding 200 lines (official threshold) where important rules get lost in noise.
Community consensus tightens this: HumanLayer keeps theirs under 60 lines; abhishekray07 reports adherence falling off above 80 lines. Claude Code's system prompt already consumes ~50 of the ~150–200 instructions frontier models reliably follow.

**Detection patterns:**
- Line count over 200 (official threshold)
- Line count over 80 (community adherence cliff)
- Multiple sections covering the same topic
- Rules Claude already follows correctly without being told

**Fix:** "Ruthlessly prune. If Claude already does something correctly without the instruction, delete it or convert it to a hook." Consider moving supplementary content to `agent_docs/` with `file:line` pointers, or to skills/rules with `paths:` frontmatter.

### Copy-Pasted External Docs `[official]`

Library or framework docs pasted verbatim into CLAUDE.md.
Claude has broad library knowledge — this is redundant token cost.

**Detection patterns:**
- Large API reference blocks for a specific library
- "Installation" / "Getting Started" sections copied in
- Excessive external doc URLs (5+)

**Fix:** Keep only project-specific customizations. Remove generic explanations. Link to docs instead.

### Tutorial-Style Content `[official]`

Step-by-step guides that belong in README or docs, not CLAUDE.md.

**Detection patterns:**
- "Step 1:", "Step 2:" numbered sequences
- Beginner-oriented explanations ("First, install...")
- References to screenshots or diagrams

**Fix:** Move to README.md or docs/. Keep only commands in CLAUDE.md.

### Excessive Inferable Information `[official]`

Repeatedly stating things Claude already knows.

> "Anything Claude can figure out by reading code" belongs in the Exclude column.
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

**Detection patterns:**
- Standard command explanations ("use `git status` to check status")
- Generic advice ("write clean code", "always write tests")
- Basic usage of well-known frameworks
- Standard language conventions Claude already knows

**Fix:** Delete. Keep only project-specific deltas.

### Stale Information `[custom]` `[official]`

Content that has drifted from the actual codebase, or from the current model's capabilities.

> "Revisit after major model releases: instructions that worked around an older model's limitation may become overhead once a newer model handles the case on its own. For example, a rule that forces single-file refactors can be deleted once the limitation is gone."
> — https://code.claude.com/docs/en/large-codebases (retrieved 2026-09-16)

**Detection patterns:**
- References to nonexistent file paths
- Commands that no longer work
- Mentions of deprecated tools or versions
- Time-dependent expressions: "as of [date]", "currently", "recently"
- **Model-era workarounds (added 2026-09-16)**: rules that only compensate for behavior current models no longer show — forced single-file edits, "always summarize after every tool call", "if in doubt use [tool]", enumerated lists of every case a one-line instruction already covers, anti-markdown blocks copied from older setups (Fable 5.1 "already formats less than earlier models, so … a block like this can suppress structure the content needs")
- **Model-era workarounds — extended 2026-09-24 with official per-model "remove this" guidance** (all `[official]`, retrieved 2026-09-24):
  - *Generic verification / re-check instructions* — Opus 5: "If your prompt contains explicit verification instructions ('include a final verification step for any non-trivial task,' 'use a subagent to verify'), remove them: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality." and "Avoid instructing re-checks it already performs ('double-check your answer,' 're-verify before responding')" — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5. **Not** covered: a concrete, runnable check ("run `bash test.sh` before committing") — that is the official "give Claude a way to verify its work" practice and stays high-value
  - *"Think carefully before answering"* lines — Opus 5.5: "if your system prompt contains instructions that tell Claude to think carefully before answering, consider removing them for Claude Opus 5.5. The model decides for itself how much to think, and effort is the main control." — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
  - *Narration suppression* — Fable 5.1: "Some earlier models were eager to give updates while working, which led to system prompt lines such as 'hold all findings for the final response.' Remove lines like that before adding anything." — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
  - *Blanket anti-formatting rules* — Fable 5.1: "If your prompt contains anti-formatting language, remove it or replace it with a rule that says when specific formatting is appropriate" (same source)
  - *Rules telling the model not to think* — Opus 5: "If your system prompt contains a rule instructing the model not to think or not to reason, remove it; that kind of instruction increases tag leakage." (Opus 5 page)
  - Umbrella official statement (Anthropic blog, Thariq Shihipar, 2026-07-24): "we found that we were overconstraining Claude Code, both through our system prompt and in our CLAUDE.md files and skills … we have since found we can delete many of them and let the model use surrounding context and judgement instead." — https://claude.dev/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models/ (retrieved 2026-09-24; claude.com/blog/… 301-redirects here)
- **Do not flag (added 2026-09-24)**: lines adapted from an official per-model prompt block — e.g. Fable 5.1's "Keep changes and tests to what the task asks for" / "Delivering work" blocks, Opus 5's "Deliver what was asked, at the scope intended", Fable 5.1's "surgically edit a file rather than rewrite" — are *recommended additions*, not workarounds. Only flag them when the file's declared/actual model is one the block was not measured on **and** the reviewer can point to the page saying the behavior differs ("Where a technique names a specific model, treat it as measured on that model and re-check it against your own evals before applying it to another." — claude-prompting-best-practices)

**Fix:** Cross-reference with codebase and update or remove. "Treat CLAUDE.md like code: review it when things go wrong, prune it regularly." For model-era rules, re-test in a fresh session without the rule; official Fable 5 guidance: "Review and consider removing older instructions if default performance is better." Scored under criterion A's inferable-content deduction when the line is obsolete; do not double-count here. (Reasoning-reproduction instructions are a separate Major entry above because they cause refusals, not just overhead.)

### Conflicting Instructions `[official]`

> "If two rules contradict each other, Claude may pick one arbitrarily."
> — https://code.claude.com/docs/en/memory (retrieved 2026-03-29)

Rules that contradict each other across CLAUDE.md files, nested files, or `.claude/rules/`.

**Detection patterns:**
- Same topic addressed differently in root CLAUDE.md vs subdirectory CLAUDE.md
- Style rule in CLAUDE.md conflicts with rule in `.claude/rules/`
- Parent and child CLAUDE.md files give opposite guidance

**Fix:** Review periodically. Consolidate into one authoritative location.

### Guidance That Should Be a Hook `[semi-official]` `[community:high]`

> "An instruction in your CLAUDE.md saying 'never use rm -rf' can be forgotten or overridden by context pressure. A PreToolUse hook that blocks rm -rf fires every single time."
> — https://github.com/trailofbits/claude-code-config (retrieved 2026-03-29)

> "Claude treats them as context, not enforced configuration. To block an action regardless of what Claude decides, use a PreToolUse hook instead."
> — https://code.claude.com/docs/en/memory (retrieved 2026-09-16) — the memory page itself now names the hook as the enforcement path

Hard rules that must be enforced 100% of the time placed in CLAUDE.md instead of hooks. Community framing (eesel.ai, 2026-09-09): "CLAUDE.md is context, not access control."

**Detection patterns:**
- "NEVER", "ALWAYS", "MUST NOT" language for tool-use restrictions
- Formatting requirements that could be a PostToolUse hook
- Security restrictions (blocked commands, forbidden file paths)

**Fix:** Convert to a PreToolUse/PostToolUse hook in `.claude/settings.json`. Keep the guidance in CLAUDE.md as documentation but rely on hooks for enforcement.

---

## Minor — Recommended to Improve

### Verbose Writing `[official]`

Using a paragraph for what fits in one line.

> "Structure: use markdown headers and bullets to group related instructions. Claude scans structure the same way readers do: organized sections are easier to follow than dense paragraphs."
> — https://code.claude.com/docs/en/memory (retrieved 2026-09-16)

> Good practice "Bullet points" vs bad practice "Long paragraphs" — impact: "Better compliance".
> — https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (page updated 2026-06-05, re-read 2026-09-16; the earlier "40% more likely" wording is gone)

**Detection patterns:**
- Repeated information
- Unnecessary preamble ("In this project, we...")
- Excessive adjectives and qualifiers
- Dense paragraphs where bullets would suffice

**Fix:** Rewrite concisely. Use bullet points.

### File Location Catalogs `[custom]`

Listing every file when Claude can discover them by reading the codebase.

**Detection patterns:**
- Exhaustive file lists without explanation
- Directory tree copied verbatim

**Fix:** Keep only non-obvious relationships. Claude can Glob for the structure.

### External Documentation URL Collections `[custom]`

Link dumps to standard tool documentation sites.

**Detection patterns:**
- Links to React, Next.js, Django, etc. official sites
- Links to Stack Overflow or blog posts

**Fix:** Keep only project-specific internal doc links. "Detailed API documentation — link to docs instead."

### Cross-File Duplication `[custom]`

Same content in root CLAUDE.md and subdirectory CLAUDE.md files.

**Detection patterns:**
- Identical commands or rules in multiple files
- Parent info copy-pasted into child files

**Fix:** Consolidate common info in parent. Children contain package-specific info only.

### Information That Changes Frequently `[official]`

Content that needs constant updates belongs elsewhere.

> "Information that changes frequently" is listed in the official Exclude column.
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

**Detection patterns:**
- Version numbers that change with releases
- URLs to environments that rotate
- Dynamic team assignments or ownership info

**Fix:** Move to auto memory, a separate referenced file, or retrieve dynamically via hooks/commands.

### Emphasis Overuse `[official]`

Emphasis markers ("IMPORTANT", "YOU MUST", "NEVER") applied to many lines, so none stands out.

> "If Claude keeps skipping one instruction, add emphasis such as 'IMPORTANT' to that line alone. If you emphasize many lines, none of them stands out."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-09-04)

> "The fix is to dial back any aggressive language. Where you might have said 'CRITICAL: You MUST use this tool when...', you can use more normal prompting like 'Use this tool when...'."
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (retrieved 2026-09-16) — newer models over-trigger on emphasis that older ones needed

> "Providing context or motivation behind your instructions, such as explaining to Claude why such behavior is important, can help Claude better understand your goals and deliver more targeted responses." — with the worked example: less effective "NEVER use ellipses"; more effective "Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them." … "Claude is smart enough to generalize from the explanation."
> — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices (retrieved 2026-09-24)

Community corroboration `[community:mid]`: MindStudio (2026-09-11) reports that all-caps "critical", "must", "always" now "cause over-triggering rather than compliance" on Claude 5-generation models — https://www.mindstudio.ai/blog/claude-fable-5-1-prompting-rules-changed (retrieved 2026-09-24).

**Detection patterns:**
- "IMPORTANT" / "YOU MUST" / all-caps directives on a large share of instructions (rough heuristic: 5+ occurrences, or >10% of lines)
- Every section opening with an emphasis marker
- Escalation stacking ("VERY IMPORTANT!!", "ABSOLUTELY NEVER")
- Bare "NEVER X" / "ALWAYS Y" rules with no stated reason, where the reason is not obvious (2026-09-24: official example above) — note, don't deduct separately; this is scored under criterion E (Actionability) as missing rationale

**Fix:** Reserve emphasis for the one or two instructions Claude actually keeps skipping. Prefer replacing the emphasis with the *reason* ("…because the validator fails open") — current models generalize from the reason. If a rule needs guaranteed compliance, convert it to a hook instead of shouting louder (see "Guidance That Should Be a Hook").

### Telling Claude in Words to Read AGENTS.md `[official]` (added 2026-09-24)

A CLAUDE.md whose job is to point at AGENTS.md in prose ("See AGENTS.md for the rules", "Read AGENTS.md first"), or a `SessionStart` hook that prints AGENTS.md.

> "A `CLAUDE.md` that tells Claude in words to read `AGENTS.md`: Claude sees `AGENTS.md` only if it decides to open the file. Delete the `CLAUDE.md` so Claude reads `AGENTS.md` directly, or replace the sentence with an `@AGENTS.md` import."
> "A `SessionStart` hook that prints `AGENTS.md`: remove it. Once Claude reads `AGENTS.md` directly, the hook adds a second copy to the context."
> — https://code.claude.com/docs/en/memory#remove-an-earlier-agents-md-workaround (retrieved 2026-09-24; native AGENTS.md reading since v2.1.277)

**Detection patterns:**
- Prose reference to AGENTS.md without an `@AGENTS.md` import
- Hook config whose SessionStart command `cat`s AGENTS.md

**Fix:** Replace with `@AGENTS.md`, or delete the CLAUDE.md (and any `CLAUDE.local.md`, which also suppresses AGENTS.md by default) so Claude Code reads AGENTS.md natively. Keep the import form when sessions run on Bedrock/Vertex/Foundry or can't fetch feature flags, where native AGENTS.md reading is unavailable. `@AGENTS.md` imports and a `CLAUDE.md → AGENTS.md` symlink are **not** defects — official: "Keeping the import never makes Claude read `AGENTS.md` twice".

### Session-Specific Content in CLAUDE.md `[official]`

Content that only applies to a specific task or session.

> "CLAUDE.md is loaded every session, so only include things that apply broadly. For domain knowledge or workflows that are only relevant sometimes, use skills instead."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

**Detection patterns:**
- Task-specific instructions mixed with general rules
- Domain knowledge relevant only to certain workflows
- References to "the current sprint" or "this PR"

**Fix:** Move to a skill (SKILL.md) for on-demand loading, or use conversation context.

---

## Changelog

- 2025-05-01: Initial version
- 2026-03-29: Added new anti-patterns from official docs and community research: Over-Specified CLAUDE.md (official), Conflicting Instructions (official), Guidance That Should Be a Hook (semi-official + community:high), Information That Changes Frequently (official), Session-Specific Content (official). Enhanced existing patterns with direct quotes and source URLs. Added SFEIR bullet-point adherence insight to Verbose Writing.
- 2026-04-17: Tightened Over-Specified CLAUDE.md detection with community 80-line adherence cliff (abhishekray07) and the ~150–200 instruction budget finding; added progressive-disclosure fix suggestion (HumanLayer agent_docs/ pattern).
- 2026-05-30: No material change to the anti-pattern catalog. 2026-05-30 research surfaced no new anti-patterns; existing patterns (Over-Specified, Information That Changes Frequently) remain accurate. Awareness note: community now reports that frequent CLAUDE.md edits invalidate the prompt-cache prefix, an additional cost of the "Information That Changes Frequently" pattern, but not severe enough to restructure the entry. last_updated bumped to 2026-05-30.
- 2026-06-10: Freshness re-run against code.claude.com/docs/en/memory (retrieved 2026-06-10). No new anti-patterns; catalog re-verified current. last_updated bumped to 2026-06-10.
- 2026-06-24: Freshness re-run (14 days stale). No new anti-patterns; catalog re-verified current against memory docs + 2026-06 community articles. 2026-06 tooling additions (`--safe-mode`, `/cd`, MEMORY.md compaction) are troubleshooting/session features, not authoring anti-patterns. last_updated bumped to 2026-06-24.
- 2026-06-26: Freshness re-run (2 days stale). No new anti-patterns; catalog re-verified against memory docs (retrieved 2026-06-26). One related detail surfaced in the official docs that does not change the catalog but worth noting for assessors: **`@path` imports inside fenced code blocks or backtick-wrapped spans are NOT parsed**, so previously-flagged "accidental imports in code examples" are not actually a problem if the path is properly fenced. Existing Major/Minor/Critical patterns all current. last_updated bumped to 2026-06-26.
- 2026-07-25: Freshness re-run (29 days stale) against code.claude.com/docs/en/memory (retrieved 2026-07-25). No new authoring anti-patterns; the Critical/Major/Minor catalog is re-verified current. **Two assessor notes added from this window**: (1) the `/doctor` trim checkup (v2.1.206) now codifies the Over-Specified pattern in official tooling - it cuts directory layouts, dependency lists, and architecture overviews and keeps pitfalls, rationale, and non-default conventions, so those three content types are officially inferable content, not merely community opinion. (2) Path-scoped `.claude/rules/` gotchas that read as authoring bugs but are platform behavior: an over-budget brace pattern (1,000 expanded patterns / 4 MiB per rule) is used **unexpanded** so its literal braces match nothing (v2.1.217), and an unparseable `[` bracket expression makes that one pattern match nothing while the rule's other patterns keep working (v2.1.207). Flag these as rule-authoring defects, not CLAUDE.md anti-patterns. last_updated bumped to 2026-07-25.
- 2026-08-12: Freshness re-run against code.claude.com/docs/en/memory (retrieved 2026-08-12) + changelog v2.1.219-v2.1.228. No new anti-patterns; catalog re-verified current. No de-flags. last_updated bumped to 2026-08-12.
- 2026-09-16: Refreshed against memory + best-practices docs, the new large-codebases / context-window / sub-agents pages, the platform prompting guide (retrieved 2026-09-16), and changelog v2.1.261–v2.1.273. **No new anti-pattern; one detection pattern added and two entries re-sourced.** (1) **Stale Information** gains a **Model-era workarounds** detection pattern backed by official text (large-codebases: "instructions that worked around an older model's limitation may become overhead"; Fable 5: "Review and consider removing older instructions if default performance is better"; Fable 5.1: anti-markdown blocks can now "suppress structure the content needs") — tag widened to `[custom]` `[official]`, deduction routed through criterion A's inferable-content schedule. (2) **Emphasis Overuse** gains the platform-guide quote "dial back any aggressive language … 'CRITICAL: You MUST' → 'Use this tool when'". (3) **Guidance That Should Be a Hook** gains the memory page's own line "To block an action regardless of what Claude decides, use a PreToolUse hook instead." (4) **Verbose Writing**: the SFEIR "40%" quote is gone from its source (page updated 2026-06-05); replaced with the official "Structure" quote plus SFEIR's current "Bullet points → Better compliance" table wording. Assessor notes: a symlinked rule whose target is outside the working directory is now officially an external import (never loads without `@path` approval; path-scoped ones never load) — flag as a rules-authoring defect, not a CLAUDE.md anti-pattern; path-scoped rules and nested CLAUDE.md are summarized away on compaction, so a "must always hold" rule with `paths:` is a scoping defect. No de-flags. last_updated bumped to 2026-09-16.
- 2026-09-04: Refreshed against memory + best-practices docs (retrieved 2026-09-04) and changelog v2.1.229–v2.1.260. **One new Minor anti-pattern added: Emphasis Overuse `[official]`** — the best-practices page now explicitly says to emphasize only the one skipped line ("If you emphasize many lines, none of them stands out"); previously the docs only said emphasis improves adherence, so blanket IMPORTANT/YOU MUST usage was not flaggable. Community had long advised this (`use only for genuine hard constraints`); now official. Assessor note: a CLAUDE.md over **4 MiB is skipped entirely** (not truncated) — treat as an extreme instance of Over-Specified. All other patterns re-verified current; no de-flags. last_updated bumped to 2026-09-04.
- 2026-09-24: Refreshed against memory + best-practices docs, the platform prompting guide and the per-model pages for Opus 5, Opus 5.5, Fable 5 and Fable 5.1, the Anthropic blog "The new rules of context engineering for Claude 5 generation models" (all retrieved 2026-09-24), and changelog v2.1.274–v2.1.281 (newest v2.1.281, 2026-09-23). **One new Major**: **Instruction to Reproduce Reasoning in the Response** — "show your reasoning"-style lines can trigger the `reasoning_extraction` refusal category on Fable 5/5.1 and Opus 5.5 (now the default Opus, v2.1.280); justification-of-result asks are explicitly excluded. **One new Minor**: **Telling Claude in Words to Read AGENTS.md** (and SessionStart hooks that print it) — Claude Code reads AGENTS.md natively since v2.1.277 and the memory page lists both as workarounds to remove; `@AGENTS.md` imports and symlinks are not defects. **Stale Information** model-era workarounds extended with official per-model removal guidance: generic verify/double-check instructions (Opus 5), "think carefully before answering" (Opus 5.5), narration suppression and blanket anti-formatting (Fable 5.1), no-thinking rules (Opus 5), plus the official "overconstraining … in our CLAUDE.md files and skills" blog quote; concrete runnable checks stay exempt. **New do-not-flag rule**: lines adapted from official per-model prompt blocks (Fable 5.1 scope/"Delivering work", Opus 5 scope, surgical-edit) are recommended additions; flag only on a documented model mismatch. **Emphasis Overuse** gains the official "NEVER use ellipses → give the reason" example and MindStudio `[community:mid]` corroboration; bare NEVER/ALWAYS without a reason routes to criterion E, not a second F deduction. last_updated bumped to 2026-09-24.

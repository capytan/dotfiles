# Anti-Pattern Catalog

> Referenced during Phase 2, criterion F (Anti-patterns).
> Each pattern has a severity: Critical / Major / Minor.

---

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

### Over-Specified CLAUDE.md `[official]`

> "The over-specified CLAUDE.md. If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise."
> — https://code.claude.com/docs/en/best-practices (retrieved 2026-03-29)

Files exceeding 200 lines (official threshold) where important rules get lost in noise.

**Detection patterns:**
- Line count over 200
- Multiple sections covering the same topic
- Rules Claude already follows correctly without being told

**Fix:** "Ruthlessly prune. If Claude already does something correctly without the instruction, delete it or convert it to a hook."

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

### Stale Information `[custom]`

Content that has drifted from the actual codebase.

**Detection patterns:**
- References to nonexistent file paths
- Commands that no longer work
- Mentions of deprecated tools or versions
- Time-dependent expressions: "as of [date]", "currently", "recently"

**Fix:** Cross-reference with codebase and update or remove. "Treat CLAUDE.md like code: review it when things go wrong, prune it regularly."

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

Hard rules that must be enforced 100% of the time placed in CLAUDE.md instead of hooks.

**Detection patterns:**
- "NEVER", "ALWAYS", "MUST NOT" language for tool-use restrictions
- Formatting requirements that could be a PostToolUse hook
- Security restrictions (blocked commands, forbidden file paths)

**Fix:** Convert to a PreToolUse/PostToolUse hook in `.claude/settings.json`. Keep the guidance in CLAUDE.md as documentation but rely on hooks for enforcement.

---

## Minor — Recommended to Improve

### Verbose Writing `[official]`

Using a paragraph for what fits in one line.

> "Concise bullet-point instructions are more likely to be followed than long paragraphs."
> — https://institute.sfeir.com/en/claude-code/claude-code-memory-system-claude-md/tips/ (retrieved 2026-03-29)

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

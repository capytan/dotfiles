## Communication

- Keep code identifiers, commands, error messages, and paths in their original form
- For technical terms, use the original term or the katakana form in common use (support → サポート, not 支え); don't force a native Japanese word, and use the original when the Japanese translation is ambiguous. This holds for all Japanese output, including briefs and drafts that other agents or PRs/issues will copy verbatim

## Workflow

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- One model per session: the user picks the model when starting the session (a heavier one for heavy design or investigation work) and stays on it through execution. Don't propose a mid-session `/model` switch — each model has its own prompt cache, so switching re-reads the whole conversation both ways. Suggesting `/effort` is fine: an effort change keeps the cache (e.g. `/effort medium` when turns run longer than the task warrants)
- Custom agents/skills live in `~/.claude/agents/` and `~/.claude/skills/` — glob before creating new ones (dotfiles source: `~/dotfiles/configs/claude/{agents,skills,hooks}/`, all symlinked into `~/.claude/`)
- Skills with `metadata:` in their frontmatter are gh-managed; upstream is the source of truth and `gh skill update` overwrites them, so don't hand-edit them. Refresh with `gh skill update --all` (without `--all` it prompts for a source repo for each hand-crafted skill)
- In `grilling` sessions (incl. `/grill-me`, `/grill-with-docs`), ask one question per `AskUserQuestion` call, with the recommended answer as the first option labeled "(Recommended)", and wait for the answer — overrides the skill's "ask the whole frontier in one round"
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)
- Before creating a PR or updating its description, read the repo's PR template (`.github/pull_request_template.md`, the repo root, `docs/`, or `.github/PULL_REQUEST_TEMPLATE/`) and prefer it: keep its headings and comments (markers, etc.). If it has no headings (only comments or markers), keep those as they are and write the body under the headings and guidance of `~/.claude/pull_request_template.md`. If it has headings, add a section from the global template only when the change needs content the repo's sections can't hold. With no repo template, follow the global one. This applies when passing the body with `--body` too, since `gh pr create` only loads a template with `-T` or in interactive mode
- Likewise before creating an issue, read the repo's issue templates (`.github/ISSUE_TEMPLATE/`) and use the one that fits, keeping its headings and comments; if none fits or there are none, follow `~/.claude/issue_templates/bug.md` or `feature.md`. This applies to `gh issue create --body` too
- Size the description to the change. Leave out what the diff already shows, the history of the work, and abandoned attempts. Keep issues to what is needed to reproduce or decide. In PR and issue descriptions, write only decisions and their reasons, the verification that backs them, the steps and cautions the reader needs next, the numbers behind them, and links; don't restate reasons already in a linked issue, ADR, or report, except the grounds a reviewer needs to approve (whether legitimate traffic or users are affected, the blast radius, plan results) — keep those briefly in the PR even if the link has them. When a section needs nothing, write nothing there — keep its heading and template comments, or drop the heading where the template allows
- In text people read (Slack messages, PR/issue bodies and comments, chat replies), refer to issues, PRs, and commits by full URL, not `#123` or a short SHA alone — readers can't resolve the bare reference

## Scope of changes

- Outside plan mode, when the next step is clear and reversible, do it instead of announcing it or asking. Stop only for destructive or outward-facing actions, or for decisions only the user can make
- Don't narrow the request on your own (don't implement part of it and leave the rest as "future work"), and don't widen it either. Everything below restrains extras; implement the requested behavior completely
- If you notice an existing bug, a performance concern, or behavior the request didn't ask for, don't fix it in this change unless the requested behavior can't work without it; list it as a follow-up in the summary. This keeps the diff reviewable
- If the request is ambiguous, implement the reading most directly supported by its wording and the surrounding code, and state that assumption in the summary. Don't build the other readings too
- Don't leave scratch scripts or temporary checks behind, and don't turn them into permanent tests. When writing tests, match the size of the neighboring test files (one focused test per behavior)
- For local changes, use Edit instead of rewriting the whole file with Write. It saves output tokens and time, and the diff is easier to read
- Don't guess about code you haven't opened. When the user points at a file, read it before answering

## Code comments

- Don't write comments that restate what the code already shows: what a line does, a paraphrase of a variable or function name, or what changed and when (that belongs in the commit message). Write a comment only for what the code can't tell the reader: the reason, a constraint, an assumption, or why an oddly written spot is that way. The change's background (what happened, the incident or ticket that prompted it) goes in the commit or PR, not the comment; the comment keeps only the reasons and constraints someone touching the code later could get wrong, such as why the code must stay this way
- This applies to every comment you add when editing existing code too; don't bulk-delete the existing comments

## Hooks

- A PreToolUse validator inspects Bash commands. deny: destructive operations (force-push / `+refspec`, `reset --hard`, `git clean -f`, `rm -rf`, `sed -i`, `gawk -i inplace`) and key/certificate paths (`id_rsa`, `*.pem`, `*.p12`, etc.). ask: destructive deletions (`git branch -D` and variants, `git update-ref -d`, `git worktree remove --force`, `rm -r`, `find -delete`/`-exec rm`, `rimraf`) and sensitive files (`.env`, anything under `~/.ssh`/`~/.aws`/`~/.kube`, `.netrc`, `*.tfvars`, etc.). The exhaustive list is the `SENSITIVE_PATHS` table in dotfiles `configs/claude/hooks/test-pretooluse-validate-command.sh`
- On deny, use only the alternative the hook message names (`sed -i` → the Edit tool; key files → the user runs it with the `!` prefix). Don't achieve the denied effect with another command (`git branch -D` → `git update-ref -d`, `rm -rf` → `find -delete`, etc.). Even if the user approves in conversation, don't work around it — report the situation and ask for direction. If a gate is too strict, fix the hook itself. Deletions are ask rather than deny so that an approval path exists; a deny workaround has actually caused an incident
- Quoted flag values of `git`/`gh` and heredoc bodies passed to `cat`/`tee`/`git`/`gh` are stripped before inspection, so quoting dangerous strings in commit messages or PR bodies won't be denied. Values containing `` ` ``, `$(`, or `${` are not stripped and are inspected. Heredocs for other commands (`python3 -`, `ssh`, etc.) are inspected, so when you need to quote such strings, use `cat <<'EOF'` or a file
- settings.json `Read()`/`Edit()` deny rules also apply to the file commands Claude Code recognizes in Bash (`cat`, `head`, `tail`, `sed`, `tee`) and to redirection targets, but not to `grep -r`, `find -exec`, or files a script opens itself. Whether ask rules apply to Bash is undocumented, so the validator's rules 8/9 handle ask for sensitive paths. Broad name patterns like `*key*`/`*token*` produce too many false positives to be in the validator, so avoid touching such files via Bash yourself
- herdr, the multiplexer, detects agent state from pane output automatically. Don't write your own state-display hooks

## AWS

Applies when the `aws-core` plugin is enabled. The plugin's skills provide detailed guidance on demand, so only rules that must take effect before a skill is loaded live here. Full text: [aws/agent-toolkit-for-aws rules/aws-agent-rules.md](https://github.com/aws/agent-toolkit-for-aws/blob/main/rules/aws-agent-rules.md).

- Before starting a task, find and load the relevant AWS skills, and prefer their guidance over general knowledge
- Prefer the AWS MCP Server (`aws-mcp`) for AWS operations; fall back to the AWS CLI only when it is unavailable. Prefer IaC (CDK / CloudFormation) for creating infrastructure and avoid creating it directly via CLI
- When unsure about API parameters, permissions, limits, or error codes, verify in the documentation instead of guessing. If you can't confirm, state the uncertainty
- Secret Safety: for tasks involving secrets, load the `aws-secrets-manager` skill first. Don't call `secretsmanager get-secret-value` / `batch-get-secret-value` directly or access the Secrets Manager Agent daemon directly. Use `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` + `asm-exec` so values resolve at runtime and never enter the context

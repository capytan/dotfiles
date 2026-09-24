## Communication

- Keep code identifiers, commands, error messages, and paths in their original form. Use the original term for technical terms whose Japanese translation is ambiguous

## Workflow

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- One model per session: the default is `opus[1m]` (Opus 5.5 at its `medium` default); for heavy design or investigation work the user starts the session on `fable` and stays on it through execution. Don't propose a mid-session `/model` switch — each model has its own prompt cache, so switching re-reads the whole conversation both ways. Suggesting `/effort` is fine: on Opus 5.5 and Fable 5.1 an effort change keeps the cache (e.g. `/effort medium` when Fable turns run longer than the task warrants)
- Custom agents/skills live in `~/.claude/agents/` and `~/.claude/skills/` — glob before creating new ones (dotfiles source: `~/dotfiles/configs/claude/{agents,skills,hooks}/`, all symlinked into `~/.claude/`). Path-scoped rules live in the repo-local `~/dotfiles/.claude/rules/` (not symlinked into `~/.claude/`)
- Skills with `metadata:` in their frontmatter are gh-managed; upstream is the source of truth and `gh skill update` overwrites them, so don't hand-edit them. Refresh with `gh skill update --all` (without `--all` it prompts for a source repo for each hand-crafted skill)
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

## Scope of changes

- Outside plan mode, when the next step is clear and reversible, do it instead of announcing it or asking. Stop only for destructive or outward-facing actions, or for decisions only the user can make
- Don't narrow the request on your own (don't implement part of it and leave the rest as "future work"), and don't widen it either. Everything below restrains extras; implement the requested behavior completely
- If you notice an existing bug, a performance concern, or behavior the request didn't ask for, don't fix it in this change unless the requested behavior can't work without it; list it as a follow-up in the summary. This keeps the diff reviewable
- If the request is ambiguous, implement the reading most directly supported by its wording and the surrounding code, and state that assumption in the summary. Don't build the other readings too
- Don't leave scratch scripts or temporary checks behind, and don't turn them into permanent tests. When writing tests, match the size of the neighboring test files (one focused test per behavior)
- For local changes, use Edit instead of rewriting the whole file with Write. It saves output tokens and time, and the diff is easier to read
- Don't guess about code you haven't opened. When the user points at a file, read it before answering

## Hooks

- A PreToolUse validator inspects Bash commands. deny: destructive operations (force-push / `+refspec`, `reset --hard`, `git clean -f`, `rm -rf`, `sed -i`, `gawk -i inplace`) and key/certificate paths (`id_rsa`, `*.pem`, `*.p12`, etc.). ask: destructive deletions (`git branch -D` and variants, `git update-ref -d`, `git worktree remove --force`) and sensitive files (`.env`, anything under `~/.ssh`/`~/.aws`/`~/.kube`, `.netrc`, `*.tfvars`, etc.)
- On deny, use only the alternative the hook message names (`sed -i` → the Edit tool; key files → the user runs it with the `!` prefix). Don't achieve the denied effect with another command (`git branch -D` → `git update-ref -d`, `rm -rf` → `find -delete`, etc.). Even if the user approves in conversation, don't work around it — report the situation and ask for direction. If a gate is too strict, fix the hook itself. Deletions are ask rather than deny so that an approval path exists; a deny workaround has actually caused an incident
- Quoted flag values of `git`/`gh` and heredoc bodies passed to `cat`/`tee`/`git`/`gh` are stripped before inspection, so quoting dangerous strings in commit messages or PR bodies won't be denied. Values containing `` ` ``, `$(`, or `${` are not stripped and are inspected. Heredocs for other commands (`python3 -`, `ssh`, etc.) are inspected, so when you need to quote such strings, use `cat <<'EOF'` or a file
- settings.json `Read()`/`Edit()` deny/ask rules apply only to the file tools, not to Bash `cat`/`head`/`tail`/`echo`/`printf`. Broad name patterns like `*key*`/`*token*` produce too many false positives to be in the validator either, so avoid touching such files via Bash yourself
- herdr, the multiplexer, detects agent state from pane output automatically. Don't write your own state-display hooks
- The stripping algorithm, past bypass cases, and notes for changing the validator are in dotfiles `.claude/rules/pretooluse-validator.md`

## AWS

Applies when the `aws-core` plugin is enabled. The plugin's skills provide detailed guidance on demand, so only rules that must take effect before a skill is loaded live here. Full text: [aws/agent-toolkit-for-aws rules/aws-agent-rules.md](https://github.com/aws/agent-toolkit-for-aws/blob/main/rules/aws-agent-rules.md).

- Before starting a task, find and load the relevant AWS skills, and prefer their guidance over general knowledge
- Prefer the AWS MCP Server (`aws-mcp`) for AWS operations; fall back to the AWS CLI only when it is unavailable. Prefer IaC (CDK / CloudFormation) for creating infrastructure and avoid creating it directly via CLI
- When unsure about API parameters, permissions, limits, or error codes, verify in the documentation instead of guessing. If you can't confirm, state the uncertainty
- Secret Safety: for tasks involving secrets, load the `aws-secrets-manager` skill first. Don't call `secretsmanager get-secret-value` / `batch-get-secret-value` directly or access the Secrets Manager Agent daemon directly. Use `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` + `asm-exec` so values resolve at runtime and never enter the context

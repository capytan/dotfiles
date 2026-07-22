## Communication

- 応答言語: 日本語
- コード識別子・コマンド・エラーメッセージは原文維持
- 技術用語は日本語訳が曖昧なら原文を使う
- Diacritical marks と特殊文字は保持（"für" → "fur" のような置換禁止）
- 冗長な前置き（「承知しました」「はい、喜んで」等）は不要、直接本題へ

## Workflow Preferences

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- Custom agents/skills live in `~/.claude/agents/` and `~/.claude/skills/` — glob before creating new ones (dotfiles source: `~/dotfiles/configs/claude/{agents,skills,hooks}/`, all symlinked into `~/.claude/`). Path-scoped rules live in the repo-local `~/dotfiles/.claude/rules/` (not symlinked into `~/.claude/`)
- Skills directory mixes hand-crafted skills (no `metadata:` frontmatter, source-of-truth is dotfiles) and gh-managed skills (installed via `gh skill install --agent claude-code --scope user`, carry `metadata: {github-repo, github-ref, github-tree-sha}`, source-of-truth is upstream). Do NOT hand-edit gh-managed ones — `gh skill update` overwrites. Refresh: `gh skill update --all` (hand-crafted skills without `metadata:` are auto-skipped, safe to mix). Avoid `gh skill update` without `--all` — it prompts per hand-crafted skill for a source repo. `--force` overwrites even hand-edited gh-managed skills. Filter list to gh-managed only: `gh skill list --scope user --jq '.[]|select(.sourceURL!="")'`
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

## Hooks

- PreToolUse validators block dangerous patterns (force-push/`+refspec`, `reset --hard`, `git clean -f`, `git branch -D`, `rm -rf`, `sed -i`, `gawk -i inplace`) and gate secret-file paths (case-insensitive): 鍵・証明書 (`id_rsa`/`id_ed25519`/`id_dsa`/`id_ecdsa`/`*.pem`/`*.pfx`/`*.p12`/`*.jks`) は deny、機微ファイル (`.env`/`.envrc`/`~/.ssh`・`~/.aws`・`~/.kube` 配下/`secrets`・`credentials` ディレクトリ/`.netrc`/`.docker/config.json`/`*.tfvars`) は ask。text-only なコマンド (`git commit`/`log`/`branch`/`tag`/`checkout`/`echo`/`printf` 等) と `.example`/`.template`/`.sample`/`.dist`/`.j2`/`.tpl`/`.pub` suffix は除外して message や public key を誤検知しない。Deny/ask output uses the `hookSpecificOutput.permissionDecision` schema; validators fail open. Source: `~/dotfiles/configs/claude/hooks/pretooluse-validate-command.sh`
- settings.json の `Read()`/`Edit()` deny・ask はファイル操作ツール (Read / Edit / Write) にのみ適用され、Bash 経由の `cat`/`head`/`tail`/`echo`/`printf` は素通り。具体パスの秘密ファイルは上記 validator が deny/ask で塞ぐが、`**/*key*`・`**/*token*` 等の広い名前パターンは false positive 過多で validator に入れていないので、この種の名前のファイルを Bash で触るときはエージェント側で回避する
- tmux window-name emoji state: ⏳ working / 🤖 subagent / ⚠️ permission/error / ❌ tool failure / ✅ stop. **1 tmux window = 1 Claude Code pane** (panes in the same window fight over the name)
- tmux ops: log `tail -F ~/.cache/claude-tmux-status.log`, disable `export CLAUDE_TMUX_LOG=0`. Engineering details (priority table, force-update events, ✅→⏳ reset) live in `~/dotfiles/.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`)

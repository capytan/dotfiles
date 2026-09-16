---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- Don't put `//` comments in the `permissions` arrays — Claude Code v2.1.216+ warns on unknown deny/ask rules (`"// ..." matches no known tool`). File rules must use `Edit()`/`Read()`, not `Write()`/`Glob()` (file permission checks only consult those two forms; `Write()`/`Glob()` are silently ignored)
- Don't add `Bash(git -C * <subcmd> *)`-style **allow** rules — the wildcard before the subcommand also matches injected options (`-c core.fsmonitor=...`, `--exec-path`), so arbitrary commands get approved without a prompt, and Claude Code warns about it at every startup. Cross-repo `git -C` is handled by the auto-mode classifier + PreToolUse validator instead (removed in this repo once; don't reintroduce). Wildcards in `ask` rules are fine — worst case is an extra prompt
- Update `setup-claude.sh` when adding new symlink targets
- Use `set -euo pipefail` in hook scripts, except `pretooluse-validate-command.sh` — validators must fail open; with `-e` a jq parse failure exits 2, which PreToolUse treats as "block all commands"
- `herdr-agent-state.sh` は herdr が生成・管理する（`# installed by herdr` ヘッダと `HERDR_INTEGRATION_VERSION` が目印、状態は `herdr integration status`）。この repo の hook 規約は**適用外**で、手で編集しない — `herdr integration install` と herdr 本体の更新が上書きする。`~/.claude/hooks` は repo への symlink なので herdr の書き込みは working tree に直接現れる。統合を更新したら差分をそのままコミットすること（整形やスタイル修正を加えない）
- PreToolUse validator の除去アルゴリズム・過去の bypass 実例・変更時の注意は `.claude/rules/pretooluse-validator.md`（`configs/claude/hooks/**` 編集時に自動ロード）

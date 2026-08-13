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

- PreToolUse validator が Bash コマンドを検査する。**deny**: 破壊的操作 (force-push/`+refspec`, `reset --hard`, `git clean -f`, `rm -rf`, `sed -i`, `gawk -i inplace`) と鍵・証明書パス (`id_rsa`/`*.pem`/`*.p12` 等)。**ask**: 破壊的削除 (`git branch -D` 系/`git update-ref -d`/`git worktree remove --force`) と機微ファイル (`.env`/`~/.ssh`・`~/.aws`・`~/.kube` 配下/`.netrc`/`*.tfvars` 等)
- 削除系を deny ではなく ask にしているのは意図的。deny だとユーザーに承認手段が無く、同じ効果の迂回コマンドを誘発する（実際 `branch -D` の deny を `update-ref -d` で抜けた事故がある）。branch/ref は reflog から復元可能なので不可逆な `rm -rf` 等とは区別し、迂回経路ごと同じ確認に載せる
- 判定前に**実行されないテキスト領域**（`git`/`gh` の message 系フラグ値と `cat`/`tee`/`git`/`gh` に渡す heredoc 本文）が除去されるので、コミットメッセージや PR 本文で危険な文字列を引用しただけでは deny されない。ただし `` ` ``・`$(`・`${` を含む値は展開経路があるので除去されず検査される（`git commit -m "$(rm -rf /x)"` は deny のまま）。判定に迷う入力は必ず「検査する」側に倒れる
- validator は fail open、出力は `hookSpecificOutput.permissionDecision` schema。実装は `configs/claude/hooks/pretooluse-validate-command.sh`。除去アルゴリズムの詳細・過去の bypass 実例・変更時の注意は `.claude/rules/claude-config.md`（dotfiles リポジトリ内でのみ自動ロードされる path-scoped rule）
- hook が `deny` を返したら、**hook のメッセージが明示した代替手段のみ**を使う (`sed -i` → Edit ツール、鍵ファイル → ユーザーが `!` プレフィックスで実行)。拒否された効果そのものを別コマンドで達成しない (`git branch -D` → `git update-ref -d`、`rm -rf` → `find -delete` 等)。ユーザーが会話で承認しても迂回経路は使わず、状況を報告して指示を仰ぐ。ゲートが厳しすぎるなら迂回ではなく hook 自体を直す
- settings.json の `Read()`/`Edit()` deny・ask はファイル操作ツール (Read / Edit / Write) にのみ適用され、Bash 経由の `cat`/`head`/`tail`/`echo`/`printf` は素通り。具体パスの秘密ファイルは上記 validator が deny/ask で塞ぐが、`**/*key*`・`**/*token*` 等の広い名前パターンは false positive 過多で validator に入れていないので、この種の名前のファイルを Bash で触るときはエージェント側で回避する
- tmux window-name emoji state: ⏳ working / 🤖 subagent / ⚠️ permission/error / ❌ tool failure / ✅ stop. **1 tmux window = 1 Claude Code pane** (panes in the same window fight over the name)
- tmux ops: log `tail -F ~/.cache/claude-tmux-status.log`, disable `export CLAUDE_TMUX_LOG=0`. Engineering details (priority table, force-update events, ✅→⏳ reset) live in `~/dotfiles/.claude/rules/claude-config.md` (path-scoped to `configs/claude/**`)

## AWS

`aws-core` plugin が有効なとき適用。詳細ガイダンスは plugin の skill 群が on-demand で提供するので、ここには skill が読まれる前に効く必要のあるルールだけ置く。全文は [aws/agent-toolkit-for-aws rules/aws-agent-rules.md](https://github.com/aws/agent-toolkit-for-aws/blob/main/rules/aws-agent-rules.md)。

- タスク開始前に関連 AWS skill を探してロードし、一般知識より skill のガイダンスを優先する
- AWS 操作は AWS MCP Server（`aws-mcp`）優先。使えない場合のみ AWS CLI に落とす。インフラ作成は IaC（CDK / CloudFormation）優先で、直接 CLI での作成は避ける
- API パラメタ・権限・上限・エラーコードが不確かなときは推測せずドキュメントで検証。確認できないなら不確実性を明示する
- **Secret Safety**: 秘密情報を扱うタスクはまず `aws-secrets-manager` skill をロード。`secretsmanager get-secret-value` / `batch-get-secret-value` の直接呼び出しと Secrets Manager Agent daemon への直アクセスは禁止。値を context に載せず実行時に解決するため `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` + `asm-exec` を使う

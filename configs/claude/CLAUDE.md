## Communication

- コード識別子・コマンド・エラーメッセージ・パスは原文のまま書く。技術用語は日本語訳が曖昧なら原文を使う

## Workflow

- Use plan mode (Shift+Tab) for tasks with 3+ steps or architectural decisions; re-plan if something goes sideways
- 重い設計・計画タスクは `/model fable` に切り替えてから plan mode に入り、実行フェーズ前に `/model opus` へ戻す。plan 承認時は context clear を選ぶ（prompt cache はモデル単位なので、切り替え後の再キャッシュ書き込みを抑える）。戻し忘れは statusline のモデル表示で確認
- Custom agents/skills live in `~/.claude/agents/` and `~/.claude/skills/` — glob before creating new ones (dotfiles source: `~/dotfiles/configs/claude/{agents,skills,hooks}/`, all symlinked into `~/.claude/`). Path-scoped rules live in the repo-local `~/dotfiles/.claude/rules/` (not symlinked into `~/.claude/`)
- frontmatter に `metadata:` を持つ skill は gh-managed で upstream が source-of-truth。`gh skill update` が上書きするので手で編集しない。更新は `gh skill update --all`（`--all` 無しだと手製 skill ごとに source repo を尋ねてくる）
- Don't use `git -C <path>` when cwd already matches — use plain `git <subcommand>` so existing permission rules match and Ask prompts don't fire. `-C` only when the target path genuinely differs from cwd (submodule, sibling repo, etc.)

## 変更の範囲

- plan mode の対象外で次の一手が明らかかつ可逆なら、宣言や確認で止まらずに実行する。止まるのは破壊的・外向きの操作や、ユーザーにしか決められない判断のときだけ
- 依頼の範囲を勝手に狭めない（一部だけ実装して残りを「今後の課題」にしない）し、勝手に広げもしない。以下の抑制はすべて extras に対するもので、依頼された挙動は完全に実装する
- 既存バグ・性能懸念・依頼に無い挙動に気づいても、依頼された挙動がそれ無しに動かない場合を除きこの変更では直さず、要約で follow-up として挙げる。差分をレビュー可能な大きさに保つため
- 依頼が曖昧なら、文言と周辺コードが最も直接支持する読みを実装し、その前提を要約に書く。他の読みの分まで作らない
- 検証用の scratch スクリプトや一時チェックは残さず、永続テストに変換しない。テストを書くときの大きさは隣接テストファイル相当（挙動 1 つに focused test 1 つ）
- 局所的な変更は Write で全体を書き直さず Edit で済ませる。出力トークンと時間を抑え、差分も読みやすくなる
- 開いていないコードについて推測で答えない。ユーザーがファイルを指したら読んでから答える

## Hooks

- PreToolUse validator が Bash コマンドを検査する。deny: 破壊的操作（force-push / `+refspec`、`reset --hard`、`git clean -f`、`rm -rf`、`sed -i`、`gawk -i inplace`）と鍵・証明書パス（`id_rsa`、`*.pem`、`*.p12` 等）。ask: 破壊的削除（`git branch -D` 系、`git update-ref -d`、`git worktree remove --force`）と機微ファイル（`.env`、`~/.ssh`・`~/.aws`・`~/.kube` 配下、`.netrc`、`*.tfvars` 等）
- deny されたら hook のメッセージが示した代替だけを使う（`sed -i` → Edit ツール、鍵ファイル → ユーザーが `!` プレフィックスで実行）。拒否された効果を別コマンドで達成しない（`git branch -D` → `git update-ref -d`、`rm -rf` → `find -delete` 等）。会話で承認されても迂回せず、状況を報告して指示を仰ぐ。ゲートが厳しすぎるなら hook 自体を直す。削除系を ask にしているのは承認手段を残すためで、deny を迂回した事故が実際にあった
- `git`/`gh` の引用符付きフラグ値と、`cat`/`tee`/`git`/`gh` に渡す heredoc 本文は検査前に除去されるので、コミットメッセージや PR 本文で危険な文字列を引用しても deny されない。ただし `` ` ``・`$(`・`${` を含む値は除去されず検査される。それ以外のコマンド（`python3 -` や `ssh` 等）の heredoc は検査されるので、引用が要るなら `cat <<'EOF'` かファイル経由にする
- settings.json の `Read()`/`Edit()` deny・ask はファイル操作ツールにだけ効き、Bash の `cat`/`head`/`tail`/`echo`/`printf` には効かない。`*key*`・`*token*` のような広い名前パターンは false positive が多く validator にも入れていないので、その種の名前のファイルを Bash で触るときは自分で避ける
- agent の状態表示は multiplexer の herdr が pane 出力から自動検出する。状態表示の hook は自作しない
- 除去アルゴリズム・過去の bypass 実例・変更時の注意は dotfiles の `.claude/rules/pretooluse-validator.md`

## AWS

`aws-core` plugin が有効なとき適用。詳細ガイダンスは plugin の skill 群が on-demand で提供するので、ここには skill が読まれる前に効く必要のあるルールだけ置く。全文は [aws/agent-toolkit-for-aws rules/aws-agent-rules.md](https://github.com/aws/agent-toolkit-for-aws/blob/main/rules/aws-agent-rules.md)。

- タスク開始前に関連 AWS skill を探してロードし、一般知識より skill のガイダンスを優先する
- AWS 操作は AWS MCP Server（`aws-mcp`）優先。使えない場合のみ AWS CLI に落とす。インフラ作成は IaC（CDK / CloudFormation）優先で、直接 CLI での作成は避ける
- API パラメタ・権限・上限・エラーコードが不確かなときは推測せずドキュメントで検証。確認できないなら不確実性を明示する
- Secret Safety: 秘密情報を扱うタスクはまず `aws-secrets-manager` skill をロードする。`secretsmanager get-secret-value` / `batch-get-secret-value` の直接呼び出しと Secrets Manager Agent daemon への直アクセスは禁止。値を context に載せず実行時に解決するため `{{resolve:secretsmanager:secret-id:SecretString:json-key}}` + `asm-exec` を使う

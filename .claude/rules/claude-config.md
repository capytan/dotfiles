---
paths:
  - "configs/claude/**"
---

# Claude Code Config Rules

- Hooks must use shared functions from `configs/claude/hooks/tmux-lib.sh`
- Don't put `//` comments in the `permissions` arrays — Claude Code v2.1.216+ warns on unknown deny/ask rules (`"// ..." matches no known tool`). File rules must use `Edit()`/`Read()`, not `Write()`/`Glob()` (file permission checks only consult those two forms; `Write()`/`Glob()` are silently ignored)
- Update `setup-claude.sh` when adding new symlink targets
- Use `set -euo pipefail` in hook scripts (except tmux hooks — guard pattern `tmux_guard || exit 0` and emoji matching conflict with `-e`/`-u` — and `pretooluse-validate-command.sh` — validators must fail open; with `-e` a jq parse failure exits 2, which PreToolUse treats as "block all commands")

## PreToolUse validator: 実行されないテキスト領域の除去

rules 1-9 は「コマンド文字列に危険な pattern が現れるか」で判定するため、実行されないテキストに書かれた literal まで拾う。PR 本文を heredoc で組み立てて `rm -rf /var/lib/apt/lists/*` を引用しただけ、`git commit -m "fix: replace rm -rf with individual deletes"` と書いただけで deny される。実害ゼロの deny はゲートへの信頼を下げ、エージェントに迂回経路を探させる動機になるので、判定前にテキスト領域を落とす。

**最重要の不変条件**: 除去してよいのは bash の意味論から「実行されない」と**証明できる**形だけ。判定に迷う入力は必ず「除去しない = 従来どおり検査する」側 (fail-closed) に倒す。逆に倒すと silent allow になり、ゲートが黙って開く。

### `_is_inert_text`

bash が double quote 内 / unquoted heredoc 本文で**実行**を起こせるのは `` `...` `` / `$(...)` / `${ ...; }` (bash 5.3 の funsub) の 3 形式だけ。`$var` は展開されるだけで、展開結果がコマンドとして再パースされることはない（`MSG='; rm -rf /'` でも `git commit -m "$MSG"` は何も削除しない）。よってこの 3 つを含まないテキストは実行されない。**構文の近似ではなく文字列包含の判定**なので bash 側とズレようがない。フラグ値・heredoc 本文・`_skip_path_rules` の 3 箇所でこの 1 関数を共有する。

### フラグ値 (`_strip_flag_values`)

先に引用符付きの値を見つけ、その手前のテキスト（`\n` `|` `;` `&` `` ` `` の最後の区切り以降）から segment の先頭語を求める。**先頭語が `git` / `gh` のときだけ**空にする。値の中に区切り文字が入りうる（`--body "a && b"`）ので、segment 分割を先にやると壊れる。single quote は bash が展開しないので無条件、double quote は `_is_inert_text` が真のときだけ。

フラグ名だけでは値が不活性か決まらない。`ssh h -t "cmd"` の `-t` は pty フラグで値はリモートで実行され、`curl -b "..."` の `-b` は cookie。

### heredoc 本文 (`_strip_heredoc_bodies`)

- **消費者は allowlist** (`cat` / `tee` / `git` / `gh`)。blocklist でインタプリタを列挙する方式は列挙漏れがそのまま silent allow になる（`ssh host <<EOF` は本文をリモートシェルが実行するが、`sh` の前が英数字 `s` なので `(sh|bash|…)` に永久に一致しない）。allowlist なら未知のコマンドは自動的に検査側へ落ちる
- 判定対象は heredoc が属するコマンド（`;` `&` で区切った chunk）の**先頭語だけ**。行全体を見ると `cat > shell/zsh/x.zsh <<'EOF'` のリダイレクト先パスをインタプリタと誤認する
- pipeline は**全 segment**が allowlist に入ること。行末が `|` / `\` なら残りが次行にあり全体が見えていないので除去しない（`cat <<'EOF' |` + 次行 `bash`）
- delimiter に `'` `"` `\` があれば quoted = 本文はリテラルなので無条件に捨てる。`<<\EOF` も bash では quoted で終端は `EOF`（`\` を剥がさないと終端が永久に一致しない）。unquoted は `_is_inert_text` が真のときだけ捨てる
- **fail-safe**: delimiter が見つからないまま読み切ったら、除去結果を捨てて**入力そのもの**を返す。戻り値は「完全に除去済み」か「入力そのまま」の 2 状態だけ。`cat "a << b"` のような誤認で以降の行を丸ごと落とすと、そこに隠れた実コマンドが allow される
- state は `delim` 1 本。`skip` との二重持ちは desync を招き、post-loop の抜けを見えなくする

### `_skip_path_rules` (rules 8/9 の事前 bypass)

`echo` / `printf` / `git commit|log|…` で始まるコマンドは rules 8/9 を飛ばすが、これも「実行されないテキスト」が前提なので `_is_inert_text` を AND する。無条件だと `echo "$(cat <秘密鍵>)"` が素通りする。

### 残る既知の false positive

`git` / `gh` 以外のコマンドのフラグ値に危険な literal を書くと deny される（`printf '%s' 'git push --force'` 等）。これは意図的なトレードオフ。回避は heredoc (`cat <<'EOF'`) かファイル経由。

### 変更するときは

`configs/claude/hooks/test-pretooluse-validate-command.sh` の `rule 0: bypass 回帰` section は、確認済みの bypass を固定したもの。削らないこと。`.github/workflows/hooks-test.yml` が PR で ubuntu (bash 5) と macOS (`/bin/bash` 3.2) の両方で走る。ローカルでは `HOOK_BASH=/bin/bash bash configs/claude/hooks/test-pretooluse-validate-command.sh` で 3.2 を確認できる。

## tmux status emoji priority model

| emoji | priority | meaning |
|---|---|---|
| ⚠️ | 50 | Awaiting user / API error (permission_prompt / idle_prompt / elicitation_dialog / StopFailure) |
| ❌ | 40 | Tool failure (PostToolUseFailure) |
| ✅ | 30 | Response complete (Stop) |
| 🤖 | 20 | Subagent running (SubagentStart, when counter == 1) |
| ⏳ | 10 | Working (SessionStart / UserPromptSubmit / PostToolUse) |

Priority-guarded: a higher-priority state is not overwritten by a lower one. Only `UserPromptSubmit` / `Stop` / `StopFailure` / `SessionStart` force-update. ✅ is reset to ⏳ on the next `UserPromptSubmit`, and ⚠️/❌ is demoted to ⏳ on the next `PostToolUse` (permission approval / tool retry には解除イベントが無いので、次の tool 実行で自動回復させる)。

`SessionStart` の base name は既存の window 名 (絵文字剥ぎ後) を保持し、空のときのみ `basename $PWD` にフォールバックする。これで `tmux-start.local.sh` 等で明示した window 名を上書きしない。

When adding a new hook, choose one of the four `tmux-lib.sh` APIs:

- `tmux_force_set_status <emoji> <hook> [<base>]` — force update, ignores priority. For new-turn / completion events only
- `tmux_set_status_if_priority_allows <emoji> <hook>` — update only when `new >= current`. Default choice
- `tmux_set_status_or_demote_alert <emoji> <hook>` — same as priority-allows, but also demotes ⚠️/❌ regardless of `new`. Used by `PostToolUse` to recover from permission-approval / tool-retry
- `tmux_demote_status <from> <to> <hook>` — downgrade only when current matches `<from>`. Used by SubagentStop (🤖→⏳)

Skip logs (`reason=priority_too_low`) are suppressed by default because `PostToolUse` fires very frequently. Enable with `CLAUDE_TMUX_LOG_SKIP=1` for debugging.

Each hook must call `_tmux_hook_init "$(cat)"` first (runs `tmux_guard` and extracts `session_id` from stdin for log lines).

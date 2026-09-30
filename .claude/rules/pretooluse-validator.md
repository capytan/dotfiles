---
paths:
  - "configs/claude/hooks/**"
  - ".github/workflows/hooks-test.yml"
---

# PreToolUse validator: 実行されないテキスト領域の除去

rules 1-9 は「コマンド文字列に危険な pattern が現れるか」で判定するため、実行されないテキストに書かれた literal まで拾う。PR 本文を heredoc で組み立てて `rm -rf /var/lib/apt/lists/*` を引用しただけ、`git commit -m "fix: replace rm -rf with individual deletes"` と書いただけで deny される。実害ゼロの deny はゲートへの信頼を下げ、エージェントに迂回経路を探させる動機になるので、判定前にテキスト領域を落とす。

**最重要の不変条件**: 除去してよいのは bash の意味論から「実行されない」と**証明できる**形だけ。判定に迷う入力は必ず「除去しない = 従来どおり検査する」側 (fail-closed) に倒す。逆に倒すと silent allow になり、ゲートが黙って開く。

## `_is_inert_text`

bash が double quote 内 / unquoted heredoc 本文で**実行**を起こせるのは `` `...` `` / `$(...)` / `${ ...; }` (bash 5.3 の funsub) の 3 形式だけ。`$var` は展開されるだけで、展開結果がコマンドとして再パースされることはない（`MSG='; rm -rf /'` でも `git commit -m "$MSG"` は何も削除しない）。よってこの 3 つを含まないテキストは実行されない。**構文の近似ではなく文字列包含の判定**なので bash 側とズレようがない。フラグ値・heredoc 本文・`_skip_path_rules` の 3 箇所でこの 1 関数を共有する。

## フラグ値 (`_strip_flag_values`)

先に引用符付きの値を見つけ、その手前のテキスト（`\n` `|` `;` `&` `` ` `` の最後の区切り以降）から segment の先頭語を求める。**先頭語が `git` / `gh` のときだけ**空にする。値の中に区切り文字が入りうる（`--body "a && b"`）ので、segment 分割を先にやると壊れる。single quote は bash が展開しないので無条件、double quote は `_is_inert_text` が真のときだけ。

フラグ名だけでは値が不活性か決まらない。`ssh h -t "cmd"` の `-t` は pty フラグで値はリモートで実行され、`curl -b "..."` の `-b` は cookie。

## heredoc 本文 (`_strip_heredoc_bodies`)

- **消費者は allowlist** (`cat` / `tee` / `git` / `gh`)。blocklist でインタプリタを列挙する方式は列挙漏れがそのまま silent allow になる（`ssh host <<EOF` は本文をリモートシェルが実行するが、`sh` の前が英数字 `s` なので `(sh|bash|…)` に永久に一致しない）。allowlist なら未知のコマンドは自動的に検査側へ落ちる
- 判定対象は heredoc が属するコマンド（`;` `&` で区切った chunk）の**先頭語だけ**。行全体を見ると `cat > shell/zsh/x.zsh <<'EOF'` のリダイレクト先パスをインタプリタと誤認する
- pipeline は**全 segment**が allowlist に入ること。行末が `|` / `\` なら残りが次行にあり全体が見えていないので除去しない（`cat <<'EOF' |` + 次行 `bash`）
- delimiter に `'` `"` `\` があれば quoted = 本文はリテラルなので無条件に捨てる。`<<\EOF` も bash では quoted で終端は `EOF`（`\` を剥がさないと終端が永久に一致しない）。unquoted は `_is_inert_text` が真のときだけ捨てる
- **fail-safe**: delimiter が見つからないまま読み切ったら、除去結果を捨てて**入力そのもの**を返す。戻り値は「完全に除去済み」か「入力そのまま」の 2 状態だけ。`cat "a << b"` のような誤認で以降の行を丸ごと落とすと、そこに隠れた実コマンドが allow される
- state は `delim` 1 本。`skip` との二重持ちは desync を招き、post-loop の抜けを見えなくする

## `_skip_path_rules` (rules 8/9 の事前 bypass)

`echo` / `printf` / `git commit|log|…` で始まるコマンドは rules 8/9 を飛ばすが、これも「実行されないテキスト」が前提なので `_is_inert_text` を AND する。無条件だと `echo "$(cat <秘密鍵>)"` が素通りする。

## 機密パス方針 (rules 8/9 と settings.json)

対象パスの正は `test-pretooluse-validate-command.sh` の `SENSITIVE_PATHS` 表 (1 行 = `tier|kind|name|表示トークン`)。テストが 3 つを照合する: settings.json の deny/ask にある `Read(`/`Edit(` エントリとの完全一致、kind ごとの代表コマンドに対する rules 8/9 の判定、deny/ask メッセージへの表示トークンの包含。パスを足すときは表に 1 行足してテストを落とし、落ちた箇所を直す。

生成ではなく照合にしたのは、validator が fail-open だから。表を runtime に読ませると、読めなかったときに鍵の deny が黙って消える。settings.json は `~/.claude/` への symlink 先そのもので、生成物にすると生成忘れがそのまま食い違いになる。

意図的な非対称は kind の定義に置き、テストで振る舞いを固定している:

- `key`: validator は `.pub` を除外、settings.json は `N*` なので `.pub` も deny。file tool が厳しい側に倒れているだけ。negation (`Read(!...)`) は `~/.ssh/...` のような anchored ルールから除外できないので揃えきれない
- `dotenv`: validator はテンプレート (`.example` 等) を除外、settings.json は `.env*` で ask
- `ext` / `key`: validator は cwd の内外を問わず拾う。settings.json の相対パターンは gitignore 意味論で cwd 以下にしか効かない。home 配下の鍵は `~/.ssh/...` で個別に塞いでいる
- `home-dir` / `home-file`: validator は場所を問わず拾い、settings.json は `~/` 配下だけ。Bash の文字列からは `~` / `$HOME` / 絶対パスを区別できないので、validator は場所を問わないしかない
- `file-only` (`*key*` 等): settings.json だけ。Bash では false positive が多すぎるので validator は拾わない

settings.json には意味の重複する行 (`.env*` と `**/.env*`、deny 側の `Edit()`) が残っており、表は現状をそのまま記述している。整理するときは kind の定義ごと変える。

## 残る既知の false positive

`git` / `gh` 以外のコマンドのフラグ値に危険な literal を書くと deny される（`printf '%s' 'git push --force'` 等）。これは意図的なトレードオフ。回避は heredoc (`cat <<'EOF'`) かファイル経由。

## 変更するときは

`configs/claude/hooks/test-pretooluse-validate-command.sh` の `rule 0: bypass 回帰` section は、確認済みの bypass を固定したもの。削らないこと。テストコマンド（bash 5 / `/bin/bash` 3.2）と CI の実行条件は root `CLAUDE.md` の Commands を参照。

---
name: update-nvim-plugins
description: LazyVim（lazy.nvim）のプラグインを、サプライチェーン侵害の事前確認（GitHub への push から 7 日の見送り、差分の危険箇所、作者と merge した人、advisory と報道）を挟んでから更新する。候補を表にして承認を得てから、dotfiles の worktree で lazy-lock.json を書き換えて PR を出し、merge のあとに restore する。Mason の npm のツールも、同じ確認のあと承認を得て入れ替える。「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」「Mason のツールを更新」等で発動する。uv・mise・Homebrew のツールには使わない（`update-local-tools` を使う）。
allowed-tools: Bash, Read, Edit, WebSearch, WebFetch, AskUserQuestion, Agent
---

# Update Nvim Plugins — 侵害確認つきで LazyVim のプラグインを更新する

## このスキルの目的

`configs/nvim/lazy-lock.json` で固定しているプラグインを上げる前に、次を候補ごとに確かめる。

- 上流の branch に push されてから 168 時間未満の commit を避ける（以下「7 日ルール」）
- 差分の危険箇所（build のフック、外部の実行、ダウンロード、難読化、バイナリ）を見る
- 初めての作者の commit と、それを merge した人を見る
- repo が archived や移管されていないか、候補が上流の正規の branch に載っているかを見る
- advisory と報道を調べる。Mason で入れたツールは OSV と trivy で `MAL-` と脆弱性を見る

結果を表で示し、承認を得たものだけ lock を書き換える。lock の変更は origin/main から切った dotfiles の worktree のブランチに commit し、PR にする。プラグインの入れ替えは、PR の merge のあとに `~/dotfiles` を pull してから行う。

## 守ること

- 手順 1〜4 は読み取りだけ。承認の前にプラグインを入れ替えない。`:Lazy update`・`:Lazy sync`・`:Lazy` の画面の `U`・`S` を使わない（branch の先頭や最新の tag まで、確かめずに進む）
- 入れ替えは、lock を書き換えてから `Lazy! restore` で行う。restore は lock の commit にだけ checkout する
- 承認の範囲を広げない。承認後に候補が変わった（手順 1 をやり直した等）ら表を作り直す
- `~/dotfiles` の本体のブランチを切り替えず（main のまま）、本体で commit しない。origin/main から worktree を切り、そのブランチに lock だけを commit して PR にする。merge はしない
- restore は PR の merge のあと（手順 7）、本体を pull してから行う。merge の前は、lock の検証（手順 5）だけを行う
- nvim を起動する前に、手順 1 の `MISSING` が空であること（手順 7 では、承認した `新規プラグイン` だけは出てよい）。spec を読み出したあとの起動（restore、`MasonInstall` など）では、spec にあって lock に無いプラグインも無いこと。起動時のインストール（前提の表）で、確かめていない commit が入るのを防ぐ
- Mason のツールは、手順 1〜6 では確かめるだけで入れ替えない。入れ替えは「Mason のツールの入れ替え」の節で、表と承認を別に取ってから行う
- Mason の npm のツールを入れ替えるときは `npm_config_min_release_age=7` を必ず付ける（`npm_config_min_release_age=7 npm config get min-release-age` が 7 を返さなければ止める）。事前に木を作るときは `--ignore-scripts` を付ける

## When to Use This Skill

発動する依頼:
- 「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」
- 「`:Lazy` で更新が出ている」「プラグインを最新に」
- 「Mason のツールを更新」「Mason のツールの脆弱性を消して」→ 手順 1 の `cutoff`、手順 2-5、「Mason のツールの入れ替え」の節だけを回す（`references/plugin-checks.md` は冒頭の `cutoff` と 2-5 の節だけを読む）

使わないケース:
- uv・mise・Homebrew のツール → `update-local-tools`
- プロジェクトの依存（package.json、pyproject.toml など）→ このスキルの対象外
- 特定のプラグインだけを頼まれた場合も手順は同じ。対象をそのプラグインに絞って回す

## 前提（この環境の事実）

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| 設定の場所 | `~/.config/nvim` は `~/dotfiles/configs/nvim` への symlink。lockfile は `~/.config/nvim/lazy-lock.json`（lazy.nvim の既定） | restore は本体の lock を読み、本体の lock を書き直す。worktree の lock は nvim から見えないので、worktree で書き換えても入れ替わらない |
| プラグインの場所 | `~/.local/share/nvim/lazy/<名前>`。lock の key がディレクトリ名 | `git fetch` と差分の確認はこのディレクトリで行う |
| checker | `checker = { enabled = true, notify = false }`。lazy.nvim の checker は fetch して更新の有無を数えるだけで、入れ替えない | 「更新あり」の表示が出ても、それ自体は危険ではない |
| `version` の指定 | `defaults.version = false` なので、多くは branch の先頭を追う。spec に `version = "*"` などがあるもの（例 LazyVim・lazy.nvim・blink.cmp）は最新の semver の tag を追う | 手順 1 で spec を読み、tag を追うものは tag を候補にする |
| restore の中身 | `restore` は `update` に `lockfile = true` を付けたもの（`lua/lazy/manage/init.lua`）。fetch のあと lock の commit に checkout し、commit が変わったプラグインだけ build を走らせ、最後に lockfile を全プラグインの今の HEAD から書き直す | 名前を付けて restore しても、ほかのプラグインの HEAD が lock とずれていれば、そのずれが lock に書き込まれる。だから名前を付けずに全体を restore する |
| lock の書式 | 書き直しは、名前の順（Lua の `table.sort`）に 1 行 1 プラグインの `  "<名前>": { "branch": "<branch>", "commit": "<sha>" }` を `{`・`}` で囲む（`lua/lazy/manage/lock.lua` の `update`） | 手順 5 で worktree の lock をこの書式で書く。同じ書式なら、手順 7 の restore のあと本体に差分が出ない |
| 壊れた lock | lock が空や不正な JSON だと、lazy.nvim はエラーにせず lock 無しとして扱い、restore が branch の先頭まで進む（`lua/lazy/manage/lock.lua` の `pcall(vim.json.decode, ...)`） | restore の前に `jq` で lock を検証する |
| build のフック | 入れ替えたときに走る。spec の `build`（`nvim-specs.tsv` の `build=` 列。例 `nvim-treesitter` の parser のビルド、`markdown-preview.nvim` のビルド済みバイナリの取得）と、プラグインの `build.lua`・`build/init.lua` | build があるプラグインと、spec を書いている LazyVim は、build まわりの差分を必ず読む |
| 実行時のダウンロード | GitHub Release の成果物を実行時に落とすプラグインがある（例 blink.cmp は tag の release から fuzzy のバイナリを落とし、同じ release の `.sha256` と照合する。attestation は無い） | release の成果物を使うプラグインは、release の公開時刻も 7 日ルールにかける |
| Mason | `~/.local/share/nvim/mason/packages/<名前>/mason-receipt.json` の `source.id` が purl（`pkg:npm/...@版`）。ツールのディレクトリに、推移的な依存や Go のバイナリがある | purl を OSV の querybatch に渡す。OSV に無い種類（github・generic）は空の結果が返る。推移的な依存と Go のバイナリは `trivy rootfs` で見る（2-5） |
| ヘッドレス | lazy.nvim の公式の形は `nvim --headless "+Lazy! sync" +qa`。`!` を付けると処理が終わるまで待つ（doc の Commands） | restore も `nvim --headless "+Lazy! restore" +qa` で行う |
| 起動時のインストール | 設定を読み込んで起動すると、入っていないプラグインを lazy.nvim がその場で clone する（`install.missing` の既定）。lock にあるものは lock の commit に、lock に無いものは branch の先頭（tag を追うものは最新の tag）に checkout する（`lua/lazy/core/loader.lua` の `install({ lockfile = true })`） | lock に無いプラグインが spec にある状態で nvim を起動しない。LazyVim を上げて依存のプラグインが増えるときは、そのプラグインも候補にして lock に足してから起動する |

## 版の上げ方のルール

| 対象 | ルール |
|---|---|
| 公開の時刻 | GitHub の repository activity API（`GET /repos/{o}/{r}/activity`）の `timestamp`。lock の branch に push・PR の merge が届いた、GitHub 側の時刻 |
| 候補（branch を追うもの） | 基準時刻の 168 時間前の時点で、lock の branch の先頭だった commit（その時刻以前で最新の activity の `after`）。日付の差で数えない |
| 候補（tag を追うもの） | lock の branch とリリース用の branch それぞれで、168 時間前の先頭が含む安定版の tag（`vX.Y.Z`、pre-release を除く）のうち、版が最も新しいもの。tag は lock の branch に載っているとは限らない（blink.cmp は `v1` の branch に打つ）ので、branch ごとに調べる。release の成果物を実行時に落とすプラグインは、その tag の GitHub Release の `published_at` も 168 時間以上前であること |
| メジャー跨ぎ | `version = "*"` の lazy.nvim はメジャーを跨いで最新の tag へ進む。候補がメジャーを跨ぐときは印 `メジャー跨ぎ` を付けて要判断にする |
| 候補の条件 | 候補は基準の commit（origin/main の lock）の子孫で、別物であること。同じなら「候補なし」、祖先なら下の「基準が新しすぎる」 |
| 基準が新しすぎる | 基準の commit 自体が 168 時間前の先頭（tag を追うものは候補の tag）より新しい（7 日ルールを通らずに入った）ときは、印 `基準が 168 時間未満` を付けて表に出し、手順 2 にかける。既定はそのまま残し、`cand` に戻すかは承認のときに選ぶ |
| 修正版の例外 | 基準の commit に advisory や侵害報道があり、修正の commit が 168 時間未満なら、候補に残して印 `要判断` を付け、承認のときに個別に決める |

この方法の限界:
- activity の時刻は、作者が書き換えられる commit の日時（author date・committer date）とは別に、GitHub が記録した時刻で、作者からは偽れない。ただし push の権限を持つ人（乗っ取られた maintainer を含む）が何を push するかは防げない。7 日ルールは、周りが気付いて報じるまでの時間を稼ぐだけ
- activity API の公式の doc に、記録をいつまで残すかは書かれていない。168 時間以前の activity が 1 件も取れないときは公開時刻不明として扱う
- 別の branch や fork で先に公開された commit も、lock の branch に届いた時刻から数える（遅い側に倒れる）
- tag は、tag を打った時刻ではなく、その commit がどれかの branch に届いた時刻で数える（`refs/tags/...` を指定しても activity は返らなかった）。release の成果物を使うプラグインだけ release の時刻も見る
- commit の日時は表の参考にだけ使い、判定には使わない

## Execution Process

手順 1・2 のコマンドは `${CLAUDE_SKILL_DIR}/references/plugin-checks.md`、Mason の入れ替えは `${CLAUDE_SKILL_DIR}/references/mason.md` にある。jq と gh の長いパイプラインは `${CLAUDE_SKILL_DIR}/scripts/` の script にしてあり、cwd に関わらず `bash "${SKILL_DIR:?}/scripts/<名前>.sh"` で呼ぶ。`SKILL_DIR` は `${CLAUDE_SKILL_DIR}`（references の中では展開されないので、ここに書かれた値を使う）。

シェルの変数は Bash の呼び出しをまたいで残らない。コードブロックは、使う変数（`SKILL_DIR`・`LAZY`・`cutoff`・`LOCK`・`br`・`WT`、プラグインごとの `n`・`d`・`repo`・`b`・`base`・`t7`・`cand`・`sha`・`from`・`to`、Mason のツールごとの `m`・`pkg`・`cur`・`cand`・`W`）をそのブロックの先頭で定義し直してから実行する。`cutoff` は最初に出した値をそのまま書き込み、呼び出しのたびに計算し直さない。`br`・`WT` は手順 4 で `$TMPDIR/nvim-update-state.sh` に書き、使うブロックの先頭で `. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"` と読み込む（`br` は時刻から作るので計算し直すと別の名前になり、`WT` が空だと `git -C ""` が cwd の repo に向く）。

dotfiles への `git` は 2 か所に向く。本体（`~/dotfiles`。restore が読み書きする lock は `~/.config/nvim` の symlink を通してここにある）は `git -C ~/dotfiles`、手順 4 で作る worktree は `git -C "$WT"` と書いている。本体では fetch・status・pull・`worktree add` など読み取りと main の更新だけを行い、ブランチの切り替えと commit は worktree で行う。始める前に次で cwd を確かめ、`DOTFILES` なら `git -C ~/dotfiles` の `-C ~/dotfiles` を外す（cwd と同じ repo に `-C` を付けない、グローバルの CLAUDE.md の決まり）。プラグインのディレクトリへの `git -C "$d"` はそのまま使う。

```bash
[ "$(pwd -P)" = "$(cd ~/dotfiles && pwd -P)" ] && echo DOTFILES || echo OTHER
```

### 手順 1: 候補の収集（読み取りのみ）

コマンドと見方は `references/plugin-checks.md` の「手順 1」を Read してから回す。流れは次のとおり。

1. 基準時刻と、その 168 時間前（`cutoff`）を取る
2. 本体（`~/dotfiles`）を main のまま pull し、`status` を見て、origin/main の lock を基準（`$TMPDIR/nvim-lock-base.json`）として書き出す
3. 全プラグインが入っているか（`MISSING`）を確かめてから、spec の `version`・`build` などを `$TMPDIR/nvim-specs.tsv` に書き出す
4. `scripts/collect-candidates.sh` で、プラグインごとに fetch し、168 時間前の branch の先頭を activity API で取る
5. branch を追うものは 168 時間前の先頭を、tag を追うものはリリース用の branch も見て 168 時間前の時点の最新の安定版の tag を `cand` にし、「候補なし」「候補あり」「基準が 168 時間未満」「別の系統」に分ける。印 `ずれ` と公開時刻不明もここで付ける
6. 表に書く経過時間のために、候補（と印 `基準が 168 時間未満` の基準）が branch に届いた時刻を `scripts/arrival-time.sh` で取る

### 手順 2: 侵害の事前確認（候補ごと）

確かめる範囲を `$from..$to` で書く。行ごとに次で決める（1 行に範囲が 2 つあれば両方にかける）。

| 行 | `from` | `to` |
|---|---|---|
| 候補あり | `base` | `cand` |
| 印 `ずれ` | `base` | HEAD |
| 印 `基準が 168 時間未満` | `cand` | `base` |

印 `基準が 168 時間未満` の行も、2-1〜2-4 をすべてかける。この範囲は 7 日ルールを通らずに今の lock に入っている commit なので、上げる候補と同じだけ確かめないと、残すか戻すかを決められない。

候補が 5 件を超えたら、5〜8 件ずつサブエージェント（Agent）へ分けて並列に回す。各エージェントには、プラグインのディレクトリ、repo、範囲（`from..to`）、下の 2-1〜2-4、結果の書式（表の 1 行）を渡す。

- 持ち主が、この範囲（`cand..base`）のプラグインの差分と作者は別の確認（前の回のこのスキルの手順 2 など）で読んだと言ったときは、2-2 と 2-3 を省いてよい。lock の sha の変更だけを見た PR のレビューは、プラグインの差分を読んだことにならないので当たらない。そのときも 2-1 と 2-4 は行う。force push・移管と advisory・報道は、差分を読んだあとにも起きるので、読んだ時点の確認では足りない
- 省いたときは、表の差分の危険箇所と作者・merge の列に「持ち主が確認済み（<いつ、何で>）」と書く

2-1〜2-5 のコマンドと見方は `references/plugin-checks.md` の「手順 2」を Read する。サブエージェントにはこのファイルのパスと、2-1〜2-4 の節だけを読めばよいことを渡す（2-5 は全体で 1 回だけ回す）。

- 2-1. repo の状態と上流: archived、移管・改名、force push、origin が spec の URL と同じか
- 2-2. 差分の危険箇所: build のフック、LazyVim が新しく使うプラグイン（印 `新規プラグイン`）、外部の実行と動的なコードの読み込み、ダウンロード、難読化、バイナリ
- 2-3. 作者と merge した人: 初めての作者の commit を読み、merge した人が maintainer かを見る。印 `直接 push`
- 2-4. advisory と報道: repo の advisory と WebSearch
- 2-5. Mason のツール（ここでは入れ替えない）: purl を OSV に、ツールのディレクトリを `trivy rootfs` にかける

#### 判定

| 判定 | 条件 |
|---|---|
| 更新可 | 168 時間以上、上流の branch に載っている、archived・移管なし、advisory・報道なし、危険箇所に異常なし、初めての作者の commit を読んで説明がつく |
| 見送り | 168 時間未満、公開時刻不明、advisory・侵害報道がある、危険箇所に説明のつかない変更がある、origin が spec の URL と違う |
| 要判断 | 修正版の例外、`移管`、`force push`、`直接 push`、`メジャー跨ぎ`、`新規プラグイン`、`基準が 168 時間未満`、`ずれ` |

LazyVim が「見送り」なら、それが連れてくる `新規プラグイン` も見送る。逆に `新規プラグイン` を承認しないなら LazyVim も上げない（上げると起動時に branch の先頭で入る）。

### 手順 3: 表を示して承認を得る

基準時刻と 168 時間前の時刻を表の上に書き、次の列で表を出す。

| プラグイン | 基準 → 候補 | 経過時間 | commit 数 | 差分の危険箇所 | 作者・merge | advisory・報道 | 印 | 判定 |
|---|---|---|---|---|---|---|---|---|

- 基準 → 候補は短い sha（tag を追うものは tag 名も）。経過時間は候補が branch に届いた時刻（手順 1）から `190 時間（7.9 日）` のように書く。印 `基準が 168 時間未満` の行は、基準が届いた時刻（手順 1 の `arrival-time.sh` に基準の sha を渡して）からの時間も書く。時間は `bash "${SKILL_DIR:?}/scripts/hours-since.sh" '<timestamp>'` で出す
- 印 `ずれ` の行は HEAD も書き、HEAD が候補の先にあるなら「HEAD は 168 時間未満、候補まで戻す」と書く
- 候補なしのプラグインは載せない。見送りは理由を判定の列に書く
- 表の下に Mason の結果（`MAL` と脆弱性のあるものだけ）を書く。入れ替えはこの承認に含めず、「Mason のツールの入れ替え」で別に聞く
- 表のあとに AskUserQuestion で承認を取る。最初の質問の選択肢は「更新可だけ実行」「更新可と要判断を選んで実行」「やめる」
- 「要判断を選んで実行」なら、要判断の項目を multiSelect で選ばせる。選択肢が 1 つだけの問いを作らないよう、AskUserQuestion の上限（1 問に選択肢 2〜4 個、1 回に 4 問）の中で項目を問いに均等に分け、4 問を超える分は次の呼び出しで聞く（全体で 1 件なら、変えるか既定のままかの 2 択にする）
  - 選択肢の label には、選んだときに起きることを書く（`blink.cmp: 上げる`、`LazyVim: cand に戻す` など）。選ばなかった項目が既定（上げない、基準を残す）になる向きにそろえる
- 印 `ずれ` で承認しなかったものは基準の commit に戻ること、印 `基準が 168 時間未満` で戻すと選んだものは `cand` に戻ることを、承認の前に書いておく

### 手順 4: dotfiles の worktree を用意する

```bash
br=chore/nvim-lazy-lock-$(date +%Y%m%d-%H%M)
WT=~/.herdr/worktrees/dotfiles/${br//\//-}
printf 'br=%q\nWT=%q\n' "$br" "$WT" > "$TMPDIR/nvim-update-state.sh"
git -C ~/dotfiles worktree add -b "$br" "$WT" origin/main
```

- origin/main は手順 1 で pull 済み。worktree の lock は基準（`nvim-lock-base.json`）と同じになる
- 本体は main のまま、lock も触らない。merge までは、本体の lock とプラグインの HEAD が今のまま（`ずれ` があればそのまま）なので、nvim はそのまま使える
- ブランチ名は日付と時刻で分ける。同じ名前のブランチや worktree があって `worktree add` が止まったら、前の PR が残っていないか `gh pr list -R capytan/dotfiles --head "$br" --state all` で見て報告する

### 手順 5: worktree の lock を書き換えて検証する（restore はしない）

1. 基準の lock に承認した変更をかけ、lazy.nvim の書式（前提の表）で worktree の lock に書く。`c` は、承認したプラグインの候補の sha と、戻すと選んだ `基準が 168 時間未満` の `cand` の sha（どちらも 40 桁）。承認しなかった `ずれ` の行は入れない（基準のまま）。`new` は承認した `新規プラグイン`（名前は repo 名。spec に `name =` があればそれ。branch は既定の branch）。名前の順に並べ直すので、書式は lazy.nvim が書き直すものと同じになる

```bash
. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"
LOCK="$WT/configs/nvim/lazy-lock.json"
bash "${SKILL_DIR:?}/scripts/write-lock.sh" "$TMPDIR/nvim-lock-base.json" \
  '{"<名前>": "<sha>", ...}' '{"<名前>": {"branch": "<branch>", "commit": "<sha>"}, ...}' > "$LOCK"
```

2. lock を検証する。key が基準と同じ（足した `新規プラグイン` を除く）で、変わったのが承認したものだけであることを見る

```bash
jq -e 'type == "object" and length > 0' "$LOCK" >/dev/null && echo valid
diff <(jq -S . "$TMPDIR/nvim-lock-base.json") <(jq -S . "$LOCK")
```

3. merge のあとの restore で動くプラグインを、今の HEAD と lock から出す。restore は lock の commit に checkout するので、HEAD と lock の commit が違うプラグインだけが動く

```bash
. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"
bash "${SKILL_DIR:?}/scripts/lock-moves.sh" "$WT/configs/nvim/lazy-lock.json"
```

- `MOVE` の行が、承認したプラグイン、承認しなかった `ずれ`（HEAD → 基準）、戻すと選んだ `基準が 168 時間未満` と過不足なく一致すること
- `NEW` の行は、承認した `新規プラグイン` だけであること（入っていないので、起動時のインストールが lock の commit で入れる）
- `NOT-ON-BRANCH` は、sha の書き間違いか、手順 1 のあとの force push。手順 6 に進まずに報告する
- 一致しなければ手順 6 に進まずに報告する。この一覧が、手順 7 の HEAD の一致を見るときの予定になる

### 手順 6: worktree で commit、push、PR

1. `git -C "$WT" status --short` が `configs/nvim/lazy-lock.json` だけであることを確かめ、それだけを stage して commit する

```bash
. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"
git -C "$WT" add configs/nvim/lazy-lock.json
git -C "$WT" commit -m "chore(nvim): lazy-lock.json を更新する"
git -C "$WT" push -u origin HEAD
```

2. PR 本文は PR テンプレートの見出しに従い、表の全文は貼らず、要点だけを書く

- Summary: 基準時刻、上げたプラグインの数、7 日ルールと侵害の確認を通したこと
- Test plan: 手順 5 の検証と、`MOVE`・`NEW` の一覧（restore と HEAD の一致は merge のあとに手順 7 で行う）
- Review focus: 要判断で決めたもの、見送ったものと理由、Mason の `MAL` の有無
- Merge and release notes: merge のあとに手順 7（本体の pull、restore、HEAD の一致の確認、worktree の片付け）を回すこと

```bash
gh pr create -R capytan/dotfiles --base main --head "$br" --title "chore(nvim): lazy-lock.json を更新する" --body-file "$TMPDIR/nvim-pr-body.md"
```

3. 報告する。上げるもの、見送ったものとその理由を表で書き、commit と PR を完全な URL で付ける。プラグインはまだ入れ替わっていないこと、merge のあとに手順 7 を回すことも伝える。`br`・`WT` と手順 5-3 の一覧も書いておく（手順 7 で使う）

### 手順 7: merge のあとに restore する

持ち主が PR を merge したと伝えたら回す。`$TMPDIR/nvim-update-state.sh` が無い（別の会話や再起動のあと）ときは、報告に書いた `br`・`WT` で書き直す。手順 5-3 の一覧も報告から使う。

先に、PR が merge されたことと本体の状態だけを見る。`MERGED` でないとき、本体が main でないときは、ここで止めて報告する（下に進むと本体の lock を捨てる）。

```bash
. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"
gh pr view "$br" -R capytan/dotfiles --json state,headRefOid --jq '"\(.state) \(.headRefOid)"'
git -C ~/dotfiles status --short --branch
```

両方を満たしたら、本体を main の先頭にそろえる。

```bash
git -C ~/dotfiles restore configs/nvim/lazy-lock.json
git -C ~/dotfiles pull --ff-only
git -C ~/dotfiles diff --quiet <headRefOid> HEAD -- configs/nvim/lazy-lock.json && echo SAME-AS-PR
```

- `restore` するのは、本体の lock に lazy.nvim が HEAD から書いた変更（`ずれ`）があると `pull --ff-only` が「would be overwritten」で止まるため。捨てるのは lock だけで、HEAD の状態はプラグインのディレクトリに残っている
- `SAME-AS-PR` が出なければ（merge のあとに main の lock がまた変わった）、restore せずに報告する

守ることの nvim の起動の前の確認（手順 1 の `MISSING` と spec の確認を、pull したあとの本体の lock でやり直す）を行ってから、名前を付けずに全体を restore する。ずれのないプラグインは checkout されず、fetch だけが走る。restore は入っていないプラグインを入れないが、起動時のインストールが lock の commit で入れる（`新規プラグイン` は restore のための起動で入る）。

- `MISSING` には手順 5-3 の `NEW` が出る（lock の commit で入る）。`NEW` に無いものが出たら止める

```bash
nvim --headless "+Lazy! restore" +qa > "$TMPDIR/nvim-restore.log" 2>&1; echo "exit=$?"
sed 's/\x1b\[[0-9;]*m//g' "$TMPDIR/nvim-restore.log" | grep -E 'HEAD is now|build|[Ee]rror|[Ff]ailed'
```

全プラグインの HEAD が lock と一致するか、restore が lock を書き直したあとも本体に差分が無いかを確かめる。

```bash
LAZY=~/.local/share/nvim/lazy
LOCK=~/dotfiles/configs/nvim/lazy-lock.json
jq -r 'to_entries[] | "\(.key) \(.value.commit)"' "$LOCK" | while read -r n c; do
  [ "$(git -C "$LAZY/$n" rev-parse HEAD)" = "$c" ] || echo "MISMATCH $n"
done
git -C ~/dotfiles status --short
```

- `HEAD is now` の出たプラグインが、手順 5-3 の `MOVE`・`NEW` と同じであること
- `MISMATCH` が出たとき、`status` に差分が出たとき（書式の違いか、lock に無いプラグインが起動で入った）は、片付けに進まずに報告する。直すときは、本体ではなく新しい worktree で PR を作る

片付ける。merge commit を pull してあるので `branch -d` で消せる。

```bash
. "$TMPDIR/nvim-update-state.sh"; : "${WT:?}"
git -C ~/dotfiles worktree remove "$WT"
git -C ~/dotfiles branch -d "$br"
```

報告する。入れ替えたもの、build が走ったプラグイン、失敗したものを表で書き、PR を完全な URL で付ける。

### Mason のツールの入れ替え（承認されたときだけ）

手順 2-5 で `MAL` や脆弱性が出たツールを、確かめた版に入れ替える（または消す）。lock の流れ（手順 3〜7）とは表と承認を分け、承認されたものだけを入れ替える。lock の流れを回さずにこの節だけを頼まれたときも、手順 1 の `cutoff` と手順 2-5 を先に行う。

始めるときに `references/mason.md` を Read し、M-1〜M-5（候補の版、確認、表と承認、実行、入れ替え後の確認）とそのエラー処理に従う。対象は purl が `pkg:npm/` のツールだけ。

## エラー処理

| 状況 | 対応 |
|---|---|
| `gh api` が rate limit や認証エラー | `gh auth status` と `gh api rate_limit --jq .resources.core` を確かめるよう伝えて止める。公開時刻が取れないまま判定しない |
| activity が取れない（404、GitHub 以外の host） | その候補は「見送り（公開時刻不明）」 |
| `git fetch` の失敗 | そのプラグインは「見送り（fetch 失敗）」としてエラーを原文で書く。ほかは続ける |
| `MISSING` が出た、spec に lock に無いプラグインがある | nvim を起動せずに止めて報告する。入れるかどうかは持ち主に聞く |
| 本体が main でない（`NOT-MAIN`） | ブランチを切り替えずに止めて報告する |
| `worktree add` が「already exists」で止まる | 同じ名前のブランチ・worktree と PR の状態を見て報告する。ブランチと worktree は消さない |
| lock の検証（`jq -e`、手順 5-3 の一覧）が通らない | commit しない。手順 5-1 の `c`・`new` を直して書き直す |
| restore の失敗（exit が 0 でない、ログに error） | ログを原文で伝えて止める。本体で commit しない。原因を直してから、もう一度 `nvim --headless "+Lazy! restore" +qa`。前の版に戻すなら、戻す PR を手順 4〜6 で作り、merge のあとに手順 7 を回す |
| restore のあと HEAD が lock とずれる | どのプラグインかと両方の sha を伝えて止める。本体で commit しない |
| `pull --ff-only` が止まる | 本体の変更を `git -C ~/dotfiles status` で見て報告する。lock 以外の変更は捨てない |

---
name: update-nvim-plugins
description: LazyVim（lazy.nvim）のプラグインを、サプライチェーン侵害の事前確認（GitHub への push から 7 日の見送り、差分の危険箇所、作者と merge した人、advisory と報道）を挟んでから更新する。候補を表にして承認を得てから lazy-lock.json を書き換えて restore し、dotfiles に PR を出す。「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」等で発動する。uv・mise・Homebrew のツールには使わない（`update-local-tools` を使う）。
allowed-tools: Bash, Read, Edit, WebSearch, WebFetch, AskUserQuestion, Agent
---

# Update Nvim Plugins — 侵害確認つきで LazyVim のプラグインを更新する

## このスキルの目的

`configs/nvim/lazy-lock.json` で固定しているプラグインを上げる前に、次を候補ごとに確かめる。

- 上流の branch に push されてから 168 時間未満の commit を避ける（以下「7 日ルール」）
- 差分の危険箇所（build のフック、外部の実行、ダウンロード、難読化、バイナリ）を見る
- 初めての作者の commit と、それを merge した人を見る
- repo が archived や移管されていないか、候補が上流の正規の branch に載っているかを見る
- advisory と報道を調べる。Mason で入れたツールは OSV で `MAL-` を見る

結果を表で示し、承認を得たものだけ lock を書き換えて入れ替える。lock の変更は dotfiles のブランチに commit し、PR にする。

## 守ること

- 手順 1〜4 は読み取りだけ。承認の前にプラグインを入れ替えない。`:Lazy update`・`:Lazy sync`・`:Lazy` の画面の `U`・`S` を使わない（branch の先頭や最新の tag まで、確かめずに進む）
- 入れ替えは、lock を書き換えてから `Lazy! restore` で行う。restore は lock の commit にだけ checkout する
- 承認の範囲を広げない。承認後に候補が変わった（手順 1 をやり直した等）ら表を作り直す
- main に直接 commit しない。ブランチを切って lock だけを commit し、PR にする。merge はしない
- Mason のツールは確かめるだけで、入れ替えない

## When to Use This Skill

発動する依頼:
- 「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」
- 「`:Lazy` で更新が出ている」「プラグインを最新に」

使わないケース:
- uv・mise・Homebrew のツール → `update-local-tools`
- プロジェクトの依存（package.json、pyproject.toml など）→ このスキルの対象外
- 特定のプラグインだけを頼まれた場合も手順は同じ。対象をそのプラグインに絞って回す

## 前提（この環境の事実）

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| 設定の場所 | `~/.config/nvim` は `~/dotfiles/configs/nvim` への symlink。lockfile は `~/.config/nvim/lazy-lock.json`（lazy.nvim の既定） | lock を書き換えると dotfiles の作業ツリーが変わる |
| プラグインの場所 | `~/.local/share/nvim/lazy/<名前>`。lock の key がディレクトリ名 | `git fetch` と差分の確認はこのディレクトリで行う |
| checker | `checker = { enabled = true, notify = false }`。lazy.nvim の checker は fetch して更新の有無を数えるだけで、入れ替えない | 「更新あり」の表示が出ても、それ自体は危険ではない |
| `version` の指定 | `defaults.version = false` なので、多くは branch の先頭を追う。spec に `version = "*"` などがあるもの（例 LazyVim・lazy.nvim・blink.cmp）は最新の semver の tag を追う | 手順 1 で spec を読み、tag を追うものは tag を候補にする |
| restore の中身 | `restore` は `update` に `lockfile = true` を付けたもの（`lua/lazy/manage/init.lua`）。fetch のあと lock の commit に checkout し、commit が変わったプラグインだけ build を走らせ、最後に lockfile を全プラグインの今の HEAD から書き直す | 名前を付けて restore しても、ほかのプラグインの HEAD が lock とずれていれば、そのずれが lock に書き込まれる。だから名前を付けずに全体を restore する |
| 壊れた lock | lock が空や不正な JSON だと、lazy.nvim はエラーにせず lock 無しとして扱い、restore が branch の先頭まで進む（`lua/lazy/manage/lock.lua` の `pcall(vim.json.decode, ...)`） | restore の前に `jq` で lock を検証する |
| build のフック | 入れ替えたときに走る。spec の `build`（`nvim-specs.tsv` の `build=` 列。例 `nvim-treesitter` の parser のビルド、`markdown-preview.nvim` のビルド済みバイナリの取得）と、プラグインの `build.lua`・`build/init.lua` | build があるプラグインと、spec を書いている LazyVim は、build まわりの差分を必ず読む |
| 実行時のダウンロード | GitHub Release の成果物を実行時に落とすプラグインがある（例 blink.cmp は tag の release から fuzzy のバイナリを落とし、同じ release の `.sha256` と照合する。attestation は無い） | release の成果物を使うプラグインは、release の公開時刻も 7 日ルールにかける |
| Mason | `~/.local/share/nvim/mason/packages/<名前>/mason-receipt.json` の `source.id` が purl（`pkg:npm/...@版`） | purl を OSV の querybatch に渡す。OSV に無い種類（github・generic）は空の結果が返る |
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

シェルの変数は Bash の呼び出しをまたいで残らない。下のコードブロックは、使う変数（`LAZY`・`cutoff`・`LOCK`、プラグインごとの `n`・`d`・`repo`・`b`・`base`・`t7`・`cand`・`sha`・`from`・`to`）をそのブロックの先頭で定義し直してから実行する。`cutoff` は最初に出した値をそのまま書き込み、呼び出しのたびに計算し直さない。

dotfiles への `git` は、`~/dotfiles` を cwd にして `-C` を付けずに書いている（グローバルの CLAUDE.md の決まり）。lock は `~/.config/nvim` の symlink を通して必ず `~/dotfiles` の本体に書かれるので、始める前に次で cwd を確かめ、`OTHER` なら（別の repo、dotfiles の worktree など）以降の dotfiles への `git` をすべて `git -C ~/dotfiles` に読み替える。プラグインのディレクトリへの `git -C "$d"` はそのまま使う。

```bash
[ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(cd ~/dotfiles && pwd -P)" ] && echo DOTFILES || echo OTHER
```

### 手順 1: 候補の収集（読み取りのみ）

基準時刻と、その 168 時間前を取る。

```bash
jq -rn 'now | todate'                    # 基準時刻（表に書く）
jq -rn 'now - 168*3600 | todate'         # 168 時間前。以降のブロックで cutoff='<この値>' として使う
```

dotfiles の状態と、基準にする lock（origin/main のもの）を取る。

```bash
git fetch --quiet origin
git status --short --branch
git show origin/main:configs/nvim/lazy-lock.json > "$TMPDIR/nvim-lock-base.json"
```

- `configs/nvim/lazy-lock.json` 以外に変更があれば、手順 6 でブランチを切れないので、止めて報告する。`configs/nvim/lua` や `lazyvim.json` の変更は、lock に無いプラグインが spec に増えている恐れもある
- lock の作業ツリーが origin/main と違うのは、誰かが `:Lazy update` などで入れ替えた跡のことが多い。下の「ずれ」で拾う

全プラグインが入っているかを確かめてから、spec の `version`・`build` などを読む。`MISSING` が出たら、nvim を起動すると lock の commit で clone されるので、起動する前に持ち主に伝えて止める。

```bash
LAZY=~/.local/share/nvim/lazy
jq -r 'keys[]' "$TMPDIR/nvim-lock-base.json" | while read -r n; do [ -d "$LAZY/$n/.git" ] || echo "MISSING $n"; done
nvim --headless +'lua local C=require("lazy.core.config"); for n,p in pairs(C.plugins) do local v=p.version; if v==nil and p.branch==nil then v=C.options.defaults.version end; io.stdout:write(("%s\t%s\tversion=%s tag=%s commit=%s pin=%s build=%s\n"):format(n, p.url or "local", tostring(v), tostring(p.tag), tostring(p.commit), tostring(p.pin), type(p.build)=="function" and "function" or tostring(p.build))) end' +qa > "$TMPDIR/nvim-specs.tsv"
```

- `version` が `*` などの文字列なら tag を追う。`tag`・`commit`・`pin` があるものは lazy.nvim が update で動かさないので、対象から外して表に参考で書く
- `nvim-specs.tsv` にあって lock に無いプラグインがあれば止めて報告する（起動で branch の先頭が入った恐れがある）

プラグインごとに fetch し、168 時間前の branch の先頭を activity API で取る。activity は新しい順に返る（`direction` の既定が `desc`）ので、`timestamp` が `cutoff` 以前の最初の 1 件が 168 時間前の先頭になる。`gh api --paginate` はページごとに出力するので、`head -1` が閉じると次の書き込みで止まり、残りのページは取らない（全ページを取るのは、当たる行が無いときだけ）。

```bash
jq -r 'to_entries[] | "\(.key)\t\(.value.branch)\t\(.value.commit)"' "$TMPDIR/nvim-lock-base.json" |
while IFS=$'\t' read -r n b base; do
  d="$LAZY/$n"
  git -C "$d" fetch --quiet --tags origin </dev/null || { printf '%s\tFETCH-FAILED\n' "$n"; continue; }
  repo=$(git -C "$d" remote get-url origin | sed -E 's#^https://github.com/##; s#\.git$##')
  t7=$(gh api "repos/$repo/activity?ref=refs/heads/$b&per_page=100" --paginate \
    --jq ".[] | select(.activity_type != \"branch_deletion\" and .timestamp <= \"$cutoff\") | \"\(.after) \(.timestamp) \(.activity_type)\"" </dev/null | head -1)
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$repo" "$b" "$base" "$(git -C "$d" rev-parse HEAD)" "$t7"
done > "$TMPDIR/nvim-candidates.tsv"
```

各行（名前、repo、branch、基準、HEAD、168 時間前の先頭とその時刻）から候補 `cand` を決める。`d`・`b`・`base`・`t7`（先頭の sha）はその行の値。

- `nvim-specs.tsv` の `version=` が `false` か `nil` なら branch を追う。`cand=$t7`
- それ以外（`*` など）は tag を追う。`t7` の行はそのまま使わず、下で出た tag の commit を `cand`、その branch を `b` にする。branch の先頭で候補を判定しない（tag を打つ前の commit まで候補になる）

```bash
for rb in $(git -C "$d" branch -r --format='%(refname:lstrip=3)' | grep -xE "$b|v?[0-9]+(\.([0-9]+|x))*|stable|release/.*"); do
  tip=$(gh api "repos/$repo/activity?ref=refs/heads/$rb&per_page=100" --paginate \
    --jq ".[] | select(.activity_type != \"branch_deletion\" and .timestamp <= \"$cutoff\") | .after" </dev/null | head -1)
  [ -n "$tip" ] || continue
  tag=$(git -C "$d" tag --merged "$tip" --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
  [ -n "$tag" ] && echo "$tag $(git -C "$d" rev-parse "$tag^{commit}") $rb"
done | sort -rV | head -1   # tag、cand、b の順
```

- tag を見る branch は、lock の branch と、リリース用の branch（`v1`・`v14`・`1.x` のような版の名前、`stable`、`release/...`。blink.cmp は `v1` に tag を打つ）に絞る。bot の一時の branch（`create-pull-request/patch`、`release-please--*` など）や PR の branch は、短命で 7 日ルールの判定に向かないので見ない
- branch ごとに 168 時間前の先頭が含む最新の tag を出し、その中で版が最も新しいものを取る。基準を含まない tag も出るので、基準が新しすぎるときも 168 時間前の時点の tag がわかる
- `cand` と `b` が決まったら、branch を追うものと同じく次で判定する

```bash
git -C "$d" merge-base --is-ancestor "$cand" "origin/$b" || echo "上流の branch に載っていない（force push）"
if [ "$base" = "$cand" ]; then echo "候補なし"
elif git -C "$d" merge-base --is-ancestor "$base" "$cand"; then echo "候補あり"
elif git -C "$d" merge-base --is-ancestor "$cand" "$base"; then echo "基準が 168 時間未満"
else echo "別の系統（止めて報告）"; fi
git -C "$d" log --format='%h %cI %an <%ae> | %s' "$base..$cand"       # 上げる範囲
git -C "$d" log --format='%h %cI %an | %s' "$cand..origin/$b" | head  # 168 時間未満で見送る範囲（参考）
```

- release の成果物を実行時に落とすプラグイン（例 blink.cmp）は `gh api "repos/$repo/releases/tags/<tag>" --jq .published_at` も 168 時間以上前か見る。足りなければ一つ前の tag に下げる
- HEAD が基準と違うプラグインには印 `ずれ` を付け、HEAD も表に書く。HEAD の commit も上げる範囲と同じく手順 2 で確かめる（`base..HEAD`）
- `t7` が空（168 時間前以前の activity が取れない）、tag を追うもので tag が 1 つも出ないなら「公開時刻不明」。基準と branch の先頭が同じなら「候補なし」、違えば「見送り（公開時刻不明）」
- `基準が 168 時間未満` が出たら印を付ける。手順 2 の範囲は手順 2 の冒頭のとおり
- `別の系統`（メジャーの branch が分かれたときなど）は止めて報告する

経過時間の列と印 `基準が 168 時間未満` の行には、その commit が branch に届いた時刻が要る。branch を追うものの `cand` は `t7` の行に時刻がある。tag を追うものの `cand` と基準は、`sha` に入れて次で取る。新しい activity から順に、`after` が `sha` を含むあいだ時刻を出し、含まなくなったところで止めて、最後に出た時刻（最も古い、届いた時刻）を使う。まとめて push された中ほどの commit も、そのまとめの activity の時刻になる。

```bash
gh api "repos/$repo/activity?ref=refs/heads/$b&per_page=100" --paginate \
  --jq '.[] | select(.activity_type != "branch_deletion") | "\(.after) \(.timestamp)"' </dev/null |
while read -r a ts; do git -C "$d" merge-base --is-ancestor "$sha" "$a" 2>/dev/null || break; echo "$ts"; done | tail -1
```

- `while` が止まると `gh` も止まるので、必要なページだけを取る
- force push で一度消えて戻った commit や、ローカルに無い `after`（force push で消えた commit）に当たると、そこで止まって新しい側の時刻になる（遅い側に倒れる）。空なら「届いた時刻不明」と書く

### 手順 2: 侵害の事前確認（候補ごと）

下のコマンドは、確かめる範囲を `$from..$to` で書いている。行ごとに次で決める（1 行に範囲が 2 つあれば両方にかける）。

| 行 | `from` | `to` |
|---|---|---|
| 候補あり | `base` | `cand` |
| 印 `ずれ` | `base` | HEAD |
| 印 `基準が 168 時間未満` | `cand` | `base` |

印 `基準が 168 時間未満` の行も、2-1〜2-4 をすべてかける。この範囲は 7 日ルールを通らずに今の lock に入っている commit なので、上げる候補と同じだけ確かめないと、残すか戻すかを決められない。

候補が 5 件を超えたら、5〜8 件ずつサブエージェント（Agent）へ分けて並列に回す。各エージェントには、プラグインのディレクトリ、repo、範囲（`from..to`）、下の 2-1〜2-4、結果の書式（表の 1 行）を渡す。

- 持ち主が、この範囲（`cand..base`）のプラグインの差分と作者は別の確認（前の回のこのスキルの手順 2 など）で読んだと言ったときは、2-2 と 2-3 を省いてよい。lock の sha の変更だけを見た PR のレビューは、プラグインの差分を読んだことにならないので当たらない。そのときも 2-1 と 2-4 は行う。force push・移管と advisory・報道は、差分を読んだあとにも起きるので、読んだ時点の確認では足りない
- 省いたときは、表の差分の危険箇所と作者・merge の列に「持ち主が確認済み（<いつ、何で>）」と書く

#### 2-1. repo の状態と上流

```bash
gh api "repos/$repo" --jq '"\(.full_name) archived=\(.archived)"'
gh api "repos/$repo/activity?ref=refs/heads/$b&activity_type=force_push&per_page=100" --paginate --jq '.[] | "\(.timestamp) \(.actor.login) \(.before[0:8])..\(.after[0:8])"'
```

- `full_name` が spec の URL（`$TMPDIR/nvim-specs.tsv`）と違えば、移管か改名。印 `移管` を付けて要判断
- archived なら印 `archived`。上げる commit が無いはずなので、あれば見送り
- 範囲の期間に force push があれば印 `force push` を付けて要判断。範囲の期間は、`from` の commit の committer date より後を目安にする（日時が偽られていても、拾う範囲が広がるだけ）
- `git -C "$d" remote get-url origin` が spec の URL と違えば見送り（入っているものが spec の repo ではない）

#### 2-2. 差分の危険箇所

差分は fetch 済みのローカルで取り、ファイルに一度だけ書き出して読む。

```bash
git -C "$d" diff --numstat "$from..$to" | awk '$1 == "-" { print "binary:", $3 } END { print NR, "files" }'
git -C "$d" diff --name-only "$from..$to" | grep -E '(^|/)(build\.lua|build/|Makefile|[^/]*\.rockspec|install[^/]*|package\.json|Cargo\.toml)|\.(sh|ps1|py|js|ts)$'
git -C "$d" diff "$from..$to" > "$TMPDIR/nvim-diff-$n.patch"
grep -nE '^\+.*(os\.execute|io\.popen|vim\.system|vim\.fn\.system|jobstart|termopen|uv\.spawn|loop\.spawn|loadstring|[^.a-z_]load\(|dofile|curl|wget|https?://|base64|(\\x[0-9a-fA-F]{2}){8})' "$TMPDIR/nvim-diff-$n.patch"
grep -E '^\+' "$TMPDIR/nvim-diff-$n.patch" | awk 'length > 400 { print substr($0, 1, 200) "..." }'
```

見る箇所:
- build のフック: プラグインの `build.lua`・`build/init.lua`・`Makefile`・rockspec・install 系のスクリプト。LazyVim は spec の `build =` の行と、`ensure_installed`（Mason で次の起動時に入るツールが増える）
- LazyVim が新しく使うプラグイン: 下のコマンドで増えた `"owner/repo"` を拾う。lock に無いものは、起動時に branch の先頭で入ってしまうので、印 `新規プラグイン` を付けて候補に足す。基準は無いので、手順 1 と同じく 168 時間前の先頭を候補にし、2-1〜2-4 を repo 全体（差分ではなく、候補の commit の中身と作者の顔ぶれ）にかける

```bash
git -C "$LAZY/LazyVim" diff "$from..$to" -- lua/lazyvim/plugins | grep -oE '^\+.*"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' | grep -oE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' | sort -u
```
- 外部の実行と動的なコードの読み込み: `os.execute`、`io.popen`、`vim.system`、`vim.fn.system`、`jobstart`、`termopen`、`uv.spawn`、`load`/`loadstring`、`dofile`
- ダウンロード: `curl`・`wget`・新しい URL
- 難読化: 長い base64、`\x` の羅列、極端に長い 1 行
- バイナリの追加

grep に当たった行は、前後を `git -C "$d" diff "$from..$to" -- <file>` で読み、目的の説明がつくか（commit message、PR、既存のコードの延長か）を判断する。説明のつかないものは見送り。差分が大きい（300 ファイル超）ときは上の箇所だけを読み、表に「危険箇所のみ確認」と書く。

#### 2-3. 作者と merge した人

作者はローカルの履歴で見る（compare API は 250 commit までしか返さない）。`from` より前の履歴に email が一度も無い作者を「初めての作者」とする。commit の日時は使わない。

```bash
git -C "$d" log --format='%ae' "$from" | sort -u > "$TMPDIR/nvim-known-$n.txt"
git -C "$d" log --format='%h %ae %an | %ce | %s' "$from..$to" |
  awk 'NR == FNR { known[$1]; next } !($2 in known) { print "初めて:", $0 }' "$TMPDIR/nvim-known-$n.txt" -
gh api "repos/$repo/commits/<sha>/pulls" --jq '.[] | "#\(.number) \(.user.login)"'
gh pr view <number> -R "$repo" --json author,mergedBy,mergedAt --jq '"\(.author.login) merged_by=\(.mergedBy.login) \(.mergedAt)"'
```

- 初めての作者の commit は、上の 2-2 に当たらなくても差分を読む。その commit の PR を引き、merge した人が maintainer（これまで merge してきた人）かを見る
- maintainer 以外が直接 push した commit（PR が無く、committer が見慣れない人）は印 `直接 push` を付けて要判断
- `github-actions[bot]` の docs 生成（`chore(build): auto-generated vimdocs` など）は、差分が `doc/` だけなら問題なしとしてよい

#### 2-4. advisory と報道

```bash
gh api "repos/$repo/security-advisories?per_page=10" --jq '.[] | "\(.ghsa_id) \(.severity) \(.published_at) \(.summary)"'
```

- WebSearch で `<repo> neovim plugin compromised OR malicious OR "supply chain"` を調べる。出典が 1 つしかない主張や、時期の合わない記事は「未確認」として表の注記に書く
- Neovim のプラグインは GitHub Advisory Database の ecosystem に無いので、repo の advisory と報道で見る

#### 2-5. Mason のツール（入れ替えない）

```bash
cd ~/.local/share/nvim/mason/packages
jq -n '[inputs | (.source.id // .primary_source.id) | select(startswith("pkg:")) | sub("#.*$"; "")] | {queries: map({package: {purl: .}})}' */mason-receipt.json > "$TMPDIR/osv-q.json"
curl -s -X POST -d @"$TMPDIR/osv-q.json" https://api.osv.dev/v1/querybatch |
  jq -r --slurpfile q "$TMPDIR/osv-q.json" '.results | to_entries[] | select(.value.vulns) | "\($q[0].queries[.key].package.purl) \([.value.vulns[].id] | join(","))"'
```

- `MAL-` で始まる id があるツールは、表の下に印 `MAL` で目立たせ、`:MasonUninstall` を勧める（このスキルでは入れ替えない）
- `GHSA-` などの脆弱性は参考として書く
- `pkg:github/`・`pkg:generic/` の purl（codelldb、golangci-lint など）は OSV に無く空で返るので、「OSV の対象外」とまとめて書く
- 2-2 で LazyVim の `ensure_installed` に増えたツールがあれば、その名前も書く（次の起動で Mason が最新版を入れる）

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

- 基準 → 候補は短い sha（tag を追うものは tag 名も）。経過時間は候補が branch に届いた時刻（手順 1）から `190 時間（7.9 日）` のように書く。印 `基準が 168 時間未満` の行は、基準が届いた時刻（手順 1 の届いた時刻のコマンドを `sha=$base` で）からの時間も書く。時間は `jq -rn --arg t '<timestamp>' '(now - ($t | fromdateiso8601)) / 3600 | floor'` で出す
- 印 `ずれ` の行は HEAD も書き、HEAD が候補の先にあるなら「HEAD は 168 時間未満、候補まで戻す」と書く
- 候補なしのプラグインは載せない。見送りは理由を判定の列に書く
- 表の下に Mason の結果（`MAL` と脆弱性のあるものだけ）を書く
- 表のあとに AskUserQuestion で承認を取る。最初の質問の選択肢は「更新可だけ実行」「更新可と要判断を選んで実行」「やめる」
- 「要判断を選んで実行」なら、要判断の項目を multiSelect で選ばせる。AskUserQuestion は 1 問に選択肢 2〜4 個、1 回の呼び出しに 4 問までなので、項目を 2〜4 件ずつの問いに分けて 1 回に 4 問まで並べ、16 件を超える分は次の呼び出しで聞く。1 件だけの問いは作らない（5 件は 3 + 2）。全体で 1 件なら「<名前>: 上げる」「上げない」の 2 択にする
  - 選択肢の label には、選んだときに起きることを書く（`blink.cmp: 上げる`、`LazyVim: cand に戻す` など）。選ばなかった項目が既定（上げない、基準を残す）になる向きにそろえる
- 印 `ずれ` で承認しなかったものは基準の commit に戻ること、印 `基準が 168 時間未満` で戻すと選んだものは `cand` に戻ることを、承認の前に書いておく

### 手順 4: dotfiles のブランチを用意する

```bash
cp ~/dotfiles/configs/nvim/lazy-lock.json "$TMPDIR/nvim-lock-before.json"   # 入れ替える前の作業ツリーの lock を控える
git restore configs/nvim/lazy-lock.json
git switch main
git pull --ff-only
git switch -c chore/nvim-lazy-lock-$(date +%Y%m%d-%H%M)
```

- `switch` と `pull --ff-only` は、作業ツリーの lock に変更があると「would be overwritten」で止まるので、先に `restore` する。捨てるのは lazy.nvim が HEAD から書いた lock だけで、HEAD の状態は手順 1 で控えてある
- ブランチ名は日付と時刻で分ける。同じ名前のブランチがあって `switch -c` が止まったら、前の PR が残っていないか `gh pr list -R capytan/dotfiles --head <名前>` で見て報告する

### 手順 5: lock を書き換えて restore する

1. 承認したプラグインの行の `commit` を、Edit で候補の sha（40 桁）に書き換える。承認しなかった `ずれ` の行は基準のまま（`pull` 後の lock がもう基準）。戻すと選んだ `基準が 168 時間未満` の行は `cand` の sha に書き換える。承認した `新規プラグイン` は、`"<名前>": { "branch": "<既定の branch>", "commit": "<候補>" },` の行を名前の順の位置に足す（名前は repo 名。spec に `name =` があればそれ）
2. lock を検証する。key が基準と同じ（足した `新規プラグイン` を除く）で、変わったのが承認したものだけであることを見る

```bash
LOCK=~/dotfiles/configs/nvim/lazy-lock.json
jq -e 'type == "object" and length > 0' "$LOCK" >/dev/null && echo valid
diff <(jq -S . "$TMPDIR/nvim-lock-base.json") <(jq -S . "$LOCK")
```

3. 名前を付けずに全体を restore する。ずれのないプラグインは checkout されず、fetch だけが走る。restore は入っていないプラグインを入れないが、起動時のインストールが lock の commit で入れる（`新規プラグイン` は restore のための起動で入る）

```bash
nvim --headless "+Lazy! restore" +qa > "$TMPDIR/nvim-restore.log" 2>&1; echo "exit=$?"
sed 's/\x1b\[[0-9;]*m//g' "$TMPDIR/nvim-restore.log" | grep -E 'HEAD is now|build|[Ee]rror|[Ff]ailed'
```

4. 全プラグインの HEAD が lock と一致するか、restore が lock を書き直したあとも中身が手順 5-1 と同じかを確かめる

```bash
jq -r 'to_entries[] | "\(.key) \(.value.commit)"' "$LOCK" | while read -r n c; do
  [ "$(git -C "$LAZY/$n" rev-parse HEAD)" = "$c" ] || echo "MISMATCH $n"
done
git diff configs/nvim/lazy-lock.json
```

restore は lock を lazy.nvim の書式で書き直すので、`git diff` は承認した行だけになる。`MISMATCH` が出たとき、承認していない key が増えたとき（lock に無いプラグインが起動で入った）は、手順 6 に進まずに報告する。

### 手順 6: commit、push、PR

1. `git status --short` が `configs/nvim/lazy-lock.json` だけであることを確かめ、それだけを stage して commit する

```bash
git add configs/nvim/lazy-lock.json
git commit -m "chore(nvim): lazy-lock.json を更新する"
git push -u origin HEAD
```

2. PR 本文は PR テンプレートの見出しに従い、表の全文は貼らず、要点だけを書く

- Summary: 基準時刻、上げたプラグインの数、7 日ルールと侵害の確認を通したこと
- Test plan: 手順 5 の HEAD の一致と、build が走ったプラグイン
- Review focus: 要判断で決めたもの、見送ったものと理由、Mason の `MAL` の有無
- Merge and release notes: merge 後の片付け（下）

```bash
gh pr create -R capytan/dotfiles --base main --title "chore(nvim): lazy-lock.json を更新する" --body-file "$TMPDIR/nvim-pr-body.md"
```

3. 報告する。更新したもの、見送ったものとその理由、失敗したものを表で書き、commit と PR を完全な URL で付ける。merge 後の片付けも伝える

```bash
git switch main
git pull --ff-only
git branch -d chore/nvim-lazy-lock-<日付>
```

merge までは `~/dotfiles` をこのブランチのままにしておく。main に戻すと lock が古い版になり、HEAD とずれる。

## エラー処理

| 状況 | 対応 |
|---|---|
| `gh api` が rate limit や認証エラー | `gh auth status` と `gh api rate_limit --jq .resources.core` を確かめるよう伝えて止める。公開時刻が取れないまま判定しない |
| activity が取れない（404、GitHub 以外の host） | その候補は「見送り（公開時刻不明）」 |
| `git fetch` の失敗 | そのプラグインは「見送り（fetch 失敗）」としてエラーを原文で書く。ほかは続ける |
| `MISSING` が出た、spec に lock に無いプラグインがある | nvim を起動せずに止めて報告する。入れるかどうかは持ち主に聞く |
| `switch -c` が「already exists」で止まる | 同じ名前のブランチと PR の状態を見て報告する。ブランチは消さない |
| lock の検証（`jq -e`）が通らない | restore を実行しない。`git diff` を見て直す |
| restore の失敗（exit が 0 でない、ログに error） | ログを原文で伝えて止める。commit しない。戻すときは `git restore configs/nvim/lazy-lock.json` のあと、もう一度 `nvim --headless "+Lazy! restore" +qa` |
| restore のあと HEAD が lock とずれる | どのプラグインかと両方の sha を伝えて止める。commit しない |
| `pull --ff-only` が止まる | 作業ツリーの変更を `git status` で見て報告する。lock 以外の変更は捨てない |

---
name: update-nvim-plugins
description: LazyVim（lazy.nvim）のプラグインを、サプライチェーン侵害の事前確認（GitHub への push から 7 日の見送り、差分の危険箇所、作者と merge した人、advisory と報道）を挟んでから更新する。候補を表にして承認を得てから lazy-lock.json を書き換えて restore し、dotfiles に PR を出す。Mason の npm のツールも、同じ確認のあと承認を得て入れ替える。「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」「Mason のツールを更新」等で発動する。uv・mise・Homebrew のツールには使わない（`update-local-tools` を使う）。
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

結果を表で示し、承認を得たものだけ lock を書き換えて入れ替える。lock の変更は dotfiles のブランチに commit し、PR にする。

## 守ること

- 手順 1〜4 は読み取りだけ。承認の前にプラグインを入れ替えない。`:Lazy update`・`:Lazy sync`・`:Lazy` の画面の `U`・`S` を使わない（branch の先頭や最新の tag まで、確かめずに進む）
- 入れ替えは、lock を書き換えてから `Lazy! restore` で行う。restore は lock の commit にだけ checkout する
- 承認の範囲を広げない。承認後に候補が変わった（手順 1 をやり直した等）ら表を作り直す
- main に直接 commit しない。ブランチを切って lock だけを commit し、PR にする。merge はしない
- nvim を起動する前に、手順 1 の `MISSING` が空であること。spec を読み出したあとの起動（restore、`MasonInstall` など）では、spec にあって lock に無いプラグインも無いこと。起動時のインストール（前提の表）で、確かめていない commit が入るのを防ぐ
- Mason のツールは、手順 1〜6 では確かめるだけで入れ替えない。入れ替えは「Mason のツールの入れ替え」の節で、表と承認を別に取ってから行う

## When to Use This Skill

発動する依頼:
- 「nvim のプラグインを更新」「LazyVim を更新」「Lazy update して」「lazy-lock を更新」
- 「`:Lazy` で更新が出ている」「プラグインを最新に」
- 「Mason のツールを更新」「Mason のツールの脆弱性を消して」→ 手順 1 の `cutoff`、手順 2-5、「Mason のツールの入れ替え」の節だけを回す

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

シェルの変数は Bash の呼び出しをまたいで残らない。下のコードブロックは、使う変数（`LAZY`・`cutoff`・`LOCK`、プラグインごとの `n`・`d`・`repo`・`b`・`base`・`t7`・`cand`・`sha`・`from`・`to`、Mason のツールごとの `m`・`pkg`・`cur`・`cand`・`W`）をそのブロックの先頭で定義し直してから実行する。`cutoff` は最初に出した値をそのまま書き込み、呼び出しのたびに計算し直さない。

dotfiles への `git` は、`~/dotfiles` を cwd にして `-C` を付けずに書いている（グローバルの CLAUDE.md の決まり）。lock は `~/.config/nvim` の symlink を通して必ず `~/dotfiles` の本体に書かれるので、始める前に次で cwd を確かめ、`OTHER` なら（別の repo、dotfiles の worktree、`~/dotfiles` の下のディレクトリなど）以降の dotfiles への `git` をすべて `git -C ~/dotfiles` に読み替える。プラグインのディレクトリへの `git -C "$d"` はそのまま使う。

```bash
[ "$(pwd -P)" = "$(cd ~/dotfiles && pwd -P)" ] && echo DOTFILES || echo OTHER
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

#### 2-5. Mason のツール（ここでは入れ替えない）

ツールそのものの purl を OSV に、ツールのディレクトリの中身を `trivy rootfs` にかける。rootfs は入っているパッケージのメタデータ（`node_modules/<pkg>/package.json`、`specifications/<gem>.gemspec`、`site-packages/<pkg>.dist-info`。以下「メタデータの置き場所」）と Go のバイナリを読み、lock は読まない。`trivy fs` は Go のバイナリと gemspec を読まないので使わない。

```bash
jq -n '[inputs | (.source.id // .primary_source.id) | select(startswith("pkg:")) | sub("#.*$"; "")] | {queries: map({package: {purl: .}})}' ~/.local/share/nvim/mason/packages/*/mason-receipt.json > "$TMPDIR/osv-q.json"
curl -s -X POST -d @"$TMPDIR/osv-q.json" https://api.osv.dev/v1/querybatch |
  jq -r --slurpfile q "$TMPDIR/osv-q.json" '.results | to_entries[] | select(.value.vulns) | "\($q[0].queries[.key].package.purl) \([.value.vulns[].id] | join(","))"'
trivy rootfs --scanners vuln --format json --quiet ~/.local/share/nvim/mason/packages/ 2> "$TMPDIR/trivy-mason.err" |
  jq -r '.Results[]? | .Target as $t | .Type as $ty | .Vulnerabilities[]? | (.PkgPath // $t) as $p | "\($p | split("/")[0]) \($ty) \($p) \(.PkgName)@\(.InstalledVersion) \(.VulnerabilityID) \(.Severity) fixed=\(.FixedVersion)"' | sort -u > "$TMPDIR/trivy-mason.txt"
awk '{ print $1, $2 }' "$TMPDIR/trivy-mason.txt" | sort | uniq -c   # ツールと種類ごとの件数
```

- 各行は、ツール（Mason の名前）、種類（`node-pkg`・`gemspec`・`python-pkg`・`gobinary`）、パス、パッケージ@版、id、重さ、修正版。Go のバイナリは Target、それ以外は `PkgPath` の先頭がツールの名前になる
- `trivy-mason.err` が空でなければ、下のエラー処理の表の trivy の行に従う

- `MAL-` で始まる id があるツールは、表の下に印 `MAL` で目立たせ、下の「Mason のツールの入れ替え」で消すか入れ替えるかを聞く
- `GHSA-`・`CVE-` などの脆弱性は参考として書き、入れ替えるかは下の節で聞く。purl が `pkg:npm/` でないツール（Go のバイナリ、gem、pypi など）の行は、M-3 の表の下に「対象外」としてまとめ、報告に残す
- `pkg:github/`・`pkg:generic/` の purl（codelldb、golangci-lint など）は OSV に無く空で返るので、「OSV の対象外」とまとめて書く
- パスがメタデータの置き場所でない行（gem や npm のパッケージに同梱されたテスト用の `package.json` など）は、入っているものではない。その名前と版が `<ツール>/package-lock.json`・`<ツール>/specifications`・`site-packages` に無ければ誤検知として数えない
- `gobinary` の行は、バイナリに埋め込まれたモジュールと、ビルドに使った Go（`stdlib`）の版で判定したもの。ツールがその箇所を呼ぶかは分からない。直すには上流が新しい Go でビルドし直した版が要る
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
- 表の下に Mason の結果（`MAL` と脆弱性のあるものだけ）を書く。入れ替えはこの承認に含めず、「Mason のツールの入れ替え」で別に聞く
- 表のあとに AskUserQuestion で承認を取る。最初の質問の選択肢は「更新可だけ実行」「更新可と要判断を選んで実行」「やめる」
- 「要判断を選んで実行」なら、要判断の項目を multiSelect で選ばせる。AskUserQuestion は 1 問に選択肢 2〜4 個、1 回の呼び出しに 4 問までなので、問いの数を件数 ÷ 4 の切り上げにして、件数の差が 1 以内になるよう均等に分け（5 件は 3 + 2）、5 問目からは次の呼び出しで聞く。こう分ければ 1 件だけの問いはできない。全体で 1 件なら multiSelect を使わず、その項目を変えるか既定のままにするかの 2 択にする（label の書き方は下と同じ）
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

### Mason のツールの入れ替え（承認されたときだけ）

手順 2-5 で `MAL` や脆弱性が出たツールを、確かめた版に入れ替える（または消す）。Mason のツールは `~/.local/share/nvim/mason` にあり、dotfiles の lock にも PR にも載らない。lock の流れ（手順 3〜6）とは表と承認を分け、承認されたものだけを入れ替える。lock の流れを回さずにこの節だけを頼まれたときも、手順 1 の `cutoff` と手順 2-5 を先に行う。

対象は purl が `pkg:npm/` のツール。ほかの種類（`pkg:pypi/`・`pkg:gem/`・`pkg:golang/`・`pkg:github/` など）は確かめ方を決めていないので、表に「対象外（入れ替えの手順なし）」と書き、入れ替えない。

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| Mason の npm | `mason-core/installer/managers/npm.lua` は `npm install <pkg>@<版>` を呼ぶだけで、lock を持たない。推移的な依存はその場で最新に解決され、install のスクリプトも走る | 事前に一時ディレクトリで同じ木を作って確かめ、本番の後に木が一致するかを見る |
| `min-release-age` | npm の設定で、単位は日（npm の `@npmcli/config` の definitions）。指定した版や依存がそれより新しいと `ETARGET` で止まる。環境変数 `npm_config_min_release_age` は Mason が起動する npm にも届く | 事前の木と本番の両方に `npm_config_min_release_age=7` を付ける。推移的な依存にも 7 日ルールがかかる。知らない npm は警告だけ出して無視するので、M-2 と M-4 の前に `npm_config_min_release_age=7 npm config get min-release-age` が `7` を返すことを確かめ、返さなければ止める |
| registry | npm の registry が npmjs 以外を向いている Mac がある（例 `configs/takumi-guard/setup-anon.sh` の Takumi Guard） | 確かめるための照会（packument、attestations、integrity、`npm diff`、`npm audit signatures`）は、いつも `registry.npmjs.org` に向ける |
| mason.nvim の読み込み | LazyVim は mason.nvim を遅延して読み込む。doc の形 `nvim --headless -c "MasonInstall ..." -c qall` だけだと `E492: Not an editor command: MasonInstall` で失敗し、exit は 0 のまま | `MasonInstall`・`MasonUninstall` の前に `Lazy! load mason.nvim` を置き、結果はログで見る |
| `ensure_installed` | LazyVim の extra などの `ensure_installed` に入っているツールは、`MasonUninstall` しても次の起動で入り直す | 消すには `configs/nvim/lua/plugins/` で外す変更（dotfiles の PR）が要る（例 markdown-toc は `markdown.lua` で外した） |

#### M-1. 候補の版

ツールごとに、Mason の名前（`MasonInstall` に渡す）、npm のパッケージ名、今の版を receipt から取る。npm 以外は `対象外` と purl を出すので、2-5 で当たったものは表に「対象外（入れ替えの手順なし）」で載せる。

```bash
jq -r '(.source.id // .primary_source.id // "") as $id | if ($id | startswith("pkg:npm/")) then .name + " " + ($id | sub("^pkg:npm/"; "") | sub("%40"; "@") | sub("@(?<v>[^@]+)$"; " \(.v)")) else .name + " 対象外 " + $id end' ~/.local/share/nvim/mason/packages/*/mason-receipt.json
```

候補は、`cutoff`（手順 1）以前に npm に公開された安定版（`X.Y.Z`、pre-release を除く）のうち、版が最も新しいもの。`m`・`pkg`・`cur` は上の行の値。

```bash
curl -s "https://registry.npmjs.org/$pkg" > "$TMPDIR/npm-$m.json"
jq -r --arg c "$cutoff" '.time as $t | .versions | keys[] | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$") and $t[.] <= $c)' "$TMPDIR/npm-$m.json" | sort -V | tail -1
```

- 候補が `cur` と同じなら「候補なし」。`cur` より古ければ、今の版が 168 時間未満で入っているので印 `今の版が 168 時間未満` を付けて要判断
- 候補で目的の脆弱性が消えるかは、M-2 の木の OSV で見る。直接の版で直らず、推移的な依存（例 markdownlint-cli2 の中の re2js）の版で直るものもある
- 消すだけ（`MAL` のツールなど）の行は候補を取らず、M-2 を省いて M-3 に進む

#### M-2. 確認（候補ごと）

公開時刻、公開者、maintainers、install のスクリプトを、今の版から候補までの全部の版（公開の順）で比べる。間の版の変更も候補の差分に入るので、両端だけで見ない。

```bash
jq -r --arg a "$cur" --arg b "$cand" '.time as $t | ([$t[$a], $t[$b]] | sort) as [$lo, $hi] | [.versions[]] |
  "before=\(map(select($t[.version] < $lo) | ._npmUser.name) | unique | join(","))",
  (.[] | select($t[.version] >= $lo and $t[.version] <= $hi) | "\(.version) published=\($t[.version]) npmUser=\(._npmUser.name) maintainers=\([(.maintainers // [])[].name] | join(",")) scripts=\(.scripts // {} | with_entries(select(.key | test("install"))) | keys | join(","))")' "$TMPDIR/npm-$m.json"
```

`before=` は範囲より前の公開者。範囲の端は公開の順に並べるので、候補が今の版より古いとき（`今の版が 168 時間未満`）も出る。

- 範囲の中で公開者が変わったとき、今の版より前の公開者に無い（初めての作者）とき、maintainers が増減したときは印 `公開者の変化` を付けて要判断
- `preinstall`・`install`・`postinstall` が候補で増えたら印 `install のスクリプト` を付け、中身を読む

provenance を見て、上流の tag の commit と照合する。

```bash
curl -s "https://registry.npmjs.org/-/npm/v1/attestations/$pkg@$cand" |
  jq -r '.attestations[]? | select(.predicateType == "https://slsa.dev/provenance/v1") | .bundle.dsseEnvelope.payload | @base64d | fromjson | .predicate.buildDefinition | "\(.externalParameters.workflow.repository) \(.externalParameters.workflow.ref) \(.resolvedDependencies[0].digest.gitCommit)"'
gh api "repos/<owner>/<repo>/commits/<tag>" --jq .sha   # 上の commit と同じか
```

- repository が `npm-$m.json` の `.repository.url` と同じ owner/repo で（`git+` と `.git` を除き、大文字と小文字を区別せずに比べる。例 `git+https://github.com/biomejs/biome.git` と `https://github.com/biomejs/biome` は同じ）、ref が候補の tag、commit が tag の commit と一致することを見る
- 前の版に provenance があって候補に無いときは印 `provenance なし` を付けて要判断。もともと無いパッケージは、tag と版の対応（GitHub の release、CHANGELOG）を見て表に「provenance なし（前から）」と書く

範囲の差分を tarball で取り、危険箇所を 2-2 と同じ見方で読む。

```bash
npm diff --registry=https://registry.npmjs.org/ --diff="$pkg@$cur" --diff="$pkg@$cand" > "$TMPDIR/npm-diff-$m.patch"
grep -nE '^\+.*(child_process|execSync|spawn\(|exec\(|eval\(|new Function|https?://|base64|(\\x[0-9a-fA-F]{2}){8})' "$TMPDIR/npm-diff-$m.patch"
grep -E '^\+' "$TMPDIR/npm-diff-$m.patch" | awk 'length > 400 { print substr($0, 1, 200) "..." }'
```

- 見る箇所は、install・postinstall のスクリプト、外部の実行、ダウンロード、難読化。bundle された `dist/` は長い行が多いので、当たった行の前後を読み、上流の tag の同じ変更で説明がつくかを見る
- advisory は `gh api "advisories?ecosystem=npm&affects=$pkg@$cand&per_page=10" --jq '.[] | "\(.ghsa_id) \(.type) \(.severity) \(.summary)"'`、報道は 2-4 と同じく WebSearch で `<pkg> npm compromised OR malicious OR "supply chain"` を調べる

推移的な依存の木を、一時ディレクトリで本番と同じ条件（7 日ルール、Mason の `install-strategy=shallow`、receipt の `extra_packages`）で作る。`--ignore-scripts` で install のスクリプトは走らせない。先に、npm が `min-release-age` を知っていることを確かめる（上の表）。

```bash
extra=$(jq -r '(.source.raw.extra_packages // []) | join(" ")' ~/.local/share/nvim/mason/packages/"$m"/mason-receipt.json)
W=$(mktemp -d)
(cd "$W" && npm_config_min_release_age=7 npm install --ignore-scripts --install-strategy=shallow "$pkg@$cand" $extra)
npm_tree() { jq -r '.packages | to_entries[] | select(.key != "") | "\(.value.name // (.key | sub(".*node_modules/"; ""))) \(.value.version) \(.value.integrity // "-")"' "$1" | sort -u; }   # 名前 版 integrity（alias は本当の名前）
npm_tree "$W/package-lock.json" > "$TMPDIR/npm-tree-$m.txt"
npm_tree ~/.local/share/nvim/mason/packages/"$m"/package-lock.json | diff - "$TMPDIR/npm-tree-$m.txt"   # 今の木から増えた・変わった依存
jq -Rn '{queries: [inputs | split(" ") | {package: {ecosystem: "npm", name: .[0]}, version: .[1]}]}' "$TMPDIR/npm-tree-$m.txt" > "$TMPDIR/osv-tree-$m.json"
curl -s -X POST -d @"$TMPDIR/osv-tree-$m.json" https://api.osv.dev/v1/querybatch |
  jq -r --slurpfile q "$TMPDIR/osv-tree-$m.json" '.results | to_entries[] | select(.value.vulns) | "\($q[0].queries[.key].package.name)@\($q[0].queries[.key].version) \([.value.vulns[].id] | join(","))"'
jq -r '.packages | to_entries[] | select(.value.hasInstallScript) | .key' "$W/package-lock.json"
awk '$3 != "-"' "$TMPDIR/npm-tree-$m.txt" | xargs -P 8 -n 3 sh -c 'r=$(curl -sf "https://registry.npmjs.org/$0/$1" | jq -r ".dist.integrity // \"none\""); if [ -z "$r" ]; then echo "FETCH-FAILED $0@$1"; elif [ "$r" = none ]; then echo "NO-INTEGRITY $0@$1"; elif [ "$r" != "$2" ]; then echo "INTEGRITY-MISMATCH $0@$1"; fi'
(cd "$W" && npm audit signatures --registry=https://registry.npmjs.org/)
```

- `extra` の中身は今の版の receipt のもの。Mason の registry で候補の版の `extra_packages` が変わっていれば、それに合わせる
- 今の木から増えた・変わった依存（上の `diff` の `>` の行）のうち、この Mac に入ったもの（`$W/node_modules` の下にあるもの。lock は別の OS の optional のバイナリも並べる）は本番で新しく入る。その全部に、上の公開者と maintainers の比べ（`$TMPDIR/npm-$m.json` の代わりにその依存の packument）をかける。そのうちツールが実行するコードを持つもの（biome・oxfmt・oxlint の `@biomejs/cli-darwin-arm64`・`@oxfmt/binding-darwin-arm64` のような platform 別のバイナリ、本体が呼ぶ実装のパッケージ）には、provenance と `npm diff` もかける
- 木の OSV に `MAL-` があれば見送り。目的の脆弱性の id が残っていれば印 `脆弱性が残る` を付けて要判断
- `hasInstallScript` の依存は、本番では install のスクリプトが走る。今の木に無かったものは、そのパッケージの scripts を読む
- `FETCH-FAILED` は registry の一時的な失敗（429 など）。その行だけやり直す
- `INTEGRITY-MISMATCH` が出たら見送り。`npm audit signatures` が署名や attestation の失敗を出したら見送り
- `NO-INTEGRITY` は registry に `dist.integrity` が無い古いパッケージ。`curl -s "https://registry.npmjs.org/$n/$v" | jq -r .dist.shasum` と、lock の `sha1-` の値（base64）を hex にしたもの（`echo '<base64>' | base64 -d | xxd -p`）を比べる
- `W` の中身は消さずに残してよい（`$TMPDIR` の下）。M-5 で `npm-tree-$m.txt` と比べる

#### M-3. 表と承認

lock の表（手順 3）とは別に、次の列で表を出す。

| ツール | 今の版 → 候補 | 公開からの時間 | 解消する脆弱性 | 公開者・maintainers | provenance・署名 | 差分の危険箇所 | 依存の木 | 印 | 判定 |
|---|---|---|---|---|---|---|---|---|---|

| 判定 | 条件 |
|---|---|
| 入れ替え可 | 168 時間以上、公開者と maintainers に変化なし、provenance が上流の tag の commit と一致（前から無いものは tag と版の対応が取れる）、integrity と署名が通る、危険箇所に異常なし、木に `MAL-` なし、advisory・報道なし |
| 見送り | 168 時間未満、`INTEGRITY-MISMATCH`、署名の失敗、説明のつかない差分、木に `MAL-`、advisory・侵害報道がある |
| 要判断 | `今の版が 168 時間未満`、`公開者の変化`、`install のスクリプト`、`provenance なし`、`脆弱性が残る`、メジャー跨ぎ、消す（`ensure_installed` に入っているものは PR が要る） |

- 2-5 で当たった npm 以外のツールは、判定の列を「対象外（入れ替えの手順なし）」にして同じ表の下にまとめる。列は、ツール、種類（`gobinary`・`gemspec`・`python-pkg`）、件数（重さ別）、主なパッケージ（`stdlib@v1.24.0`、`nokogiri@1.19.3` など）。承認の選択肢には入れない
- 公開からの時間は `jq -r --arg v "$cand" '(now - (.time[$v] | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601)) / 3600 | floor' "$TMPDIR/npm-$m.json"`（`update-local-tools` と同じ形）。npm の時刻はミリ秒つき（`...47.800Z`）で、`fromdateiso8601` がそのままでは読めないので `sub` で落とす
- AskUserQuestion で承認を取る。選択肢と、要判断の multiSelect の分け方は手順 3 と同じ（「入れ替え可だけ実行」「入れ替え可と要判断を選んで実行」「やめる」）。label は `oxfmt: 0.74.0 に上げる`、`markdown-toc: 消す` のように、選んだときに起きることを書く
- 消す行のうち `ensure_installed` に入っているものは、`MasonUninstall` だけでは次の起動で戻ることを承認の前に書き、`configs/nvim/lua/plugins/` で外す PR を別に作るかも聞く。その PR は手順 4・6 と同じく dotfiles のブランチで作る

#### M-4. 実行

承認したものだけを、7 日ルールの環境変数を付けて入れ替える。複数のツールは 1 回の `MasonInstall` に並べてよい。headless の `MasonInstall` は終わるまで待つ。

先に、npm が `min-release-age` を知っていること（上の表）と、守ることの nvim の起動の前の確認を行う。

```bash
npm_config_min_release_age=7 nvim --headless -c "Lazy! load mason.nvim" -c "MasonInstall <m>@<cand> ..." -c qall > "$TMPDIR/mason-install.log" 2>&1; echo "exit=$?"
sed 's/\x1b\[[0-9;]*m//g' "$TMPDIR/mason-install.log" | grep -E 'Installing|installed|failed|[Ee]rror|E492|ETARGET|aborted'
```

消すと承認したものは、同じく mason.nvim を読み込んでから消す。

```bash
nvim --headless -c "Lazy! load mason.nvim" -c "MasonUninstall <m> ..." -c qall 2>&1 | sed 's/\x1b\[[0-9;]*m//g'
```

- exit が 0 でも失敗していることがある（`E492` など）。ログで各ツールの成否を見る
- 失敗したツールは前の版が残る（receipt が変わらない）。M-5 で receipt を見て確かめる

#### M-5. 入れ替え後の確認

receipt の版と、入った後の木が M-2 の事前の木と一致するかを見る。`npm_tree` は M-2 の定義をこのブロックの先頭に置き直す。

```bash
jq -r '.source.id' ~/.local/share/nvim/mason/packages/"$m"/mason-receipt.json
npm_tree ~/.local/share/nvim/mason/packages/"$m"/package-lock.json | diff "$TMPDIR/npm-tree-$m.txt" - && echo SAME
```

- 差が出たら（事前の確認のあとに依存の新しい版が 7 日を越えた等）、増えた・変わった依存を M-2 と同じく OSV・integrity・install のスクリプトにかけて報告する
- 手順 2-5 の OSV と trivy をかけ直す。trivy の出力先は `$TMPDIR/trivy-mason-after.txt`・`trivy-mason-after.err` に変え（同じ名前だと前の結果を上書きする）、`diff "$TMPDIR/trivy-mason.txt" "$TMPDIR/trivy-mason-after.txt"` で目的の脆弱性が減ったことを確かめる
- 報告には、入れ替えたもの（版の前後）、消したもの、見送ったものと理由、減った脆弱性と残った脆弱性を表で書く。`ensure_installed` から外す PR を作ったときは完全な URL を付ける

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
| `trivy: command not found`、trivy の DB の取得の失敗 | `trivy-mason.txt` が空でも「脆弱性なし」と書かない。エラーを原文で伝え、表に「trivy 未実行」と書く。入れ替えの後の比べ（M-5）もできないので、入れ替えは OSV の結果だけで決めてよいか持ち主に聞く |
| `E492: Not an editor command: MasonInstall`（`MasonUninstall` も同じ） | mason.nvim が読み込まれていない。`-c "Lazy! load mason.nvim"` を前に置いてやり直す。exit が 0 でも失敗している |
| `npm error code ETARGET`（`No matching version found for <pkg>@<版> with a date before ...`） | 指定した版か依存が 7 日ルールに引っかかった。その版は見送り、M-1 の候補を取り直す。前の版が残っていることを receipt で確かめる |
| `Neovim is exiting while packages are still installing` と `Installation was aborted` | mason.nvim を読み込んだときに `ensure_installed` の入っていないツールの install が始まり、`qall` で止まった。止まったツールの名前を報告し、入れるかを持ち主に聞く。`MasonInstall` に並べたツールがこの中に出たら、先に `ensure_installed` の側が入れ始めて待たれなかったので、M-5 で receipt を見てから入れ替えをやり直す |
| `MasonUninstall` したツールが次の起動で戻る | `ensure_installed` に入っている。`configs/nvim/lua/plugins/` で外す PR を作るかを持ち主に聞く |
| `INTEGRITY-MISMATCH`、`npm audit signatures` の失敗 | 入れ替えない。どのパッケージかと、registry の値を原文で伝えて止める |
| 入れ替え後の木が事前の木と違う | 差の依存を M-2 と同じく確かめて報告する。`MAL-` があれば `MasonUninstall` を勧める |

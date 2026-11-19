# 手順 1・2 のコマンドと見方

SKILL.md の手順 1・2 で Read する。変数の定義し直し（`SKILL_DIR`・`LAZY`・`cutoff` など）は SKILL.md の「Execution Process」に従う。

## 目次

- 手順 1: 候補の収集（基準時刻、dotfiles の状態、spec、候補の判定、届いた時刻）
- 手順 2: 侵害の事前確認（2-1 repo の状態と上流、2-2 差分の危険箇所、2-3 作者と merge した人、2-4 advisory と報道、2-5 Mason のツール）

## 手順 1: 候補の収集（読み取りのみ）

基準時刻と、その 168 時間前を取る。

```bash
jq -rn 'now | todate'                    # 基準時刻（表に書く）
jq -rn 'now - 168*3600 | todate'         # 168 時間前。以降のブロックで cutoff='<この値>' として使う
```

dotfiles の状態と、基準にする lock（origin/main のもの）を取る。

```bash
if [ "$(git -C ~/dotfiles branch --show-current)" = main ]; then git -C ~/dotfiles pull --ff-only; else echo NOT-MAIN; fi
git -C ~/dotfiles status --short
git -C ~/dotfiles show origin/main:configs/nvim/lazy-lock.json > "$TMPDIR/nvim-lock-base.json"
```

- `NOT-MAIN` が出たとき、`pull --ff-only` が止まったときは、エラー処理の表に従って止める。本体を origin/main にそろえるのは、下で読む spec が本体のもので、worktree と基準は origin/main だから
- ただし `pull` が「would be overwritten」で止まり、挙がったのが `configs/nvim/lazy-lock.json` だけなら、`git -C ~/dotfiles restore configs/nvim/lazy-lock.json` のあと pull し直してよい。本体の lock の変更は lazy.nvim が HEAD から書いたもので、HEAD はプラグインのディレクトリに残り、下の「ずれ」で拾える
- `status` に `configs/nvim/` の lock 以外（`lua` や `lazyvim.json`）の変更が出たら止めて報告する。lock に無いプラグインが spec に増えている恐れがある。`configs/nvim/` の外の変更はこのスキルでは触らない
- 本体の lock が origin/main と違うのは、誰かが `:Lazy update` などで入れ替えた跡のことが多い。下の「ずれ」で拾う

全プラグインが入っているかを確かめてから、spec の `version`・`build` などを読む。`MISSING` が出たら、nvim を起動すると lock の commit で clone されるので、起動する前に持ち主に伝えて止める。

```bash
LAZY=~/.local/share/nvim/lazy
jq -r 'keys[]' "$TMPDIR/nvim-lock-base.json" | while read -r n; do [ -d "$LAZY/$n/.git" ] || echo "MISSING $n"; done
nvim --headless +'lua local C=require("lazy.core.config"); for n,p in pairs(C.plugins) do local v=p.version; if v==nil and p.branch==nil then v=C.options.defaults.version end; io.stdout:write(("%s\t%s\tversion=%s tag=%s commit=%s pin=%s build=%s\n"):format(n, p.url or "local", tostring(v), tostring(p.tag), tostring(p.commit), tostring(p.pin), type(p.build)=="function" and "function" or tostring(p.build))) end' +qa > "$TMPDIR/nvim-specs.tsv"
```

- `version` が `*` などの文字列なら tag を追う。`tag`・`commit`・`pin` があるものは lazy.nvim が update で動かさないので、対象から外して表に参考で書く
- `nvim-specs.tsv` にあって lock に無いプラグインがあれば止めて報告する（起動で branch の先頭が入った恐れがある）

プラグインごとに fetch し、168 時間前の branch の先頭を activity API で取る（`activity-tip.sh`）。

```bash
bash "${SKILL_DIR:?}/scripts/collect-candidates.sh" "$TMPDIR/nvim-lock-base.json" "$cutoff" > "$TMPDIR/nvim-candidates.tsv"
```

各行（名前、repo、branch、基準、HEAD、168 時間前の先頭とその時刻）から候補 `cand` を決める。`d`（`$LAZY/<名前>`）・`b`・`base`・`t7`（先頭の sha）はその行の値。

- `nvim-specs.tsv` の `version=` が `false` か `nil` なら branch を追う。`cand=$t7`
- それ以外（`*` など）は tag を追う。`t7` の行はそのまま使わず、下で出た tag の commit を `cand`、その branch を `b` にする。branch の先頭で候補を判定しない（tag を打つ前の commit まで候補になる）

```bash
for rb in $(git -C "$d" branch -r --format='%(refname:lstrip=3)' | grep -xE "$b|v?[0-9]+(\.([0-9]+|x))*|stable|release/.*"); do
  tip=$(bash "${SKILL_DIR:?}/scripts/activity-tip.sh" "$repo" "$rb" "$cutoff" | cut -d' ' -f1)
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
- `基準が 168 時間未満` が出たら印を付ける。手順 2 の範囲は SKILL.md の手順 2 の表のとおり
- `別の系統`（メジャーの branch が分かれたときなど）は止めて報告する

経過時間の列と印 `基準が 168 時間未満` の行には、その commit が branch に届いた時刻が要る。branch を追うものの `cand` は `t7` の行に時刻がある。tag を追うものの `cand` と基準は、次で取る。まとめて push された中ほどの commit も、そのまとめの activity の時刻になる。

```bash
bash "${SKILL_DIR:?}/scripts/arrival-time.sh" "$repo" "$b" "$d" "$sha"
```

- force push で一度消えて戻った commit や、ローカルに無い `after`（force push で消えた commit）に当たると、そこで止まって新しい側の時刻になる（遅い側に倒れる）。空なら「届いた時刻不明」と書く

## 手順 2: 侵害の事前確認（候補ごと）

範囲 `$from..$to` の決め方と、持ち主が確認済みと言ったときに省けるものは SKILL.md の手順 2 に従う。

### 2-1. repo の状態と上流

```bash
gh api "repos/$repo" --jq '"\(.full_name) archived=\(.archived)"'
gh api "repos/$repo/activity?ref=refs/heads/$b&activity_type=force_push&per_page=100" --paginate --jq '.[] | "\(.timestamp) \(.actor.login) \(.before[0:8])..\(.after[0:8])"'
```

- `full_name` が spec の URL（`$TMPDIR/nvim-specs.tsv`）と違えば、移管か改名。印 `移管` を付けて要判断
- archived なら印 `archived`。上げる commit が無いはずなので、あれば見送り
- 範囲の期間に force push があれば印 `force push` を付けて要判断。範囲の期間は、`from` の commit の committer date より後を目安にする（日時が偽られていても、拾う範囲が広がるだけ）
- `git -C "$d" remote get-url origin` が spec の URL と違えば見送り（入っているものが spec の repo ではない）

### 2-2. 差分の危険箇所

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

### 2-3. 作者と merge した人

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

### 2-4. advisory と報道

```bash
gh api "repos/$repo/security-advisories?per_page=10" --jq '.[] | "\(.ghsa_id) \(.severity) \(.published_at) \(.summary)"'
```

- WebSearch で `<repo> neovim plugin compromised OR malicious OR "supply chain"` を調べる。出典が 1 つしかない主張や、時期の合わない記事は「未確認」として表の注記に書く
- Neovim のプラグインは GitHub Advisory Database の ecosystem に無いので、repo の advisory と報道で見る

### 2-5. Mason のツール（ここでは入れ替えない）

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
- `trivy-mason.err` が空でなければ、`references/mason.md` のエラー処理の表の trivy の行に従う
- `MAL-` で始まる id があるツールは、表の下に印 `MAL` で目立たせ、「Mason のツールの入れ替え」（`references/mason.md`）で消すか入れ替えるかを聞く
- `GHSA-`・`CVE-` などの脆弱性は参考として書き、入れ替えるかは同じ節で聞く。purl が `pkg:npm/` でないツール（Go のバイナリ、gem、pypi など）の行は、M-3 の表の下に「対象外」としてまとめ、報告に残す
- `pkg:github/`・`pkg:generic/` の purl（codelldb、golangci-lint など）は OSV に無く空で返るので、「OSV の対象外」とまとめて書く
- パスがメタデータの置き場所でない行（gem や npm のパッケージに同梱されたテスト用の `package.json` など）は、入っているものではない。その名前と版が `<ツール>/package-lock.json`・`<ツール>/specifications`・`site-packages` に無ければ誤検知として数えない
- `gobinary` の行は、バイナリに埋め込まれたモジュールと、ビルドに使った Go（`stdlib`）の版で判定したもの。ツールがその箇所を呼ぶかは分からない。直すには上流が新しい Go でビルドし直した版が要る
- 2-2 で LazyVim の `ensure_installed` に増えたツールがあれば、その名前も書く（次の起動で Mason が最新版を入れる）

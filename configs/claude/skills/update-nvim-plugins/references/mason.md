# Mason のツールの入れ替え（承認されたときだけ）

SKILL.md の「Mason のツールの入れ替え」から Read する。手順 1・2-5 は `references/plugin-checks.md` にある。変数の定義し直し（`SKILL_DIR`・`cutoff`、ツールごとの `m`・`pkg`・`cur`・`cand`・`W`）は SKILL.md の「Execution Process」に従う。

## 目次

- 前提（Mason の npm、`min-release-age`、registry、mason.nvim の読み込み、`ensure_installed`）
- M-1 候補の版、M-2 確認、M-3 表と承認、M-4 実行、M-5 入れ替え後の確認
- エラー処理

## 前提

Mason のツールは `~/.local/share/nvim/mason` にあり、dotfiles の lock にも PR にも載らない。

対象は purl が `pkg:npm/` のツール。ほかの種類（`pkg:pypi/`・`pkg:gem/`・`pkg:golang/`・`pkg:github/` など）は確かめ方を決めていないので、表に「対象外（入れ替えの手順なし）」と書き、入れ替えない。

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| Mason の npm | `mason-core/installer/managers/npm.lua` は `npm install <pkg>@<版>` を呼ぶだけで、lock を持たない。推移的な依存はその場で最新に解決され、install のスクリプトも走る | 事前に一時ディレクトリで同じ木を作って確かめ、本番の後に木が一致するかを見る |
| `min-release-age` | npm の設定で、単位は日（npm の `@npmcli/config` の definitions）。指定した版や依存がそれより新しいと `ETARGET` で止まる。環境変数 `npm_config_min_release_age` は Mason が起動する npm にも届く | 事前の木と本番の両方に `npm_config_min_release_age=7` を付ける。推移的な依存にも 7 日ルールがかかる。知らない npm は警告だけ出して無視するので、M-2 と M-4 の前に `npm_config_min_release_age=7 npm config get min-release-age` が `7` を返すことを確かめ、返さなければ止める |
| registry | npm の registry が npmjs 以外を向いている Mac がある（例 `configs/takumi-guard/setup-anon.sh` の Takumi Guard） | 確かめるための照会（packument、attestations、integrity、`npm diff`、`npm audit signatures`）は、いつも `registry.npmjs.org` に向ける |
| mason.nvim の読み込み | LazyVim は mason.nvim を遅延して読み込む。doc の形 `nvim --headless -c "MasonInstall ..." -c qall` だけだと `E492: Not an editor command: MasonInstall` で失敗し、exit は 0 のまま | `MasonInstall`・`MasonUninstall` の前に `Lazy! load mason.nvim` を置き、結果はログで見る |
| `ensure_installed` | LazyVim の extra などの `ensure_installed` に入っているツールは、`MasonUninstall` しても次の起動で入り直す | 消すには `configs/nvim/lua/plugins/` で外す変更（dotfiles の PR）が要る（例 markdown-toc は `markdown.lua` で外した） |

## M-1. 候補の版

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

## M-2. 確認（候補ごと）

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

## M-3. 表と承認

lock の表（手順 3）とは別に、次の列で表を出す。

| ツール | 今の版 → 候補 | 公開からの時間 | 解消する脆弱性 | 公開者・maintainers | provenance・署名 | 差分の危険箇所 | 依存の木 | 印 | 判定 |
|---|---|---|---|---|---|---|---|---|---|

| 判定 | 条件 |
|---|---|
| 入れ替え可 | 168 時間以上、公開者と maintainers に変化なし、provenance が上流の tag の commit と一致（前から無いものは tag と版の対応が取れる）、integrity と署名が通る、危険箇所に異常なし、木に `MAL-` なし、advisory・報道なし |
| 見送り | 168 時間未満、`INTEGRITY-MISMATCH`、署名の失敗、説明のつかない差分、木に `MAL-`、advisory・侵害報道がある |
| 要判断 | `今の版が 168 時間未満`、`公開者の変化`、`install のスクリプト`、`provenance なし`、`脆弱性が残る`、メジャー跨ぎ、消す（`ensure_installed` に入っているものは PR が要る） |

- 2-5 で当たった npm 以外のツールは、判定の列を「対象外（入れ替えの手順なし）」にして同じ表の下にまとめる。列は、ツール、種類（`gobinary`・`gemspec`・`python-pkg`）、件数（重さ別）、主なパッケージ（`stdlib@v1.24.0`、`nokogiri@1.19.3` など）。承認の選択肢には入れない
- 公開からの時間は `bash "${SKILL_DIR:?}/scripts/hours-since.sh" "$(jq -r --arg v "$cand" '.time[$v]' "$TMPDIR/npm-$m.json")"` で出す（npm の時刻はミリ秒つきだが、script が落とす）
- AskUserQuestion で承認を取る。選択肢と、要判断の multiSelect の分け方は手順 3 と同じ（「入れ替え可だけ実行」「入れ替え可と要判断を選んで実行」「やめる」）。label は `oxfmt: 0.74.0 に上げる`、`markdown-toc: 消す` のように、選んだときに起きることを書く
- 消す行のうち `ensure_installed` に入っているものは、`MasonUninstall` だけでは次の起動で戻ることを承認の前に書き、`configs/nvim/lua/plugins/` で外す PR を別に作るかも聞く。その PR は手順 4・6 と同じく dotfiles の worktree のブランチで作る

## M-4. 実行

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

## M-5. 入れ替え後の確認

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
| `trivy: command not found`、trivy の DB の取得の失敗 | `trivy-mason.txt` が空でも「脆弱性なし」と書かない。エラーを原文で伝え、表に「trivy 未実行」と書く。入れ替えの後の比べ（M-5）もできないので、入れ替えは OSV の結果だけで決めてよいか持ち主に聞く |
| `E492: Not an editor command: MasonInstall`（`MasonUninstall` も同じ） | mason.nvim が読み込まれていない。`-c "Lazy! load mason.nvim"` を前に置いてやり直す。exit が 0 でも失敗している |
| `npm error code ETARGET`（`No matching version found for <pkg>@<版> with a date before ...`） | 指定した版か依存が 7 日ルールに引っかかった。その版は見送り、M-1 の候補を取り直す。前の版が残っていることを receipt で確かめる |
| `Neovim is exiting while packages are still installing` と `Installation was aborted` | mason.nvim を読み込んだときに `ensure_installed` の入っていないツールの install が始まり、`qall` で止まった。止まったツールの名前を報告し、入れるかを持ち主に聞く。`MasonInstall` に並べたツールがこの中に出たら、先に `ensure_installed` の側が入れ始めて待たれなかったので、M-5 で receipt を見てから入れ替えをやり直す |
| `MasonUninstall` したツールが次の起動で戻る | `ensure_installed` に入っている。`configs/nvim/lua/plugins/` で外す PR を作るかを持ち主に聞く |
| `INTEGRITY-MISMATCH`、`npm audit signatures` の失敗 | 入れ替えない。どのパッケージかと、registry の値を原文で伝えて止める |
| 入れ替え後の木が事前の木と違う | 差の依存を M-2 と同じく確かめて報告する。`MAL-` があれば `MasonUninstall` を勧める |

---
name: clear-rebuildable-caches
description: ディスクが逼迫したとき、今使っておらず作り直せるキャッシュ（Docker のイメージ・ビルドキャッシュ・匿名ボリューム、uv・npm・Go・Homebrew・SwiftPM のキャッシュ、Xcode の DerivedData とシミュレータ、Terraform の .terraform など）を測り、候補を表にして承認を得てから、各ツールの公式のコマンドで消す。「キャッシュを消して」「ディスクを空けて」「容量が足りない」「ストレージを掃除」「docker の容量を減らして」等で発動する。ツールの更新には使わない（`update-local-tools` を使う）。
allowed-tools: Bash, Read, AskUserQuestion
---

# Clear Rebuildable Caches — 使っていない、作り直せるキャッシュを消す

## このスキルの目的

対象ごとに次を測り、表にして承認を得たものだけを消す。

- サイズ
- 「今使っていない」と判定した根拠（最後に使われた日、動いているプロセスや開いている herdr のペインとの照合）
- 消すコマンド（各ツールの公式のコマンド。無いものは持ち主に `!` で実行してもらう）

最後に、消す前と後の空き容量を報告する。記録は会話に表を出すだけで、ファイルには残さない。

## When to Use This Skill

発動する依頼:
- 「キャッシュを消して」「ディスクを空けて」「容量が足りない」「ストレージを掃除して」
- 「docker の容量を減らして」「uv のキャッシュを消して」など、対象を 1 つに絞った依頼。手順は同じで、対象をそれに絞る

使わないケース:
- ツールの更新 → `update-local-tools`
- 不要になった git の branch や worktree の片付け → このスキルの対象外（`.terraform` だけは対象）
- 写真・動画・ダウンロードなど、持ち主のファイルの整理

## 前提（この環境の事実）

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| PreToolUse の hook | `rm -rf` は deny。迂回（`rm -r`、`find -delete`、`trash` など）も禁止（グローバルの CLAUDE.md） | ディレクトリを直接消すしかないもの（`.terraform`、DerivedData など）は、コマンドを示して持ち主に `!` を付けて実行してもらう。Claude は Bash で消さない |
| 権限 | settings の `ask` に `Bash(brew *)`、`Bash(docker rmi *)`、`Bash(docker system prune *)` がある | brew のコマンドは 1 回にまとめる。`docker system prune` は範囲が広いので使わず、種類ごとの prune を使う |
| uv | `uv` は safe-chain のシェル関数で包まれている | キャッシュの操作はインストールではないので `command uv` で呼んでよい |
| APFS の clone | uv は既定で clonefile（copy-on-write）で venv にファイルを置く | uv のキャッシュを消しても、venv と共有しているブロックは空かない。`du` の数字より空く量が少ないことがある。前後の `df` で実際の量を報告する |
| Docker | OrbStack | イメージなどを消すと OrbStack のディスクイメージが縮み、macOS 側の空きが増える。増えたかは前後の `df` で確かめる |
| Terraform | `plugin_cache_dir` を設定していない | provider は `.terraform` ごとに実体で入っている。`terraform init` で作り直せる |

## 対象にしないもの

次は候補の表に載せない（「対象外」として表の下に 1 行ずつ理由を書くだけにする）。

- 作り直せないもの: `~/Movies`・`~/Documents` などの持ち主のファイル、アプリのデータ（`~/Library/Application Support`、`~/Library/Containers`）、`terraform.tfstate`・`terraform.tfstate.d/`・`.terraform.lock.hcl`、`~/go/bin`、`~/.local/share/uv/{python,tools}`・mise のインストール
- Docker の名前付きボリューム（compose の DB のデータなど）。中身が要るかを Claude は判定できない。持ち主が名前を挙げて頼んだときだけ、1 つずつ確認して `docker volume rm <name>` を使う
- 今使っているもの: 動いているコンテナや止まっているコンテナが使うイメージ、herdr のペインが開いているディレクトリの `.terraform`、`~/.cache/codex-runtimes/codex-primary-runtime`、動いているアプリのキャッシュ（`~/Library/Caches/com.openai.codex` など）
- 動いている Claude Code・codex・MCP サーバー（`npm exec` で動くもの）が使っている npx のキャッシュ
- Time Machine のローカルスナップショット、iCloud のファイル、システムの領域

## 「使っていない」の基準

- 既定は「最後に使われてから 14 日以上」。持ち主が日数を指定したらそれに従う
- 最後に使われた日が取れないものは、ツール自身の「未使用」の判定（Docker の「どのコンテナからも参照されていない」、uv の `prune` など）に任せ、表にその旨を書く
- herdr のペインが開いているディレクトリは「使用中」。一覧は次で取る

```bash
herdr api snapshot | jq -r '[.. | objects | (.cwd?, .foreground_cwd?) | strings] | unique[]' > "$TMPDIR/herdr-cwd.txt"
```

## Execution Process

### 手順 1: 測る（読み取りのみ）

最初に基準時刻と空き容量を取って表の上に書く。

```bash
date '+%Y-%m-%d %H:%M %Z'
df -h /System/Volumes/Data | tail -1
```

以下、対象ごとに「測る」「使用中の判定」を行う。消すコマンドは手順 4 の表にまとめてある。

#### Docker（OrbStack）

```bash
docker system df
docker ps -aq | xargs docker inspect --format '{{.Image}}' | sort -u > "$TMPDIR/used-img.txt"
docker image ls --no-trunc --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}' | grep -vFf "$TMPDIR/used-img.txt"
docker buildx du --verbose | grep -E '^(ID|Size|Last used|Description):'
docker volume ls --filter dangling=true --format '{{.Name}}\t{{.Labels}}'
```

- イメージ: どのコンテナ（止まっているものも含む）からも参照されていないものが候補。`docker image prune -a` はちょうどそれを消す
- ビルドキャッシュ: `Last used` が 14 日以上前のものが候補。`docker builder prune -a --filter until=336h` で消える量は、`Last used` が 14 日以上前の行の `Size` の合計
- ボリューム: ラベルに `com.docker.volume.anonymous` があるものが匿名ボリューム。`docker volume prune`（`-a` なし）は、どのコンテナも使っていない匿名ボリュームだけを消す。名前付きは対象外
- `buildx_buildkit_*_state` は docker-container driver の builder の状態。builder ごと消すことになるので対象外

#### uv

```bash
command uv cache dir
command uv cache size --human
```

- `uv cache prune` は今のどの環境からも参照されていないエントリを消す。`uv cache clean` は全部を消し、次の `uv sync` などで取り直す。既定の候補は `prune`、`clean` は `要判断`
- 両方とも、ほかの uv が動いているとロックを待つ。`--force` は付けない

#### npm

```bash
du -sh ~/.npm/_cacache ~/.npm/_npx
npm cache npx ls
pgrep -fl 'npm exec|npx '
```

- `_cacache` は `npm cache clean --force` で消す（npm は `--force` を付けないと断る）。消しても次の install で取り直す
- `_npx` は entry ごとに `npm cache npx rm <key>`。`pgrep` に出た package（動いている MCP サーバーなど）と一致する entry は使用中として除く。`(unknown)` の entry は `npm cache npx info <key>` で package を確かめ、分からなければ除く

#### Go

```bash
go env GOCACHE GOMODCACHE
du -sh "$(go env GOCACHE)" "$(go env GOMODCACHE)"
```

- build cache（`GOCACHE`）は `go clean -cache`。次の build で作り直す。go は 5 日使われていないエントリを自分で消すので、残っている量は最近の build の分
- module cache（`GOMODCACHE`）は `go clean -modcache`。全モジュールを取り直すことになるので `要判断`。`pgrep -x gopls` が出たら、エディタが一時的に壊れることを表に書く

#### Homebrew

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew cleanup -n --prune=all 2>&1 | tail -1
```

- `brew cleanup --prune=all` は、ダウンロードのキャッシュ全部と、古い版の formula・cask を消す。入っている版には触れない

#### SwiftPM・Xcode

```bash
du -sh ~/Library/Caches/org.swift.swiftpm
pgrep -x Xcode
du -sh ~/Library/Developer/Xcode/DerivedData/*
for p in ~/Library/Developer/Xcode/DerivedData/*/info.plist; do echo "$(plutil -extract LastAccessedDate raw "$p") $(plutil -extract WorkspacePath raw "$p") $(dirname "$p")"; done
xcrun simctl list devices -j | jq -r '.devices | to_entries[] | .key as $r | .value[] | "\(.udid)\t\(.name)\t\($r|sub(".*SimRuntime.";""))\t\(.state)\tavail=\(.isAvailable)\t\(.lastBootedAt // "never")"'
du -sh ~/Library/Developer/CoreSimulator/Devices/* | sort -h | tail -5
xcrun simctl runtime list
```

- SwiftPM: `swift package purge-cache` が公式。次の resolve で取り直す
- DerivedData: Xcode が動いていないこと（`pgrep -x Xcode` が空）が前提。プロジェクトごとの `LastAccessedDate` が 14 日以上前か、`WorkspacePath` がもう無いものが候補。`*.noindex`（ModuleCache など）は全プロジェクトの共有なので、Xcode が動いていなければ候補。公式の CLI が無いので持ち主に `!` で消してもらう
- シミュレータ: `isAvailable` が false のものは `xcrun simctl delete unavailable`。使えるものでも `lastBootedAt` が 14 日以上前で大きいものは、`xcrun simctl delete <udid>` の候補にする（シミュレータに入れたアプリのデータが消えるので `要判断`）。Xcode が必要なら作り直す
- runtime: どの device も使っていない runtime だけを `xcrun simctl runtime delete <id>` の候補にする

#### Terraform の `.terraform`

```bash
find ~/ghq ~/.herdr/worktrees -type d -name .terraform -prune 2>/dev/null > "$TMPDIR/tfdirs.txt"
while IFS= read -r d; do
  s=$(du -sk "$d" | cut -f1)
  t=$(find "$d" -maxdepth 2 \( -name terraform.tfstate -o -name modules.json \) -exec stat -f %m {} + 2>/dev/null | sort -n | tail -1)
  [ -z "$t" ] && t=$(stat -f %m "$d")
  ws=$(cat "$d/environment" 2>/dev/null)
  printf '%s\t%s\t%s\t%s\n' "$((s / 1024))MB" "$(( ($(date +%s) - t) / 86400 ))d" "${ws:-default}" "$d"
done < "$TMPDIR/tfdirs.txt" | sort -rn
pgrep -x terraform
```

- 2 列目は最後の `terraform init` からの日数（`.terraform/terraform.tfstate` は backend の設定で、state ではない）。14 日以上が候補
- 使用中として除くもの: `herdr-cwd.txt` のどれかが `.terraform` の親ディレクトリ以下にあるもの、`.terraform` が herdr のペインが開いている worktree の中にあるもの、`pgrep -x terraform` が出たら `lsof -p <pid> -a -d cwd` の cwd の下にあるもの
- 3 列目が `default` でないものは、`terraform workspace select` を作り直しのあとにやり直す必要がある。表にその workspace 名を書く
- `.terraform.lock.hcl` と state は `.terraform` の外にあるので消えない。provider は `terraform init` で lock と同じ版が入り直す
- 公式の CLI が無いので持ち主に `!` で消してもらう

#### そのほかのキャッシュ

```bash
du -sh ~/.cache/* ~/Library/Caches/* 2>/dev/null | sort -h | tail -15
ls -la ~/.cache/codex-runtimes
lsof +D ~/.cache/codex-runtimes 2>/dev/null | awk 'NR>1 {print $1, $9}' | sort -u
ls ~/Library/Caches/JetBrains
```

| 対象 | 判定と消し方 |
|---|---|
| `~/.cache/codex-runtimes/codex-runtime-install-*` | インストールの途中で残ったもの（`node-runtime.tar.xz` と `payload` だけ）。作られてから 1 日以上たち、`lsof` に出ないものが候補。持ち主に `!` で消してもらう。`codex-primary-runtime` は対象外 |
| `~/Library/Caches/JetBrains/<製品><版>` | 製品ごとに最新の版のディレクトリを残し、古い版を候補にする。IDE の「Delete leftover IDE directories」でも消せる。CLI で消すなら持ち主に `!` で |
| Spotify・Chrome などアプリのキャッシュ | アプリの設定から消してもらう（Spotify は「設定 → ストレージ → キャッシュを消去」、Chrome は「閲覧履歴データの削除 → キャッシュされた画像とファイル」）。表には手順だけを書く |
| 上のどれにも当たらない大きいもの | 中身と作り直し方が分かるまで対象外。表の下に「未調査」として載せる |

### 手順 2: 表を示す

基準時刻と今の空き容量を表の上に書き、次の列で表を出す。

| # | 対象 | サイズ | 使っていない根拠 | 消すコマンド | 実行する人 | 印 | 判定 |
|---|---|---|---|---|---|---|---|

- 種類（Docker・言語のキャッシュ・Xcode・Terraform・そのほか）ごとに見出しで分ける。`.terraform` は 1 行ずつ載せる（多ければサイズの大きい順に並べ、14 日未満のものは件数と合計だけを書く）
- 実行する人は `Claude`（公式のコマンド）か `持ち主（!）`（ディレクトリを直接消すもの）か `持ち主（アプリ）`
- 印: `要判断`（取り直しに時間がかかる、アプリのデータが消える、など）
- 判定: `候補`（根拠がそろった）、`要判断`、`対象外`（理由を書く）
- 表の下に、候補を全部消したときに空く見込みの合計を書く。uv は clone のぶん少なくなりうると書き添える

### 手順 3: 承認を得る

AskUserQuestion で承認を取る。選択肢は「候補だけ実行」「候補と要判断を選んで実行」「やめる」。要判断の項目は multiSelect で 1 つずつ選べるようにする。`.terraform` が多いときは、リポジトリごとにまとめて選べるようにする。

### 手順 4: 承認分だけ消す

Claude が実行するものを 1 つずつ実行し、そのあとで持ち主に `!` で実行してもらうものを示す。

| 対象 | コマンド |
|---|---|
| Docker のイメージ | `docker image prune -a -f`（どのコンテナからも参照されていないイメージを全部消す。一部だけ承認されたら `docker image rm <id> ...`） |
| Docker のビルドキャッシュ | `docker builder prune -a -f --filter until=336h` |
| Docker の匿名ボリューム | `docker volume prune -f`（`-a` を付けない） |
| uv | `command uv cache prune`（`clean` が承認されたら `command uv cache clean`） |
| npm | `npm cache clean --force`、`npm cache npx rm <key> ...` |
| Go | `go clean -cache`、承認されたら `go clean -modcache` |
| Homebrew | `HOMEBREW_NO_AUTO_UPDATE=1 brew cleanup --prune=all` |
| SwiftPM | `swift package purge-cache` |
| シミュレータ | `xcrun simctl delete unavailable`、`xcrun simctl delete <udid> ...`、`xcrun simctl runtime delete <id>` |
| `.terraform`・DerivedData・codex-runtimes の残り・JetBrains の古い版 | 持ち主に `!` で実行してもらう（下を参照） |

- 実行の直前に、使用中の判定（`docker ps -a`、`pgrep -x Xcode`、`pgrep -x terraform`、herdr の cwd）を取り直す。表を出したときと変わっていたら、その対象を外して報告する
- どれかが失敗したら、その場で止めてエラーを原文のまま報告する。残りは実行しない

#### 持ち主に `!` で実行してもらうもの

承認されたパスを、1 行 1 パスのコマンドにして示す。パスは単一引用符で囲む。Claude は Bash で実行しない（hook の deny を迂回しない）。

```text
! rm -rf -- '/Users/<user>/ghq/github.com/<org>/<repo>/envs/<env>/.terraform'
! rm -rf -- '/Users/<user>/Library/Developer/Xcode/DerivedData/<Project>-<hash>'
```

- 1 つの `!` に並べる行数が多いときは、リポジトリごとなどに分けて示す
- 実行してもらったら、`ls -d <path>` で消えたことを確かめる。消えていないものは報告に書く
- `.terraform` の workspace が `default` でなかったものは、作り直すときに `terraform workspace select <name>` が要ると伝える

### 手順 5: 報告

```bash
df -h /System/Volumes/Data | tail -1
docker system df
```

次を表で報告する。

- 前後の空き容量と、その差
- 消したもの（対象・コマンド・見込みのサイズ）
- 見送ったもの・対象外にしたものとその理由
- 失敗したもの

差が見込みよりずっと小さいときは、`tmutil listlocalsnapshots /` でローカルスナップショットが残っていないか見て報告する（スナップショットは消さない）。

`$TMPDIR` に作ったファイル（`used-img.txt`、`tfdirs.txt`、`herdr-cwd.txt`）は最後に `rm` で 1 つずつ消す。

## 守ること

- 手順 1〜3 は読み取りだけ。承認の前に prune・clean・delete を実行しない
- 承認の範囲を広げない。承認後に状況が変わったら（コンテナが起動した、ペインが開いた）その対象を外す
- `rm -rf` などでディレクトリを消す操作は Claude が実行しない。hook に deny されたら、別のコマンドで同じことをしない
- `docker system prune`、`docker volume prune -a`、`uv cache clean --force` は使わない

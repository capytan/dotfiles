---
name: update-local-tools
description: uv・mise・Homebrew のローカルツールを、サプライチェーン侵害の事前確認（公開から 7 日の見送り、advisory と報道、署名、差分コード）を挟んでから更新する。候補を表にして承認を得てから実行する。「ツール更新して」「ローカルツールを更新」「brew/mise/uv を更新」「brew upgrade して」「mise を最新に」「uv self update して」等で発動する。プロジェクトの依存（package.json、pyproject.toml、Gemfile など）の更新には使わない。
allowed-tools: Bash, Read, WebSearch, WebFetch, AskUserQuestion, Agent
---

# Update Local Tools — 侵害確認つきでローカルツールを更新する

## このスキルの目的

uv・mise・Homebrew で入れたツールを更新する前に、次の 4 つを候補ごとに確かめる。

- 公開直後の版を避ける（公開から 7 日未満は見送り）
- 侵害報道と advisory を調べる
- 署名・attestation・checksum を検証する
- 差分コードの危険箇所を見る

結果を表で示し、承認を得たものだけ更新する。記録は会話に表を出すだけで、ファイルには残さない。

## When to Use This Skill

発動する依頼:
- 「ツール更新して」「ローカルツールを更新」「brew/mise/uv を更新」
- 「brew upgrade して」「mise を最新に」「uv self update して」「uv tool を直して」

使わないケース:
- プロジェクトの依存更新（`npm update`、`uv lock --upgrade`、`bundle update` など）→ このスキルの対象外
- 特定ツール 1 つだけの更新を頼まれた場合も手順は同じ。対象をそのツールに絞って回す

## 前提（この環境の事実）

| 項目 | 事実 | 手順への影響 |
|---|---|---|
| 権限 | settings の `ask` に `Bash(brew *)` と `Bash(mise *)` がある | 読み取りの `brew outdated` や `mise outdated` でも毎回確認が出る。コマンドを 1 回にまとめて回数を減らす |
| uv | `uv` は safe-chain のシェル関数（`wrapSafeChainCommand`）で包まれている。本体は `~/.local/bin/uv` | 更新系（`uv tool install` など）は `uv` で呼び、safe-chain を通す。`command -v safe-chain` が空なら更新系を止めて報告する。読み取りは `command uv` でよい |
| mise のインストール経路 | 今は `~/.local/bin/mise`（standalone）。brew 経由だと `mise self-update` は使えない | 手順 1 で経路を判定して分岐する |
| mise の検証設定 | aqua の cosign/slsa/github_attestations/minisign、github の attestations/slsa、`node.verify` が有効 | mise ツールの署名は mise がインストール時に検証する。表には「mise が検証」と書く |
| mise config | `~/.config/mise/config.toml` は `~/dotfiles/configs/mise/config.toml` への symlink。全ツールを完全な版で固定している | `mise outdated` は `--bump` を付けないと何も出ない。書き込みは `mise use -g` で行い、dotfiles に commit する |
| uv tool の Python | mise の Python（例 `~/.local/share/mise/installs/python/3.13.3`）で入れた uv tool は、その Python が消えると "environment not found" で壊れる | uv tool は `--managed-python --python 3.14` を付けて uv が管理する安定版の Python で入れ、mise の Python から切り離す。参照先は `$(uv tool dir)/X/pyvenv.cfg` の `home` で分かる |

## 版の上げ方のルール

| 対象 | ルール |
|---|---|
| 見送り日数 | 公開から 7 日未満の版は候補にしない。7 日以上の版のうち最新を候補にする |
| 修正版の例外 | 現行版に advisory があり、修正版が 7 日未満なら、候補に残して表で目立たせ（印 `要判断`）、承認時に個別に決める |
| mise | メジャー内に留める。python・ruby は minor もメジャー扱いで patch のみ。0.x 系は先頭番号（`0`）だけをメジャーと見なし、minor も上げる |
| mise の例外: gcloud | 版ごとにメジャー番号が上がる（`588.0.0` → `589.0.0`）ので、メジャー内のルールを外して最新まで上げる。7 日ルールと侵害確認はほかと同じにかける |
| brew・uv tool | メジャー跨ぎは表で印（`メジャー跨ぎ`）を付け、既定は除外。承認時に選べるようにする。0.x の扱いは mise と同じ |
| 候補の条件 | 候補は現在の版より新しいこと。7 日ルールで選んだ版が現在以下なら「候補なし」 |
| cask・formula | brew は最新版しか入れられない。最新が 7 日未満なら古い版に下げる手段はないので見送る |

## Execution Process

### 手順 1: 候補の収集（読み取りのみ）

今日の日付を `date -u +%Y-%m-%dT%H:%M:%SZ` で取り、経過日数の基準にする。

#### uv 本体

```bash
command uv --version
command uv self update --dry-run
gh api 'repos/astral-sh/uv/releases?per_page=10' --jq '.[] | select(.prerelease|not) | "\(.tag_name) \(.published_at)"'
```

`uv self update` には `--exclude-newer` が無い。公開日は GitHub Release で確かめ、7 日以上たった最新の版を候補にする。

#### uv tool

```bash
command uv tool list --outdated --show-version-specifiers
command uv tool dir
```

- `warning: Tool \`X\` environment not found` が出た tool は「壊れている」として候補に入れる。今の版は `$(uv tool dir)/X/lib/python*/site-packages/` の `*.dist-info` 名から、使っている index は `$(uv tool dir)/X/uv-receipt.toml` の `[tool.options]` から読む
- 候補版は PyPI の公開日で決める（`--outdated` は 7 日未満の版も出すため）
- `$(uv tool dir)/X/pyvenv.cfg` の `home` が uv の Python（`$(command uv python dir)` の下）でない tool は、印 `mise の Python` を付けて表に出す。手順 4 で `--managed-python` を付けて入れ直す

```bash
curl -s https://pypi.org/pypi/<name>/json | jq -r '.releases | to_entries | map(select(.value|length>0) | {v:.key, t:(.value|map(.upload_time_iso_8601)|min)}) | sort_by(.t) | .[-5:][] | "\(.v) \(.t)"'
```

#### mise 本体

```bash
mise --version
mise doctor | grep -E '^(version|self_update_available):'
command -v mise; brew --prefix
gh api 'repos/jdx/mise/releases?per_page=10' --jq '.[] | select(.prerelease|not) | "\(.tag_name) \(.published_at)"'
```

- `self_update_available: yes` で、パスが `$(brew --prefix)` の下でなければ standalone。`mise self-update` で更新する
- brew 経由なら mise は brew の formula として扱い、下の Homebrew の流れに入れる

#### mise のツール

```bash
mise outdated --global --bump -J
```

出たツールごとに、版の上げ方のルールに沿ったメジャー内の候補を取る。

```bash
mise latest node@24 --minimum-release-age 7d      # メジャー内（node 24.x）
mise latest python@3.14 --minimum-release-age 7d  # python・ruby は minor 内
mise latest tflint@0 --minimum-release-age 7d     # 0.x は先頭番号の 0 内
mise latest gcloud --minimum-release-age 7d       # gcloud は例外で範囲を付けない
mise ls-remote node@24 -J | jq -r '.[-5:][] | "\(.version) \(.created_at)"'   # 公開日の確認
```

`--minimum-release-age` は範囲指定にだけ効き、固定版の `--bump` には効かない。だから `mise upgrade --bump` は使わず、上で選んだ版を手順 4 で `mise use -g` に渡す。`bump` 列がメジャーを跨ぐものは「メジャー跨ぎ、対象外」として表に参考で載せる（gcloud は除く）。

#### Homebrew

最初に `brew update` でメタデータをそろえる（ツールは更新しない）。以降は `HOMEBREW_NO_AUTO_UPDATE=1` を付け、確認した版と実際に入る版がずれないようにする。

```bash
brew update
HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --json=v2 > "$TMPDIR/brew-outdated.json"
brew info --json=v2 --installed | jq -r '.formulae[] | select(any(.installed[]; .installed_on_request)) | .full_name' > "$TMPDIR/brew-onreq.txt"
jq -r '.formulae[].name' "$TMPDIR/brew-outdated.json" | grep -xFf "$TMPDIR/brew-onreq.txt"    # 自分で入れた formula
jq -r '.casks[] | "\(.name) \(.installed_versions|join(",")) -> \(.current_version)"' "$TMPDIR/brew-outdated.json"
HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --vulnerable <自分で入れた outdated formula ...>    # 現行版に既知の脆弱性があるもの
```

- `--vulnerable` は名前を付けずに呼ぶと、走査できない formula が 1 つでもあると `Error: Incomplete vulnerability scan for: ...` で止まる。候補の名前を渡す。候補自体が走査できなければ表の advisory 列に「OSV 走査不可」と書く

- `brew list --installed-on-request` は tap の formula を短い名前（`supabase`）で返し、`brew outdated` は完全名（`supabase/tap/supabase`）で返すので突き合わせに使わない。上の `brew info --json=v2` の `full_name` で突き合わせる
- 巻き込まれる依存は dry-run で洗い出す。対象に挙げていないパッケージが出たら、それが巻き込み依存

```bash
HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --dry-run --formula <自分で入れた outdated formula ...>
```

### 手順 2: 侵害の事前確認（候補ごと）

2-1 と 2-2 は全候補で行う。2-1 で 7 日未満と分かった候補は、2-2 で現行版に advisory がなければ見送りが決まるので、2-3・2-4 を省く。現行版に advisory があれば修正版の例外として 2-3・2-4 も行う。

候補が 5 件を超えたら、ツールごとにサブエージェント（Agent）へ分けて並列に回す。各エージェントには下の 4 項目と結果の書式（表の 1 行）を渡す。

#### 2-1. 公開日

| 対象 | 取り方 |
|---|---|
| uv・mise 本体 | 手順 1 の GitHub Release の `published_at` |
| uv tool | PyPI の `upload_time_iso_8601` |
| mise ツール | `mise ls-remote <tool>@<prefix> -J` の `created_at` |
| brew formula・cask | tap の commit 日。パスは `brew info --json=v2 <name>` の `.ruby_source_path`、repo は `.tap`（`homebrew/core` → `Homebrew/homebrew-core`、`<o>/<r>` → `<o>/homebrew-<r>`） |

```bash
gh api 'repos/Homebrew/homebrew-core/commits?path=Formula/p/pipx.rb&per_page=1' --jq '.[0] | "\(.commit.committer.date) \(.commit.message|split("\n")[0])"'
```

#### 2-2. advisory と報道

```bash
gh api 'repos/<o>/<r>/security-advisories?per_page=10' --jq '.[] | "\(.ghsa_id) \(.severity) \(.published_at) \(.vulnerabilities|map("\(.vulnerable_version_range) patched=\(.patched_versions)")|join(";"))"'
gh api 'advisories?ecosystem=pip&affects=<name>&per_page=10' --jq '.[] | "\(.ghsa_id) \(.severity) \(.summary)"'
```

- 現在の版・候補の版がそれぞれ `vulnerable_version_range` に入るかを見る。現行版が影響を受けるなら修正版の例外ルールを適用する
- ecosystem は uv tool が `pip`、mise の npm backend が `npm`
- WebSearch で `<tool> <version> compromised OR malicious OR "supply chain"` を調べる。出典が 1 つしかない主張や、版の合わない記事は「未確認」として表の注記に書く

#### 2-3. 署名・checksum

| 対象 | 検証 |
|---|---|
| uv 本体 | 一時ディレクトリに成果物を落として `gh attestation verify <file> --repo astral-sh/uv`。成功すれば signer は `astral-sh/uv/.github/workflows/release.yml` |
| mise 本体 | `mise self-update` が置き換え前に署名を検証する。追加で確かめるなら uv と同じく `gh attestation verify <file> --repo jdx/mise` |
| mise ツール | mise がインストール時に検証（aqua・github backend の attestation/slsa/cosign/minisign、`node.verify`）。表には「mise が検証」 |
| uv tool | PyPI の provenance を `curl -s -H 'Accept: application/vnd.pypi.integrity.v1+json' https://pypi.org/integrity/<name>/<version>/<file>/provenance` で取る。404 なら「provenance なし（PyPI の hash のみ）」 |
| brew formula | 手順 4 で `HOMEBREW_VERIFY_ATTESTATIONS=1` を付ける（homebrew/core と対応 tap の bottle）。それ以外の tap は「formula の sha256 のみ」 |
| brew cask | cask に書かれた sha256 を brew が照合する。`sha256 :no_check` の cask は表で目立たせる |

一時ディレクトリは `mktemp -d` で作り、検証が終わったらファイルを消してから `rmdir` する。落とした成果物は実行しない。

#### 2-4. コード確認（GitHub compare）

全候補で現在の版から候補の版までの compare を取り、危険箇所に絞って読む。

```bash
gh api 'repos/<o>/<r>/compare/<cur_tag>...<new_tag>?per_page=100' --paginate --jq '.files[].filename' | sort -u
```

見る箇所:
- `.github/workflows/` のうち release・publish・sign・build 系（`uses:` が SHA 固定か、外部からの `curl | sh`、`secrets.` の新しい使い方）
- install/build スクリプト（`build.rs`、`setup.py`、`install*.sh`、`Makefile`、npm の `postinstall`）
- 依存の追加（`Cargo.toml`、`pyproject.toml`、`package.json`、`go.mod` の新しい依存）
- 難読化・base64（長い base64 文字列、`eval`、`exec(`、`\x` の羅列）

```bash
gh api 'repos/<o>/<r>/compare/<cur>...<new>?per_page=100' --paginate --jq '.files[] | select(.filename|test("^\\.github/workflows/(release|publish|sign|build)")) | "=== \(.filename)\n\(.patch // "(no patch)")"' | grep -E '^===|^\+.*(curl|wget|base64|eval|uses: |secrets\.|https?://)'
```

- 差分が大きい（数千 commit、300 ファイル超）ときは上の危険箇所だけを読み、表に「危険箇所のみ確認」と書く
- ソース非公開（1password-cli、cursor など）や upstream の repo が分からないものは「コード確認不可」と書く
- brew の revision だけの更新（`2.1.1` → `2.1.1_1`）は upstream のコードが同じなので、tap の formula の差分だけを見る

#### 判定

| 判定 | 条件 |
|---|---|
| 更新可 | 7 日以上、候補版に advisory なし、報道なし、署名の検証が通る（または仕組み上検証される）、危険箇所に異常なし |
| 見送り | 7 日未満、候補版に advisory がある、侵害報道がある、署名が通らない、危険箇所に説明のつかない変更がある |
| 要判断 | 修正版の例外、メジャー跨ぎ、壊れた uv tool の直し、コード確認不可の cask |

巻き込み依存が「見送り」なら、その親も「見送り」にする。

### 手順 3: 表を示して承認を得る

次の列で表を出す。

| ツール | 現在 → 候補 | 経過日数 | advisory | 署名 | コード確認 | 印 | 判定 |
|---|---|---|---|---|---|---|---|

- 種類（uv 本体・uv tool・mise 本体・mise ツール・brew formula・brew cask・巻き込み依存）ごとに見出しで分ける
- 候補なしのツールは載せない。見送りは理由を判定の列に書く
- 表のあとに AskUserQuestion で承認を取る。選択肢は「更新可だけ実行」「更新可と要判断を選んで実行」「やめる」。要判断の項目は multiSelect で 1 つずつ選べるようにする

### 手順 4: 承認分だけ更新する

順序と失敗時の扱い:
- uv 本体 → mise 本体 → mise ツール → brew → uv tool の順に 1 つずつ実行する
- uv tool を最後にするのは、mise の Python を参照したままの tool が mise の更新で壊れることがあるため。mise の python を更新したら、手順 1 の uv tool の一覧を取り直し、壊れたものを表に足して承認を取り直す
- どれかが失敗したら、その場で止めて報告する。残りは実行しない

| 対象 | コマンド |
|---|---|
| uv 本体 | `uv self update <version>` |
| mise 本体（standalone） | `mise self-update -y <version>` |
| mise ツール | `mise use -g <tool>@<version>`（ツールごと。config の版も書き換わる） |
| brew formula | `HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_VERIFY_ATTESTATIONS=1 brew upgrade --formula <names>` |
| brew cask | `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask <names>` |
| uv tool の前準備（安定版の Python） | 下の「uv tool の Python をそろえる」を参照 |
| uv tool（メジャー内の更新） | `uv tool upgrade <name> --managed-python --python 3.14 --exclude-newer "7 days"` |
| uv tool（メジャー内に固定したい） | `uv tool install '<name>>=<cur>,<<next_major>' --managed-python --python 3.14 --exclude-newer "7 days"` |
| 壊れた uv tool、印 `mise の Python` の uv tool | `uv tool install <name> --reinstall --managed-python --python 3.14 --exclude-newer "7 days"`。receipt に index があれば `--default-index <url>` を付ける。メジャー跨ぎを避けるなら上の範囲指定を使う |

- uv tool は `uv`（safe-chain 経由）で呼ぶ。`command uv` にしない
- `--managed-python` は uv が管理する Python だけを使い、mise の Python を使わない。実行後に `$(uv tool dir)/<name>/pyvenv.cfg` の `home` が `$(command uv python dir)` の下の安定版（alpha・beta・rc でない）になったことを確かめる

#### uv tool の Python をそろえる

uv は条件に合う pre-release（例 `cpython-3.14.0a6`）が入っていると、安定版を取りに行かずにそれを使う（uv のドキュメント「Python versions」）。`uv python install 3.14` も、条件に合う版が入っていれば何もせずに終わる。だから uv tool を入れる前に、安定版を版まで指定して入れる。

```bash
command uv python list 3.14 --managed-python        # 入っている版と、取得できる安定版（<download available>）を見る
command uv python find 3.14 --managed-python        # 今 3.14 で選ばれる版
```

- `find` が pre-release を返したら、`list` に出る最新の安定版を `uv python install 3.14.<patch>` で入れる（この操作も承認の範囲に入れる）。入れたあと `find` が安定版を返すことを確かめる。安定版と pre-release が両方あれば、uv は安定版を選ぶ
- `find` が安定版を返すなら、前準備は要らない
- mise の Python を参照したままの tool には `uv tool upgrade` を使わず、`--reinstall` で入れ直す（環境を作り直して参照先を切り替えるため）
- `--exclude-newer "7 days"` は推移依存にも効く。推移依存の個別確認はしない
- mise の `npm:` と `pypi:` backend の推移依存は、mise の `minimum_release_age`（config の tool option で `7d`）で守る。個別確認はしない。npm: は mise 内蔵の aube が、pypi: は uv の `--exclude-newer` が依存の解決にこの cutoff をかける（mise の公式ドキュメント）。ツール本体の固定版には効かないので、本体は手順 1〜3 で確かめる
- `mise use -g` は tool option（`minimum_release_age`、azure-cli の `dependency_prereleases`・`with`）を残したまま `version` だけを書き換える。commit 前に `git -C ~/dotfiles diff configs/mise/config.toml` で、変わったのが版だけであることを確かめる

### 手順 5: mise config の commit と報告

1. `git -C ~/dotfiles status --short` で `configs/mise/config.toml` に差分があるか見る
2. 差分があり、ほかに staged の変更がなければ `configs/mise/config.toml` だけを stage して commit する。ほかに staged の変更があれば commit せずに報告する

```bash
git -C ~/dotfiles add configs/mise/config.toml
git -C ~/dotfiles commit -m "chore(mise): ツールバージョンを更新"
```

push はしない。

3. 更新したもの、見送ったものとその理由、失敗したものを表で報告する。commit したならその hash も書く

## エラー処理

| 状況 | 対応 |
|---|---|
| `gh api` が rate limit や認証エラー | `gh auth status` を確かめるよう伝えて止める。公開日・advisory が取れないまま判定しない |
| PyPI・GitHub で公開日が取れない | その候補は「見送り（公開日不明）」 |
| `safe-chain` が見つからない | uv tool の更新を止めて報告する |
| `mise self-update` が brew 管理を理由に断る | mise を brew の流れに移し、`brew upgrade --formula mise` を候補として表を出し直す |
| 更新コマンドの失敗 | エラーを原文のまま伝え、以降の更新を止める |

## 守ること

- 手順 1〜3 は読み取りだけ。承認の前に更新系コマンド（`uv self update`、`uv tool install/upgrade`、`mise self-update`、`mise use`、`mise upgrade`、`brew upgrade`）を実行しない
- 承認の範囲を広げない。承認後に版が変わった（`brew update` をやり直した等）ら表を作り直す
- 落とした成果物は検証だけに使い、実行しない

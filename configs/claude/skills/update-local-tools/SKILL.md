---
name: update-local-tools
description: uv・mise・Homebrew のローカルツールと zeno.zsh を、サプライチェーン侵害の事前確認（公開から 7 日の見送り、advisory と報道、署名、差分コード）を挟んでから更新する。候補を表にして承認を得てから実行する。「ツール更新して」「ローカルツールを更新」「brew/mise/uv を更新」「brew upgrade して」「mise を最新に」「uv self update して」「zeno を更新」等で発動する。プロジェクトの依存（package.json、pyproject.toml、Gemfile など）の更新には使わない。
allowed-tools: Bash, Read, WebSearch, WebFetch, AskUserQuestion, Agent
---

# Update Local Tools — 侵害確認つきでローカルツールを更新する

## このスキルの目的

uv・mise・Homebrew で入れたツールと zeno.zsh を更新する前に、次の 4 つを候補ごとに確かめる。

- 公開直後の版を避ける（公開から 168 時間未満は見送り。以下「7 日ルール」）
- 侵害報道と advisory を調べる
- 署名・attestation・checksum を検証する
- 差分コードの危険箇所を見る

結果を表で示し、承認を得たものだけ更新する。記録は会話に表を出すだけで、ファイルには残さない。

## 守ること

- 手順 1〜3 は読み取りだけ。承認の前に更新系コマンド（`uv self update`、`uv tool install/upgrade`、`mise self-update`、`mise use`、`mise upgrade`、`brew upgrade`、zeno.zsh の `git checkout`）を実行しない
- 承認の範囲を広げない。承認後に版が変わった（`brew update` をやり直した等）ら表を作り直す
- 落とした成果物は検証だけに使い、実行しない
- `~/dotfiles` の本体のブランチを切り替えず（main のまま）、本体で commit しない。mise config と `install.sh` の変更は、origin/main から切った worktree のブランチに commit し、PR にする。merge はしない

## When to Use This Skill

発動する依頼:
- 「ツール更新して」「ローカルツールを更新」「brew/mise/uv を更新」
- 「brew upgrade して」「mise を最新に」「uv self update して」「uv tool を直して」「zeno を更新」

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
| mise config | `~/.config/mise/config.toml` は `~/dotfiles/configs/mise/config.toml` への symlink。全ツールを完全な版で固定している | `mise outdated` は `--bump` を付けないと何も出ない |
| global の config の差し替え | `MISE_GLOBAL_CONFIG_FILE` は global の config を 1 つのファイルに置き換え、`mise use -g` はそのファイルに書く。ただし `$HOME` の下を cwd にすると、`~/.config/mise/config.toml` は project の config として読まれ、global より強い（mise の doc「Configuration」） | `mise use -g` は cwd を `/` にし、`MISE_GLOBAL_CONFIG_FILE` を worktree の config に向けて呼び、その変更を PR にする。ツールはその場で入るが、本体の config は古い版のままなので、新しい版が効くのは merge のあとに本体を pull してから |
| uv tool の Python | mise の Python（例 `~/.local/share/mise/installs/python/3.13.3`）で入れた uv tool は、その Python が消えると "environment not found" で壊れる | uv tool は `--managed-python --python 3.14` を付けて uv が管理する安定版の Python で入れ、mise の Python から切り離す。参照先は `$(uv tool dir)/X/pyvenv.cfg` の `home` で分かる |
| zeno.zsh | `~/.local/share/zeno` の git clone。上流に tag も release も無いので、`~/dotfiles/install.sh` の `ZENO_COMMIT`（40 桁の sha）で固定している。`install.sh` は clone と、その commit への checkout しかしない | 更新は checkout と、worktree の `install.sh` の `ZENO_COMMIT` の書き換えで行い、PR にする。merge までに本体の `install.sh` を実行すると、古い commit に戻る |

## 版の上げ方のルール

| 対象 | ルール |
|---|---|
| 見送り日数 | 公開時刻から今までの経過を時間単位で計算し、168 時間（7 日）未満の版は候補にしない。168 時間以上の版のうち最新を候補にする。日付の差で数えない（10-13 15:38Z 公開の版は 10-20 02:50Z の時点で 155 時間なので見送り） |
| 修正版の例外 | 現行版に advisory があり、修正版が 168 時間未満なら、候補に残して表で目立たせ（印 `要判断`）、承認時に個別に決める |
| mise | メジャー内に留める。python・ruby は minor もメジャー扱いで patch のみ。0.x 系は先頭番号（`0`）だけをメジャーと見なし、minor も上げる |
| mise の例外: gcloud | 版ごとにメジャー番号が上がる（`588.0.0` → `589.0.0`）ので、メジャー内のルールを外して最新まで上げる。7 日ルールと侵害確認はほかと同じにかける |
| brew・uv tool | メジャー跨ぎは表で印（`メジャー跨ぎ`）を付け、既定は除外。承認時に選べるようにする。0.x の扱いは mise と同じ |
| 候補の条件 | 候補は現在の版より新しいこと。7 日ルールで選んだ版が現在以下なら「候補なし」 |
| cask・formula | brew は最新版しか入れられない。最新が 168 時間未満なら古い版に下げる手段はないので見送る |
| zeno.zsh | 公開時刻は GitHub の repository activity API（`GET /repos/{o}/{r}/activity`）の `timestamp`。main に push・PR の merge が届いた、GitHub 側の時刻で、作者が書き換えられる commit の日時は使わない。候補は 168 時間前の時点の main の先頭（その時刻以前で最新の activity の `after`）。168 時間前以前の activity が取れなければ公開時刻不明として見送る（update-nvim-plugins の「版の上げ方のルール」と同じ） |

## Execution Process

ツールの種類ごとの収集のコマンドと注意は `${CLAUDE_SKILL_DIR}/references/` の `uv.md`・`mise.md`・`brew.md`・`zeno.md` にある。対象に入る種類のファイルだけを、手順 1 の前に Read する。繰り返し使う jq と gh のパイプラインは `${CLAUDE_SKILL_DIR}/scripts/` の script にしてあり、cwd に関わらず `bash "${SKILL_DIR:?}/scripts/<名前>.sh"` で呼ぶ。`SKILL_DIR` は `${CLAUDE_SKILL_DIR}`（references の中では展開されないので、ここに書かれた値を使う）で、使うブロックの先頭で定義し直す。

dotfiles への `git` は 2 か所に向く。本体（`~/dotfiles`。`~/.config/mise/config.toml` は symlink でここの config を指す）は `git -C ~/dotfiles`、手順 4 で作る worktree は `git -C "$WT"` と書いている。本体では fetch・status・pull・`worktree add` など読み取りと main の更新だけを行い、ブランチの切り替えと commit は worktree で行う。始める前に次で cwd を確かめ、`DOTFILES` なら `git -C ~/dotfiles` の `-C ~/dotfiles` を外す（cwd と同じ repo に `-C` を付けない、グローバルの CLAUDE.md の決まり）。シェルの変数は Bash の呼び出しをまたいで残らない。`br`・`WT` は手順 4 で `$TMPDIR/local-tools-state.sh` に書き、使うブロックの先頭で `. "$TMPDIR/local-tools-state.sh"; : "${WT:?}"` と読み込む（`br` は時刻から作るので計算し直すと別の名前になり、`WT` が空だと `git -C ""` が cwd の repo に向く）。

始める前に本体を origin/main にそろえる。

```bash
[ "$(pwd -P)" = "$(cd ~/dotfiles && pwd -P)" ] && echo DOTFILES || echo OTHER
if [ "$(git -C ~/dotfiles branch --show-current)" = main ]; then git -C ~/dotfiles pull --ff-only; else echo NOT-MAIN; fi
git -C ~/dotfiles status --short
```

- `NOT-MAIN` が出たとき、`pull --ff-only` が止まったときは、エラー処理の表に従って止める
- `status` に `configs/mise/config.toml` か `install.sh` が出たら止めて報告する。手順 1 は本体の config を読み、手順 4 は origin/main から切った worktree に書くので、両者が違うと候補と PR がずれ、merge のあとの pull もぶつかる

### 手順 1: 候補の収集（読み取りのみ）

基準時刻を `date -u +%Y-%m-%dT%H:%M:%SZ` で取って表に書く。経過時間は公開時刻（UTC の ISO 8601）から `bash "${SKILL_DIR:?}/scripts/hours-since.sh" '<published_at>'` で出す。小数秒付き（`.389957Z`、`.0Z`）の時刻もそのまま渡せる。

種類ごとに、references の「手順 1」に従って候補を集める。

| 種類 | reference | 見るもの |
|---|---|---|
| uv 本体 | `uv.md` | GitHub Release（`uv self update` に `--exclude-newer` が無いため） |
| uv tool、uv 管理の Python | `uv.md` | `uv tool list --outdated`、壊れた tool、印 `mise の Python`、PyPI の公開日、python-build-standalone のビルド |
| mise 本体、mise のツール | `mise.md` | インストールの経路（standalone か brew か）、`mise outdated --bump`、メジャー内の候補 |
| Homebrew | `brew.md` | `brew update` のあと `HOMEBREW_NO_AUTO_UPDATE=1` で outdated、自分で入れた formula、`--vulnerable`、巻き込まれる依存 |
| zeno.zsh | `zeno.md` | `ZENO_COMMIT` と、activity API の 168 時間前の main の先頭 |

### 手順 2: 侵害の事前確認（候補ごと）

2-1 と 2-2 は全候補で行う。2-1 で 168 時間未満と分かった候補は、2-2 で現行版に advisory がなければ見送りが決まるので、2-3・2-4 を省く。現行版に advisory があれば修正版の例外として 2-3・2-4 も行う。

候補が 5 件を超えたら、ツールごとにサブエージェント（Agent）へ分けて並列に回す。各エージェントには下の 4 項目と結果の書式（表の 1 行）を渡す。

#### 2-1. 公開日

公開時刻を取り、手順 1 の `hours-since.sh` で経過時間を出す。

| 対象 | 取り方 |
|---|---|
| uv・mise 本体 | 手順 1 の GitHub Release の `published_at` |
| uv 管理の Python のビルド | python-build-standalone のリリース（手順 1 で分かった tag）の `published_at`。CPython の版の公開日ではなく、uv が取りに行くビルドの公開日で数える |
| uv tool | PyPI の `upload_time_iso_8601` |
| mise ツール | `mise ls-remote <tool>@<prefix> -J` の `created_at` |
| brew formula・cask | tap の commit 日。パスは `brew info --json=v2 <name>` の `.ruby_source_path`、repo は `.tap`（`homebrew/core` → `Homebrew/homebrew-core`、`<o>/<r>` → `<o>/homebrew-<r>`） |
| zeno.zsh | 手順 1 の activity の `timestamp`。commit の日時は使わない |

brew の tap の commit 日の取り方は `brew.md` にある。

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
| uv 管理の Python のビルド | リリースの asset の digest で GitHub attestation を引く（`uv.md` のコマンド）。1 件以上あれば「attestation あり」 |
| uv tool | PyPI の provenance を `curl -s -H 'Accept: application/vnd.pypi.integrity.v1+json' https://pypi.org/integrity/<name>/<version>/<file>/provenance` で取る。404 なら「provenance なし（PyPI の hash のみ）」 |
| brew formula | 手順 4 で `HOMEBREW_VERIFY_ATTESTATIONS=1` を付ける（homebrew/core と対応 tap の bottle）。それ以外の tap は「formula の sha256 のみ」 |
| brew cask | cask に書かれた sha256 を brew が照合する。`sha256 :no_check` の cask は表で目立たせる |
| zeno.zsh | 署名は無い。表には「署名なし（commit で固定）」 |

一時ディレクトリは `mktemp -d` で作り、検証が終わったらファイルを消してから `rmdir` する。落とした成果物は実行しない。

#### 2-4. コード確認（GitHub compare）

全候補で現在の版から候補の版までの compare を取り、危険箇所に絞って読む。

```bash
bash "${SKILL_DIR:?}/scripts/compare-risky.sh" <o>/<r> <cur_tag> <new_tag>
```

見る箇所:
- `.github/workflows/` のうち release・publish・sign・build 系（`uses:` が SHA 固定か、外部からの `curl | sh`、`secrets.` の新しい使い方）
- install/build スクリプト（`build.rs`、`setup.py`、`install*.sh`、`Makefile`、npm の `postinstall`）
- 依存の追加（`Cargo.toml`、`pyproject.toml`、`package.json`、`go.mod` の新しい依存）
- 難読化・base64（長い base64 文字列、`eval`、`exec(`、`\x` の羅列）

- script は、変更ファイルの一覧と、release・publish・sign・build 系の workflow の差分のうち上の危険箇所に当たる行を出す
- 差分が大きい（数千 commit、300 ファイル超）ときは上の危険箇所だけを読み、表に「危険箇所のみ確認」と書く
- ソース非公開（1password-cli、cursor など）や upstream の repo が分からないものは「コード確認不可」と書く
- brew の revision だけの更新は `brew.md`、zeno.zsh のコード確認は `zeno.md` の「手順 2-4」に従う

#### 判定

| 判定 | 条件 |
|---|---|
| 更新可 | 168 時間以上、候補版に advisory なし、報道なし、署名の検証が通る（または仕組み上検証される）、危険箇所に異常なし |
| 見送り | 168 時間未満、候補版に advisory がある、侵害報道がある、署名が通らない、危険箇所に説明のつかない変更がある |
| 要判断 | 修正版の例外、メジャー跨ぎ、壊れた uv tool の直し、コード確認不可の cask、zeno.zsh の `基準が 168 時間未満`・force push |

巻き込み依存が「見送り」なら、その親も「見送り」にする。同じように、uv 管理の Python のビルドが「見送り」なら、それを使う uv tool の行も「見送り（Python のビルドが 168 時間未満）」にし、168 時間を超える時刻を書く。

### 手順 3: 表を示して承認を得る

次の列で表を出す。

| ツール | 現在 → 候補 | 経過時間 | advisory | 署名 | コード確認 | 印 | 判定 |
|---|---|---|---|---|---|---|---|

- 経過時間は `155 時間（6.5 日）` のように時間と日数を並べて書く。基準時刻も表の上に書く
- 種類（uv 本体・uv tool・uv 管理の Python・mise 本体・mise ツール・brew formula・brew cask・巻き込み依存・zeno.zsh）ごとに見出しで分ける
- zeno.zsh の行は、現在 → 候補を commit の短い sha で書く
- uv 管理の Python の行は、ツール名に `cpython-3.14.<patch>+<tag>`、コード確認に「対象外（CPython のビルド）」と書く
- 候補なしのツールは載せない。見送りは理由を判定の列に書く
- 表のあとに AskUserQuestion で承認を取る。最初の質問の選択肢は「更新可だけ実行」「更新可と要判断を選んで実行」「やめる」
- 「要判断を選んで実行」なら、要判断の項目を multiSelect で選ばせる。AskUserQuestion は 1 問に選択肢 2〜4 個、1 回の呼び出しに 4 問までなので、問いの数を件数 ÷ 4 の切り上げにして、件数の差が 1 以内になるよう均等に分け（5 件は 3 + 2）、5 問目からは次の呼び出しで聞く。こう分ければ 1 件だけの問いはできない。全体で 1 件なら multiSelect を使わず、その項目を変えるか既定のままにするかの 2 択にする（label の書き方は下と同じ）
  - 選択肢の label には、選んだときに起きることを書く（`node: 24.1.0 に上げる`、`ruff: 入れ直す` など）。選ばなかった項目が既定（上げない、入れ直さない）になる向きにそろえる

### 手順 4: 承認分だけ更新する

順序と失敗時の扱い:
- uv 本体 → mise 本体 → mise ツール → brew → uv tool → zeno.zsh の順に 1 つずつ実行する
- uv tool を最後にするのは、mise の Python を参照したままの tool が mise の更新で壊れることがあるため。mise の python を更新したら、手順 1 の uv tool の一覧を取り直し、壊れたものを表に足して承認を取り直す
- どれかが失敗したら、エラー処理の表の「更新コマンドの失敗」に従う

mise のツールか zeno.zsh を承認したときは、mise ツールの前に dotfiles の worktree を origin/main から作る。

```bash
br=chore/local-tools-$(date +%Y%m%d-%H%M)
WT=~/.herdr/worktrees/dotfiles/${br//\//-}
printf 'br=%q\nWT=%q\n' "$br" "$WT" > "$TMPDIR/local-tools-state.sh"
git -C ~/dotfiles worktree add -b "$br" "$WT" origin/main
```

| 対象 | コマンド |
|---|---|
| uv 本体 | `uv self update <version>` |
| mise 本体（standalone） | `mise self-update -y <version>` |
| mise ツール | `. "$TMPDIR/local-tools-state.sh"; : "${WT:?}"; (cd / && MISE_GLOBAL_CONFIG_FILE="$WT/configs/mise/config.toml" mise use -g <tool>@<version>)`（ツールごと） |
| brew formula | `HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_VERIFY_ATTESTATIONS=1 brew upgrade --formula <names>` |
| brew cask | `HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --cask <names>` |
| uv tool の前準備（安定版の Python） | `uv.md` の「手順 4: uv tool の Python をそろえる」を参照 |
| uv tool（メジャー内の更新） | `uv tool upgrade <name> --managed-python --python 3.14 --exclude-newer "7 days"` |
| uv tool（メジャー内に固定したい） | `uv tool install '<name>>=<cur>,<<next_major>' --managed-python --python 3.14 --exclude-newer "7 days"` |
| 壊れた uv tool、印 `mise の Python` の uv tool | `uv tool install <name> --reinstall --managed-python --python 3.14 --exclude-newer "7 days"`。receipt に index があれば `--default-index <url>` を付ける。メジャー跨ぎを避けるなら上の範囲指定を使う |
| zeno.zsh | `git -C ~/.local/share/zeno checkout --quiet --detach <cand>` が通ってから、`$WT/install.sh` の `ZENO_COMMIT` を `cand` の 40 桁の sha に Edit で書き換える（checkout が失敗したら書き換えずに止める） |

- uv tool の呼び方は `uv.md` の「手順 4」に従う。mise の config の書き換えと推移的な依存の扱いは `mise.md` の「手順 4」に従う

### 手順 5: worktree で commit、push、PR と報告

worktree を作らなかった（mise のツールも zeno.zsh も上げなかった）ときは 3 だけを行う。

1. `git -C "$WT" status --short` が `configs/mise/config.toml` と `install.sh` だけであることを確かめ、ファイルごとに別に commit する（変わっていない方の commit は飛ばす）

```bash
. "$TMPDIR/local-tools-state.sh"; : "${WT:?}"
git -C "$WT" add configs/mise/config.toml && git -C "$WT" commit -m "chore(mise): ツールバージョンを更新"   # mise を上げたときだけ
git -C "$WT" add install.sh && git -C "$WT" commit -m "chore(zeno): zeno.zsh を <cand の短い sha> に上げる"   # zeno.zsh を上げたときだけ
git -C "$WT" push -u origin HEAD
```

2. PR を作る。本文は `~/.claude/pull_request_template.md` の見出しに従い、表の全文は貼らず、要点だけを書く

- Summary: 基準時刻、上げた mise のツールと zeno.zsh、7 日ルールと侵害の確認を通したこと
- Test plan: 手順 4 の実行結果と、config の差分が版だけであること
- Review focus: 要判断で決めたもの、見送ったものと理由
- Merge and release notes: merge のあとに手順 6 を回すまで、mise の新しい版は効かないこと（入ってはいる）

```bash
gh pr create -R capytan/dotfiles --base main --head "$br" --title "chore: ローカルツールを更新する" --body-file "$TMPDIR/local-tools-pr-body.md"
```

3. 更新したもの、見送ったものとその理由、失敗したものを表で報告する。PR を作ったなら完全な URL と `br`・`WT` を書き、merge のあとに手順 6 を回すことを伝える

### 手順 6: merge のあとに本体を pull する

持ち主が PR を merge したと伝えたら回す。`$TMPDIR/local-tools-state.sh` が無い（別の会話や再起動のあと）ときは、報告に書いた `br`・`WT` で書き直す。

先に、PR が merge されたことと本体の状態だけを見る。`MERGED` でないとき、本体が main でないときは、ここで止めて報告する（下に進むと worktree を消す）。

```bash
. "$TMPDIR/local-tools-state.sh"; : "${WT:?}"
gh pr view "$br" -R capytan/dotfiles --json state,headRefOid --jq '"\(.state) \(.headRefOid)"'
git -C ~/dotfiles status --short --branch
```

両方を満たしたら pull し、PR の中身と同じになったか、上げた版が入っているかを見る。`pull --ff-only` が止まったらエラー処理の表に従う。

```bash
git -C ~/dotfiles pull --ff-only
git -C ~/dotfiles diff --quiet <headRefOid> HEAD -- configs/mise/config.toml install.sh && echo SAME-AS-PR
(cd / && mise ls --global --missing)
```

- `SAME-AS-PR` が出なければ（merge のあとに main の config か `install.sh` がまた変わった）、片付けずに報告する
- `mise ls --global --missing` が空なら、上げた版は手順 4 で入っていて、pull で効くようになった。出たツールがあれば報告する

ここまで通ったら片付ける。merge commit を pull してあるので `branch -d` で消せる。

```bash
. "$TMPDIR/local-tools-state.sh"; : "${WT:?}"
git -C ~/dotfiles worktree remove "$WT"
git -C ~/dotfiles branch -d "$br"
```

## エラー処理

| 状況 | 対応 |
|---|---|
| `gh api` が rate limit や認証エラー | `gh auth status` を確かめるよう伝えて止める。公開日・advisory が取れないまま判定しない |
| PyPI・GitHub で公開日が取れない | その候補は「見送り（公開日不明）」 |
| `safe-chain` が見つからない | uv tool の更新を止めて報告する |
| `mise self-update` が brew 管理を理由に断る | mise を brew の流れに移し、`brew upgrade --formula mise` を候補として表を出し直す |
| 更新コマンドの失敗 | エラーを原文のまま伝え、以降の更新を止める。それまでに済んだ mise のツールと zeno.zsh の変更は worktree に残っているので、手順 5 で PR にしてから報告する（入ったツールの版がどこにも固定されないまま残るのを防ぐ） |
| 本体が main でない（`NOT-MAIN`） | ブランチを切り替えず、本体の変更も捨てずに止めて報告する |
| `worktree add` が「already exists」で止まる | 同じ名前のブランチ・worktree と PR の状態を `gh pr list -R capytan/dotfiles --head "$br" --state all` で見て報告する。ブランチと worktree は消さない |
| `pull --ff-only` が止まる | 本体の変更を `git -C ~/dotfiles status` で見て報告する。変更は捨てない |

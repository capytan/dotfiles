# uv 本体・uv tool・uv 管理の Python

SKILL.md の各手順から Read する。`$SKILL_DIR` と、判定や表の書き方などの共通の決まりは SKILL.md に従う。

## 手順 1: uv 本体

```bash
command uv --version
command uv self update --dry-run
bash "${SKILL_DIR:?}/scripts/gh-releases.sh" astral-sh/uv
```

`uv self update` には `--exclude-newer` が無い。公開時刻は GitHub Release で確かめ、168 時間以上たった最新の版を候補にする。

## 手順 1: uv tool

```bash
command uv tool list --outdated --show-version-specifiers
command uv tool dir
```

- `warning: Tool \`X\` environment not found` が出た tool は「壊れている」として候補に入れる。今の版は `$(uv tool dir)/X/lib/python*/site-packages/` の `*.dist-info` 名から、使っている index は `$(uv tool dir)/X/uv-receipt.toml` の `[tool.options]` から読む
- 候補版は PyPI の公開日で決める（`--outdated` は 168 時間未満の版も出すため）
- `$(uv tool dir)/X/pyvenv.cfg` の `home` が uv の Python（`$(command uv python dir)` の下）でない tool は、印 `mise の Python` を付けて表に出す。手順 4 で `--managed-python` を付けて入れ直す
- 入れ直しや更新の候補があれば、使う uv 管理の Python も調べる。`command uv python find <PYVER> --managed-python` が安定版を返さなければ、手順 4 の前準備で入れる版（`command uv python list <PYVER> --managed-python` の最新の安定版）を、ビルドごと候補に入れる。ビルドは python-build-standalone のリリースで、URL の `releases/download/<tag>/` から tag が分かる

```bash
command uv python list <PYVER>.<patch> --managed-python --output-format json | jq -r '.[] | "\(.key) \(.url // .path)"'
gh api repos/astral-sh/python-build-standalone/releases/tags/<tag> --jq '"\(.tag_name) \(.published_at)"'
```

PyPI の公開日（候補版を決める）:

```bash
bash "${SKILL_DIR:?}/scripts/pypi-releases.sh" <name>    # 直近 5 版と公開時刻
```

## 手順 2-3: uv 管理の Python のビルドの attestation

```bash
# <file> は手順 1 の URL の末尾（%2B は + に戻す）
h=$(gh api repos/astral-sh/python-build-standalone/releases/tags/<tag> --jq '.assets[] | select(.name=="<file>") | .digest' | cut -d: -f2)
gh api "repos/astral-sh/python-build-standalone/attestations/sha256:$h" --jq '.attestations | length'
```

## 手順 4: uv tool の Python をそろえる

- `--managed-python` は uv が管理する Python だけを使い、mise の Python を使わない。実行後に `$(uv tool dir)/<name>/pyvenv.cfg` の `home` が `$(command uv python dir)` の下の安定版（alpha・beta・rc でない）になったことを確かめる

uv は条件に合う pre-release（例 `cpython-3.14.0a6`）が入っていると、安定版を取りに行かずにそれを使う（uv のドキュメント「Python versions」）。`uv python install <PYVER>` も、条件に合う版が入っていれば何もせずに終わる。だから uv tool を入れる前に、安定版を版まで指定して入れる。

```bash
command uv python list <PYVER> --managed-python     # 入っている版と、取得できる安定版（<download available>）を見る
command uv python find <PYVER> --managed-python     # 今 <PYVER> で選ばれる版
```

- `find` が pre-release を返したら、`list` に出る最新の安定版を `uv python install <PYVER>.<patch>` で入れる（この操作も承認の範囲に入れる）。入れたあと `find` が安定版を返すことを確かめる。安定版と pre-release が両方あれば、uv は安定版を選ぶ
- `find` が安定版を返すなら、前準備は要らない
- mise の Python を参照したままの tool には `uv tool upgrade` を使わず、`--reinstall` で入れ直す（環境を作り直して参照先を切り替えるため）
- `--exclude-newer "7 days"` は推移依存にも効く。推移依存の個別確認はしない

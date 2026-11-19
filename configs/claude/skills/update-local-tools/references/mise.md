# mise 本体・mise のツール

SKILL.md の各手順から Read する。`$SKILL_DIR` と、判定や表の書き方などの共通の決まりは SKILL.md に従う。

## 手順 1: mise 本体

```bash
mise --version
mise doctor | grep -E '^(version|self_update_available):'
command -v mise; brew --prefix
bash "${SKILL_DIR:?}/scripts/gh-releases.sh" jdx/mise
```

- `self_update_available: yes` で、パスが `$(brew --prefix)` の下でなければ standalone。`mise self-update` で更新する
- brew 経由なら mise は brew の formula として扱い、`brew.md` の流れに入れる

## 手順 1: mise のツール

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

## 手順 4: config の書き換えと推移的な依存

- mise の `npm:` と `pypi:` backend の推移依存は、mise の `minimum_release_age`（config の tool option で `7d`）で守る。個別確認はしない。npm: は mise 内蔵の aube が、pypi: は uv の `--exclude-newer` が依存の解決にこの cutoff をかける（mise の公式ドキュメント）。ツール本体の固定版には効かないので、本体は手順 1〜3 で確かめる
- `mise use -g` は tool option（`minimum_release_age`、azure-cli の `dependency_prereleases`・`with`）を残したまま `version` だけを書き換える。commit 前に `git -C "$WT" diff configs/mise/config.toml` で、変わったのが版だけであることを確かめる。`git -C ~/dotfiles status --short` に config が出たら（`MISE_GLOBAL_CONFIG_FILE` を付け忘れて本体に書いた）、止めて報告する

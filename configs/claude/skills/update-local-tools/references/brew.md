# Homebrew の formula・cask

SKILL.md の各手順から Read する。`$SKILL_DIR` と、判定や表の書き方などの共通の決まりは SKILL.md に従う。

## 手順 1: 候補の収集

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

## 手順 2-1: tap の commit 日

```bash
gh api 'repos/Homebrew/homebrew-core/commits?path=Formula/p/pipx.rb&per_page=1' --jq '.[0] | "\(.commit.committer.date) \(.commit.message|split("\n")[0])"'
```

## 手順 2-4: revision だけの更新

- brew の revision だけの更新（`2.1.1` → `2.1.1_1`）は upstream のコードが同じなので、tap の formula の差分だけを見る

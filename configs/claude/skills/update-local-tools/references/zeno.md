# zeno.zsh

SKILL.md の各手順から Read する。`$SKILL_DIR` と、判定や表の書き方などの共通の決まりは SKILL.md に従う。

## 手順 1: 候補の収集

基準 `base` は `install.sh` の `ZENO_COMMIT`。168 時間前の main の先頭を activity API で取る。activity は新しい順に返るので、`timestamp` が `cutoff` 以前の最初の 1 件が候補 `cand` とその公開時刻になる。

```bash
Z=~/.local/share/zeno
cutoff=$(jq -rn 'now - 168*3600 | todate')
base=$(git -C ~/dotfiles show origin/main:install.sh | sed -nE 's/^ZENO_COMMIT="([0-9a-f]{40})"$/\1/p')
git -C "$Z" fetch --quiet origin main
[ "$(git -C "$Z" rev-parse --is-shallow-repository)" = true ] && git -C "$Z" fetch --quiet --unshallow origin    # 古い install.sh の --depth 1 の clone
git -C "$Z" rev-parse HEAD    # base と違えば印 `ずれ`
bash "${SKILL_DIR:?}/scripts/activity-tip.sh" yuki-yano/zeno.zsh main "$cutoff"
```

```bash
cand=<上の 1 列目>
git -C "$Z" merge-base --is-ancestor "$cand" origin/main || echo "上流の main に載っていない（force push。止めて報告）"
if [ "$base" = "$cand" ]; then echo "候補なし"
elif git -C "$Z" merge-base --is-ancestor "$base" "$cand"; then echo "候補あり"
elif git -C "$Z" merge-base --is-ancestor "$cand" "$base"; then echo "基準が 168 時間未満"
else echo "別の系統（止めて報告）"; fi
git -C "$Z" log --format='%h %an <%ae> | %s' "$base..$cand"    # 上げる範囲
```

- activity の行が出なければ公開時刻不明。基準と main の先頭（`origin/main`）が同じなら「候補なし」、違えば「見送り（公開時刻不明）」
- `基準が 168 時間未満` は、7 日ルールを通らずに入った commit が `ZENO_COMMIT` にあるということ。印を付けて `cand..base` を手順 2 にかけ、戻すかは承認のときに選ぶ

## 手順 2-4: コード確認

- zeno.zsh は tag が無いので、fetch 済みのローカルで `git -C ~/.local/share/zeno diff "$base..$cand"` を読む。SKILL.md の 2-4 の見る箇所に加えて、シェル関数（`zeno.zsh`、`shells/zsh/`、`bin/`）、Deno の import（`src/deps.ts` などの `jsr:`・`npm:`・URL の追加と版の変更）、`deno run`・`deno cache` のフラグを見る。範囲の期間に main への force push が無いかも `gh api "repos/yuki-yano/zeno.zsh/activity?ref=refs/heads/main&activity_type=force_push&per_page=100" --paginate --jq '.[] | "\(.timestamp) \(.actor.login) \(.before[0:8])..\(.after[0:8])"'` で確かめ、あれば要判断

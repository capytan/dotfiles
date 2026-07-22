#!/bin/bash
# PreToolUse hook: 危険なコマンドを実行前にブロック
# Claude Code の PreToolUse イベントで呼び出される
# stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# stdout: {"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}} でブロック
# fail-open 方針: set -euo pipefail を使わず、jq 欠損時などは黙って allow (validator が二次的な信頼できないゲートである前提)

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Bash ツールのみ対象
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# 空コマンドは早期 allow
[ -z "$COMMAND" ] && exit 0

# 改行 (bash line continuation `\<nl>` 等) を空白に正規化。
# grep -qE は行単位処理なので、正規化しないと `git \<nl>push --force` 型の
# bypass が全 block で成立する
COMMAND=$(printf '%s' "$COMMAND" | tr '\n' ' ')

# deny 出力ヘルパ: 現行 Claude Code hook 契約 (hookSpecificOutput.permissionDecision) に準拠
deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# ask 出力ヘルパ: deny と同じ契約で permissionDecision を "ask" にする (ユーザーに確認プロンプトを出す)
ask() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# 設計原則:
# - segment 境界 ([^|;&`]*) を挟むことで、globaloption や `cd && sed -i` のような連結を吸収しつつ
#   `git status && git push origin main` のような cross-segment 混同を防ぐ
# - flag 検知は「行頭または空白の直後」を要求する ((^|[[:space:]])-...)。これがないと path 内の
#   `/var/log-final/` の `-f` を flag と誤認する false positive が発生する
# - flag 内の force を表す文字 (f/F/D) は前後に任意の short-option 文字を許容 ([a-zA-Z]*)

# 1. git push --force / -f / +refspec をブロック
# +refspec は space・行頭・シェルクォート (' や ") の後に来る形を許容する
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bpush\b[^|;&`]*(--force([-a-zA-Z]*)?\b|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*|(^|[[:space:]'"'"'"])\+[[:alnum:]_/@.^~:-])'; then
  deny "git push の force 系オプション (--force / --force-with-lease / -f / +refspec) は upstream に影響します。--force は履歴を破壊、--force-with-lease は他人の作業がなくても書き換えます。通常の git push で解決するか、ユーザーに明示的な確認を求めてください。"
fi

# 2. git reset --hard をブロック
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\breset\b[^|;&`]*--hard\b'; then
  deny "git reset --hard はコミットされていない変更を失います。代わりに git stash でスタッシュするか、バックアップブランチを作成してください。"
fi

# 3. git clean -f をブロック
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bclean\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*|--force\b)'; then
  deny "git clean -f は追跡されていないファイルを削除します。先に git clean -n でプレビューしてから、ユーザーに確認を求めてください。"
fi

# 4. git branch 強制削除をブロック
# - flag 位置 anchor 必須 (branch 名 feature-D-42 の false positive 回避)
# - long/short 双方向 mix ((--delete + -f), (-d + --force) 等) を網羅
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bbranch\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*D[a-zA-Z]*\b|(^|[[:space:]])-[a-zA-Z]*d[a-zA-Z]*f[a-zA-Z]*\b|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*d[a-zA-Z]*\b|(^|[[:space:]])(-[a-zA-Z]*d\b|--delete\b)[^|;&`]*[[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force\b)|(^|[[:space:]])(-[a-zA-Z]*f\b|--force\b)[^|;&`]*[[:space:]](-[a-zA-Z]*d[a-zA-Z]*|--delete\b))'; then
  deny "git branch の強制削除 (-D / -d -f / --delete --force) は取り消せません。安全な git branch -d を使用するか、削除前にユーザーに確認を求めてください。"
fi

# 5. rm -rf をブロック (-rf, -fr, -R+f, --recursive + --force のあらゆる組み合わせ)
# flag 位置 anchor 必須 (path 内の /var/log-f/ や data-r を flag と誤認しない)
if echo "$COMMAND" | grep -qE '\brm\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*[rR][a-zA-Z]*f[a-zA-Z]*\b|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*[rR][a-zA-Z]*\b|(^|[[:space:]])(-[rR]\b|--recursive\b)[^|;&`]*[[:space:]](-f\b|--force\b)|(^|[[:space:]])(-f\b|--force\b)[^|;&`]*[[:space:]](-[rR]\b|--recursive\b))'; then
  deny "rm -rf は復元不可能なファイル削除です。個別ファイルを指定するか、ユーザーに明示的な確認を求めてください。"
fi

# 6. sed の in-place 編集をブロック
# - `-i`, `-i.bak`, `-i ''`, `-iBAK` (GNU sed attached suffix), `--in-place` を網羅
# - パイプ内の read-only 用途 (git log | sed ...) や `sed -n 1,5p` は許可
if echo "$COMMAND" | grep -qE '\b(g)?sed\b[[:space:]][^|;&`]*(-i([a-zA-Z0-9.=[:space:]]|$)|--in-place\b)'; then
  deny "sed の in-place 編集 (-i / -iSUFFIX / --in-place) の代わりに Edit ツールを使用してください。read-only な用途 (sed -n, cmd | sed ...) は許可されています。"
fi

# 7. gawk の in-place 編集をブロック
# - `gawk -i inplace` (POSIX 形式), `gawk -iinplace` (attached optarg), `gawk --include inplace|=inplace` (long) を網羅
# - read-only な awk (awk '{print}' file 等) は許可
if echo "$COMMAND" | grep -qE '\b(g|n)?awk\b[[:space:]][^|;&`]*(-i[[:space:]]*inplace\b|--include([[:space:]]+|=)inplace\b)'; then
  deny "gawk -i inplace の代わりに Edit ツールを使用してください。read-only な awk は許可されています。"
fi

# 秘密ファイル系の path 検知は settings.json の Read()/Edit() ルールと対称に 2 段階で扱う:
#   鍵・証明書 (実体が必ず秘匿) は deny、機微ファイル (中身次第) は ask。
#   Read()/Edit() permission は Bash 経由の cat/head 等に効かないため、ここで具体パスを拾う。
#
# 設計方針 (rules 1-7 とは異なる):
# - パターンはコマンド全体に match させる ([^|;&`]* segment 境界を張らない)。
#   `cat foo && cat .env` のような後続 segment の path も拾いたいため。text-only な
#   コマンド (git commit の message、log 検索、branch 名等) は事前 bypass で除外する
# - APFS が既定で case-insensitive なので grep -Ei にする (uppercase 拡張子も検出)
# - 鍵名 `id_(rsa|ed25519|dsa|ecdsa)` を word boundary で拾う。他のツール由来
#   (`id_xmss` 等) の追加は同じ alternation に足す
# - `.env(rc)?\b` で dotenv と direnv (.envrc) の両方を拾う
# - `\.(ssh|aws|kube)([/[:space:]]|$)` で末尾なし (ls ~/.ssh) も含めて拾う
# - `.example`/`.template`/`.sample`/`.dist`/`.j2`/`.tpl`/`.pub` はテンプレート・
#   公開鍵として除外する (誤検知回避)
# - 具体パスのみ対象 (*key* 等の広い substring は false positive 過多のため validator では拾わない)

# rules 8/9 事前 bypass: text-only コマンド (message/log/branch 内の literal は path ではない)
_skip_path_rules=0
if echo "$COMMAND" | grep -qE '^[[:space:]]*(git[[:space:]]+(commit|log|branch|tag|checkout|switch|blame|shortlog|show|diff|remote|stash|rev-parse|cherry-pick)|echo|printf|history)\b'; then
  _skip_path_rules=1
fi
# rules 8/9 事前 bypass: テンプレート / 公開鍵の suffix
if [ "$_skip_path_rules" = "0" ] && echo "$COMMAND" | grep -qEi '\.(example|template|sample|dist|j2|tpl|pub)\b'; then
  _skip_path_rules=1
fi

# 8. 秘密鍵・証明書ファイルへのアクセスをブロック (deny を ask より先に評価)
if [ "$_skip_path_rules" = "0" ] && echo "$COMMAND" | grep -qEi '(\bid_(rsa|ed25519|dsa|ecdsa)\b|\.(pem|pfx|p12|jks)\b)'; then
  deny "秘密鍵・証明書ファイル (id_rsa / id_ed25519 / id_dsa / id_ecdsa / *.pem / *.pfx / *.p12 / *.jks) へのアクセスは禁止です。この種のコマンドは実行できません。どうしても必要な場合はユーザーがプロンプトで ! プレフィックスを付けて自分で実行してください。"
fi

# 9. 機微ファイルへのアクセスを確認 (ask)
if [ "$_skip_path_rules" = "0" ] && echo "$COMMAND" | grep -qEi '(\.env(rc)?\b|\.(ssh|aws|kube)([/[:space:]]|$)|\b(secrets|credentials)/|\.netrc\b|\.docker/config\.json\b|\.tfvars\b)'; then
  ask "機微ファイル (.env / .envrc / ~/.ssh / ~/.aws / ~/.kube 配下 / secrets・credentials ディレクトリ / .netrc / .docker/config.json / *.tfvars) にアクセスする可能性があります。内容を確認の上で承認してください。"
fi

exit 0

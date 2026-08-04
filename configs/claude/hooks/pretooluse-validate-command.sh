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

# 実行されないテキスト領域を検査対象から落とす (改行正規化より先に行う)。
# rule は文字列の pattern match なので、PR 本文や commit message に引用しただけの
# `rm -rf` まで拾う。実害ゼロの deny はゲートへの信頼を下げ迂回を誘発する。
#
# 除去してよいのは bash の意味論から「実行されない」と証明できる形だけ。迷う入力は
# 必ず「除去しない = 検査する」側 (fail-closed) に倒す。逆に倒すと silent allow になる。
# アルゴリズムと過去の bypass 実例は ~/dotfiles/.claude/rules/claude-config.md

# double quote 内 / unquoted heredoc 本文で実行を起こせるのは `...` / $(...) / ${ ...; }
# の 3 形式だけ。$var は展開されるだけでコマンドとして再パースされない。
_is_inert_text() {
  case "$1" in
    *'`'* | *'$('* | *'${'*) return 1 ;;
  esac
  return 0
}

# 先頭の (^|[^<]) は herestring `<<<` を heredoc と誤認しないための除外
_HEREDOC_START_RE='(^|[^<])<<-?[[:space:]]*([^[:space:]<;|&()]+)'

# 本文を実行しないと分かっている消費者。blocklist だと列挙漏れがそのまま silent allow に
# なる (`ssh host <<EOF` は本文をリモートシェルが実行するが `sh` に一致しない)。
_HEREDOC_SAFE_CONSUMER_RE='^[[:space:]]*(cat|tee|git|gh)([[:space:]]|$)'

# 本文を捨ててよいか。判定は先頭語だけを見る (行全体だと
# `cat > shell/zsh/x.zsh <<'EOF'` のリダイレクト先パスを消費者と誤認する)。
_heredoc_consumer_is_safe() {
  local chunk rest seg
  # `;` `&` で区切り、`<<` を含む chunk を選ぶ (heredoc はその command に属する)
  rest=${1//&/;}
  while :; do
    chunk=${rest%%;*}
    case "$chunk" in *'<<'*) break ;; esac
    [ "$chunk" = "$rest" ] && return 1
    rest=${rest#*;}
  done
  chunk=${chunk%"${chunk##*[![:space:]]}"}
  # 行末が `|` / `\` だと pipeline の残りが次行にあり判断できない
  case "$chunk" in
    *'|' | *'\') return 1 ;;
  esac
  # pipeline の全 segment が安全であることを要求する (`cat <<'EOF' | sh` を弾く)
  while :; do
    seg=${chunk%%|*}
    [[ "$seg" =~ $_HEREDOC_SAFE_CONSUMER_RE ]] || return 1
    [ "$seg" = "$chunk" ] && break
    chunk=${chunk#*|}
  done
  return 0
}

# heredoc 本文を除去する。宣言行は実コマンドなので残す。
# 戻り値は「完全に除去済み」か「入力そのまま」の 2 状態だけ。
_strip_heredoc_bodies() {
  local line trimmed delim="" quoted=0 body="" out=""
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$delim" ]; then
      # 終端判定は前後の空白を落として比較する (`<<-` のタブ字下げに対応)
      trimmed="${line#"${line%%[![:space:]]*}"}"
      trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
      if [ "$trimmed" = "$delim" ]; then
        # quoted はリテラル。unquoted は展開されるので実行経路が無いときだけ捨てる
        [ "$quoted" = "1" ] || _is_inert_text "$body" || out+="$body"
        delim=""
        body=""
      else
        body+="$line"$'\n'
      fi
      continue
    fi
    out+="$line"$'\n'
    if [[ "$line" =~ $_HEREDOC_START_RE ]]; then
      # delim を先に確定させる (_heredoc_consumer_is_safe も [[ =~ ]] で BASH_REMATCH を潰す)
      delim="${BASH_REMATCH[2]}"
      _heredoc_consumer_is_safe "$line" || { delim=""; continue; }
      # `<<\EOF` も bash では quoted で終端は `EOF`。`\` を剥がさないと終端が一致しない
      case "$delim" in
        *\'* | *\"* | *\\*) quoted=1 ;;
        *) quoted=0 ;;
      esac
      delim="${delim//\'/}"
      delim="${delim//\"/}"
      delim="${delim//\\/}"
      body=""
    fi
  done <<< "$1"
  # fail-safe: 終端が見つからなければ heredoc の誤認 (`cat "a << b"` 等)。除去結果を
  # 捨てて入力を返す。素通りさせると捨てた行に隠れた実コマンドが allow される。
  [ -n "$delim" ] && { printf '%s' "$1"; return; }
  printf '%s' "$out"
}

# guard: `<<` が無ければループごと飛ばす (見逃しても検査側に倒れるので穴は開かない)
case "$COMMAND" in
  *'<<'*) COMMAND=$(_strip_heredoc_bodies "$COMMAND") ;;
esac

# message / body 系フラグの引用符付き値を空にする。
# unquoted な値は空白を含まない 1 語なので `rm -rf <path>` 型の pattern は成立せず、
# 引用符付きだけを対象にすれば十分。`bash -c "..."` の -c は対象外なので、
# インタプリタに渡す文字列は従来どおり検査される。
_MSG_FLAG_VALUE_RE="((^|[[:space:]])(-m|-b|-t|--message|--body|--title|--notes|--description)([[:space:]]+|=))('[^']*'|\"[^\"]*\")"

# 除去は値が属する segment の先頭語が git / gh のときだけ。フラグ名だけでは値が不活性か
# 決まらない (`ssh h -t "cmd"` はリモートで実行、`curl -b "..."` は cookie)。
_SEGMENT_LEADER_RE='^[[:space:]]*(git|gh)([[:space:]]|$)'
# 改行もコマンド区切りなので segment 境界に含める
_SEGMENT_SEP_CLASS=$'\n|;&`'

# 値の中に区切り文字が入りうる (`--body "a && b"`) ので、先に値を見つけてから
# 手前のテキストで segment の先頭語を判定する。
_strip_flag_values() {
  local rest=$1 out="" full head val pre ctx
  while [[ "$rest" =~ $_MSG_FLAG_VALUE_RE ]]; do
    full=${BASH_REMATCH[0]}
    head=${BASH_REMATCH[1]}
    val=${BASH_REMATCH[5]}
    pre=${rest%%"$full"*}
    rest=${rest#*"$full"}
    ctx="$out$pre"
    ctx=${ctx##*[$_SEGMENT_SEP_CLASS]}
    if [[ "$ctx" =~ $_SEGMENT_LEADER_RE ]]; then
      case "$val" in
        \'*) out+="$pre$head''" ;;
        *) if _is_inert_text "$val"; then out+="$pre$head\"\""; else out+="$pre$full"; fi ;;
      esac
    else
      out+="$pre$full"
    fi
  done
  printf '%s' "$out$rest"
}

# guard: 引用符付きの message 系フラグを含まないコマンドは丸ごと飛ばす
if [[ "$COMMAND" =~ $_MSG_FLAG_VALUE_RE ]]; then
  COMMAND=$(_strip_flag_values "$COMMAND")
fi

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

# 4. 破壊的な削除を確認 (ask)
# - deny ではなく ask にするのは、ユーザー承認という逃げ道がないとエージェントが迂回コマンドを
#   探すため (実例: branch -D の deny → git update-ref -d で抹消)。branch/ref は reflog から
#   一定期間復元できるので、完全に不可逆な rm -rf 等 (rule 5) とは区別する
# - 同じ理由で、迂回経路 (update-ref) も同じ ask に載せる。片方だけ deny にすると gate が形骸化する
# - branch: flag 位置 anchor 必須 (branch 名 feature-D-42 の false positive 回避)
#   long/short 双方向 mix ((--delete + -f), (-d + --force) 等) を網羅
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bbranch\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*D[a-zA-Z]*\b|(^|[[:space:]])-[a-zA-Z]*d[a-zA-Z]*f[a-zA-Z]*\b|(^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*d[a-zA-Z]*\b|(^|[[:space:]])(-[a-zA-Z]*d\b|--delete\b)[^|;&`]*[[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force\b)|(^|[[:space:]])(-[a-zA-Z]*f\b|--force\b)[^|;&`]*[[:space:]](-[a-zA-Z]*d[a-zA-Z]*|--delete\b))'; then
  ask "git branch の強制削除 (-D / -d -f / --delete --force) は未マージのコミットを失う可能性があります (reflog からは一定期間復元可能)。対象ブランチがマージ済みか確認の上で承認してください。"
fi

# git update-ref -d は branch -D と同じ ref 抹消。squash merge されたブランチの掃除で
# エージェントが branch -D の代わりに使いがちなので、同じゲートに載せる
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bupdate-ref\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*d[a-zA-Z]*\b|--delete\b)'; then
  ask "git update-ref -d は ref (branch / tag) を直接削除します。git branch -D と同等の破壊的操作です。対象 ref を確認の上で承認してください。"
fi

# worktree remove --force は未コミット変更を破壊する。reflog に残らない分 branch -D より
# 危険なので、復元可能な branch -D にゲートを張るなら当然こちらにも張る
if echo "$COMMAND" | grep -qE '\bgit\b[^|;&`]*\bworktree\b[^|;&`]*\bremove\b[^|;&`]*((^|[[:space:]])-[a-zA-Z]*f[a-zA-Z]*\b|--force\b)'; then
  ask "git worktree remove --force は worktree 内の未コミット変更を破棄します。reflog では復元できません。対象 worktree に未保存の作業がないか確認の上で承認してください。"
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
# _is_inert_text を AND するのは、この bypass も「実行されないテキスト」を前提にしているため。
# 無条件だと `echo "$(cat <秘密鍵>)"` が rules 8/9 を丸ごと飛ばして allow になる。
_skip_path_rules=0
if _is_inert_text "$COMMAND" && echo "$COMMAND" | grep -qE '^[[:space:]]*(git[[:space:]]+(commit|log|branch|tag|checkout|switch|blame|shortlog|show|diff|remote|stash|rev-parse|cherry-pick)|echo|printf|history)\b'; then
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

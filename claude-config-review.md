# Claude Code 設定 全面レビューレポート

- 実施日: 2026-07-06
- 対象: `/Users/capytan/dotfiles` の Claude Code 設定一式(working tree 基準。`settings.json` の `model` キーは一時値のため対象外)
- 手法: 観点別 5 subagent の並列レビュー + メインセッションでの追検証。**「実機確認済み」「実行確認済み」と記した項目は本セッションのツール実行で挙動を確認したもの**。未検証の推測はその旨明記。

---

## 1. 要約（TLDR）

最大の問題は、**PreToolUse バリデータ(`pretooluse-validate-command.sh`)が現行の Claude Code では何もブロックしていないこと**です。deny の出力フォーマットが旧仕様ですらない独自形式のため hook 出力として認識されず、本セッションでブロック対象コマンド(standalone `sed`)を実行したところ素通りしました。`git push`/`rm` などは permissions の ask リストが二重の守りになっていますが、`git clean -f`・`git branch -D`・単独 sed/awk はこの hook が唯一のゲートなので、現在は無警告で通ります。加えて、フォーマットを直した後も効くように塞ぐべき検知パターンの穴が 5 種(実行確認済み)あります。

一方、全体の土台は良好です。settings.json の 13 hook エントリは全て実ファイルと一致、tmux 状態表示系はドキュメント・実装・優先度表が完全に一致しており、グローバル CLAUDE.md は簡潔で現行モデル(Opus 4.8 / Sonnet 5)に適合しています。懸念されていた `outputStyle` は現物にも git 履歴にも存在せず、対応不要です。

構造面では、(1) レビュー系 skill のうち `auditing-claude-config` と `claude-config-reviewer` が「audit」で正面衝突している、(2) 言語 reviewer agent 8 本が「security-reviewer へ hand off せよ」という subagent には実行不可能な指示を持つ、(3) `mcp.json` と `~/.claude/RTK.md` が死んだ設定として残っている、が主な整理対象です。

---

## 2. 重大度別の指摘一覧

### Critical

**C1. PreToolUse バリデータの deny 出力が認識されず、実質 no-op**
- `configs/claude/hooks/pretooluse-validate-command.sh:20,26,32,38,44,51,58`
- 問題: deny を `{"permissionDecision": "deny", "message": "..."}` (トップレベル・フラット)で出力し常に exit 0。現行の hook 出力契約は `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..."}}` (旧式は `decision: "block"` + `reason`)であり、本スクリプトの形式はどちらにも該当しない。Claude Code 2.1.201 バイナリ内のスキーマ記述(`strings` で抽出、subagent 確認)にも「`decision` は PreToolUse では deprecated、`hookSpecificOutput.permissionDecision` を使え」と明記。
- **実機確認済み**: 本セッション(同一 hook 設定)でブロック対象の `sed -n 1p /etc/hosts` を実行 → ブロックされず正常実行された。
- 影響: `git push --force`・`git reset --hard`・`rm -rf` は settings.json の ask リストが確認プロンプトを出すため全開放ではない。しかし **`git clean -f`・`git branch -D`・単独 sed/awk は ask/deny のどのリストにもなく、この hook が唯一のゲート**のため、現在は素通り(defaultMode: auto)。
- 推奨: 出力を `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}` に修正。修正後に実機でブロックを確認する。

### Warning

**W1. バリデータ検知パターンのバイパス 5 種(すべて実行確認済み)**

C1 修正後に意味を持つ穴。subagent がスクリプトに JSON を流して ALLOW/DENY を確認済み:

| # | バイパス例 | 原因 | 該当行 |
|---|---|---|---|
| a | `git -c protocol.version=2 push --force` | 正規表現が `-C <path>` しか想定せず `-c k=v` 等で不一致 | :19,25,31,37 |
| b | `git push origin +HEAD:main` | refspec `+`(強制更新)を未検出 | :19 |
| c | `rm -Rf /tmp/x` / `rm -R -f` | char class が小文字 `r` のみ(macOS で `-R` は有効) | :43 |
| d | `git branch --delete --force x` | 大文字 `-D` のみ検出、long form 未対応 | :37 |
| e | `cd /tmp && sed -i s/a/b/ f` / `command sed ...` | sed/awk のみ行頭アンカー(`^\s*sed\s`)で連結・前置に弱い(rm は非アンカーで連結でも検出) | :50,57 |

- 推奨: (a) git のグローバルオプションを `(\s+-[cC]\s*\S+)*` 等で許容、(b) `+refspec` 検出追加、(c) `[rR]` に拡張、(d) `--delete.*--force` 追加、(e) sed/awk のアンカー方針を rm と揃える(連結を考慮)。

**W2. sed/awk の read-only 用途まで誤ブロック(誤検知)**
- `configs/claude/hooks/pretooluse-validate-command.sh:50,57`
- **実行確認済み**: `sed -n 1,5p file`(表示のみ・非破壊)が DENY 判定。Edit ツールで代替できない読み取り用途まで一律ブロックする方針は過剰。C1 修正でバリデータが実効化すると、この誤検知も実際に発火し始める点に注意。
- 推奨: `-i` フラグ(in-place 編集)がある場合のみブロックする等、破壊的操作に限定。

**W3. 秘密ファイルの Read/Write 保護が Bash 経由でバイパス可能**
- `configs/claude/settings.json:83-85,93,220`(`cat`/`head`/`tail`/`echo`/`printf` の無条件 allow)
- 問題: deny/ask の `Read(~/.ssh/**)`・`Read(.env*)`・`Read(**/*.pem)` 等は Read/Write ツールにしか効かない。`cat ~/.ssh/id_rsa` や `cat .env` はプロンプトなしで実行され、`echo x > file` のリダイレクト書き込みも `Write()` ルールをすり抜ける(`tee` だけ ask にした対策も echo/printf には及ばない)。PreToolUse バリデータも秘密ファイル読取はスコープ外。
- 推奨: 秘密ファイル保護を本気で機能させるならバリデータ側で `cat`/`head`/`tail` の秘密パス読取をブロックする。そこまでしないなら「Bash には効かない」制約を CLAUDE.md 等に明記して期待値を揃える。

**W4. `configs/claude/mcp.json` が orphan、`enabledMcpjsonServers` が no-op**
- `configs/claude/mcp.json`(全体、`{"mcpServers": {}}` で空)、`configs/claude/settings.json:368-370`
- 問題(検証済み): mcp.json は `setup-claude.sh` の symlink 対象になっておらず、どこからも参照されない dead file。`enabledMcpjsonServers: ["context7"]` はプロジェクト `.mcp.json` 由来サーバの承認機構だが、実際の context7 は plugin(`context7@claude-plugins-official`)から供給されており、この entry は stale。
- 推奨: mcp.json を削除し、`enabledMcpjsonServers` を空にするか削除。雛形として残す意図があるならコメントで明示。

**W5. `~/.claude/RTK.md` が dangling symlink**
- symlink 先 `configs/claude/RTK.md` はコミット 0ded279(rtk integration 削除)で消滅(git log で検証済み)。`setup-claude.sh` に除去処理がないため再実行でも直らない。実害は小さいが、`ls -la ~ | grep dotfiles` 検証原則(CLAUDE.md)に照らして不衛生。
- 推奨: `rm ~/.claude/RTK.md`。setup-claude.sh に「symlink 先が消えたリンクの掃除」を足すかは任意。

**W6. `kill` は ask なのに `pkill`/`killall` は無条件 allow(逆転)**
- `configs/claude/settings.json:149-150`(allow)vs `:264`(ask)
- 名前指定で広範囲に殺せる `pkill -9 node` の方が PID 指定の `kill` より影響が大きいのに扱いが逆。
- 推奨: 3 つを同じ扱い(ask 推奨)に揃える。

**W7. `auditing-claude-config` と `claude-config-reviewer` が同一ドメインで衝突**
- `configs/claude/skills/claude-config-reviewer/SKILL.md:3-5` / `auditing-claude-config/SKILL.md:3`
- 問題: 両者とも Claude Code 設定をレビューし、description の「audit」が正面衝突。「claude 設定を audit して」でどちらが起動するか予測不能。auditing 側は SKILL.md:48 で claude-config-reviewer を相互参照しており機能が地続き。意図された棲み分け(auditing=症状ベースの診断 / claude-config-reviewer=品質採点)は description から読めない。
- 推奨: 統合が最善(auditing の 6 層フレームを主とし採点側を詳細モードとして吸収)。存続させるなら description を相互排他に書き分ける。

**W8. 言語 reviewer 8 本の「security-reviewer へ hand off」が実行不可能な指示**
- `python-reviewer.md:43`, `typescript-reviewer.md:52`, `cpp-reviewer.md:43`, `java-reviewer.md:57`, `ruby-reviewer.md:44`, `rust-reviewer.md:44`, `kotlin-reviewer.md:66`, `flutter-reviewer.md:65`(いずれも configs/claude/agents/)
- 問題: これらの tools は `Read/Grep/Glob/Bash` のみで Agent 系ツールを持たず、subagent は subagent を起動できない。「stop and hand off to security-reviewer」は存在しない能力を前提にした指示。`go-reviewer.md:56` の「recommend escalation」だけが実態に即す。また python/typescript/cpp では hand off ステップが「Begin review」より前に置かれ順序も逆。
- 推奨: go-reviewer の文言(「CRITICAL としてフラグし、親セッションに security-reviewer の起動を推奨する」)に 8 本を統一。

**W9. architect / planner / tdd-guide の proactive トリガーが三つ巴に競合**
- `configs/claude/agents/architect.md:5,16-22`, `planner.md:5,16-23`, `tdd-guide.md:5`
- 問題: 「複雑な機能を実装して」という 1 つの依頼で 3 agent が同時に proactive 起動を主張する文面。とくに architect と planner は「実装前・複数サービス横断・フェーズ分割」まで近い。
- 推奨: architect=「後戻りしにくい設計判断・技術選定」、planner=「設計確定後の手順分解」にトリガーを絞り、planner に「設計判断が未確定なら architect を先に」の境界を 1 文追加。

**W10. `claude-config-reviewer` の採点儀式と freshness policy が現行モデルで過剰**
- `configs/claude/skills/claude-config-reviewer/SKILL.md:142-144,217-224`(100 点採点 + S〜F grade)、`:46-48`(freshness)
- 問題: 数値スコア・グレード付与は旧モデル向けの構造化儀式で、Opus 4.8 / Sonnet 5 は severity 付き findings で十分機能する。数値化は恣意性(「なぜ 83 点か」)を生む。また「reference が 1 日以上古ければ全 reference を再リサーチ」は、ほぼ毎回 context7 + WebSearch + WebFetch のフルリサーチが走る設定で遅く高コスト。
- 推奨: 採点を severity タグ付き findings に置換。freshness 閾値は 30〜90 日に緩和するか明示要求時のみに。

**W11. グローバル CLAUDE.md が実在しないパス `configs/claude/rules/` を案内**
- `configs/claude/CLAUDE.md:12`
- 問題(検証済み): `~/dotfiles/configs/claude/{agents,skills,hooks,rules}/` のうち `rules` は実在しない。rules は `.claude/rules/`(リポジトリローカル・path-scoped)にあり、他 3 つと違って `~/.claude/` に symlink もされない。パスもスコープも異なるものを同じ brace に混ぜている。
- 推奨: brace から `rules` を外して `{agents,skills,hooks}/` にし、rules は「repo-local の `.claude/rules/`」と別記。

**W12. 「Hooks must use tmux-lib.sh」ルールが overbroad**
- `.claude/rules/claude-config.md:1`
- 問題(検証済み): `pretooluse-validate-command.sh` / `tmux-session-end-usage.sh` / `worktree-git-wt.sh` は tmux-lib.sh を source しておらず(tmux ステータス hook でないので当然)、無条件の「must」が実態と不一致。同ファイル内の `set -euo pipefail` 例外規定とも整合しない。
- 推奨: 「tmux ステータス hook は tmux-lib.sh の共有関数を使う」にスコープ限定。

**W13. `build-error-resolver` と `flutter-reviewer` の過剰な規範(削減余地が最大の 2 本)**
- `configs/claude/agents/build-error-resolver.md:48-171`: 中核方針「最小 diff・refactor しない・build を通す」は :37 で言い切っており、以降の Common Fixes 表 / DO-DON'T / Priority Levels / Quick Recovery / Success Metrics は同義反復。「Read the error message carefully」は現行モデルに不要。
- `configs/claude/agents/flutter-reviewer.md`(266 行、担当中最長): CRITICAL 項目は価値が高いが、Dependencies & Build(LOW, :212-218)や Internationalization(MEDIUM, :206-210)等の末端は発火頻度が低い。
- 推奨: build-error-resolver は中核方針 + 「When NOT to Use」を残して表群を大幅圧縮。flutter-reviewer は LOW と一部 MEDIUM を圧縮。

**W14. `codebase-review` の diff/PR リダイレクト先が不完全**
- `configs/claude/skills/codebase-review/SKILL.md:3`
- 問題: description が「diff/PR は code-review を使え」と誘導するが、同じ設定内の diff/PR 用 `agent-team-review` に触れておらず入口が二重化。
- 推奨: 「軽量差分は code-review、深い多エージェント差分は agent-team-review」と両方を案内。

### Nits

**N1. `MAX_THINKING_TOKENS: "31999"` と `effortLevel`/`alwaysThinkingEnabled` の重複疑い** — `configs/claude/settings.json:6,694-695`。現行モデルでは thinking 量は effort で制御される。併用時に env が今も効くかは**未検証**。挙動確認のうえ冗長なら削除候補。

**N2. `Bash(git push --force *)` の ask entry が冗長** — `configs/claude/settings.json:271`。`:270` の `Bash(git push *)` の部分集合で無効果。意図の明示として残すなら可。

**N3. `git describe` の allow が `-C` 版のみ** — `configs/claude/settings.json:60`。素の `git describe *` が allow になく、「cwd 一致時は -C を使うな」方針(CLAUDE.md:13)と非対称。

**N4. reviewer 間の定型 drift** — `configs/claude/agents/rust-reviewer.md:41-42` のみ `git diff HEAD~1 -- '*.rs'` を使い、他 reviewer(`git diff --staged` + `git diff` → 空なら `git show HEAD`)と対象が異なる(未コミット変更でなく直前コミットを見る)。意図的でなければ統一。Approval Criteria の逐語重複も将来の一斉更新漏れリスク。

**N5. reviewer の出力フォーマット不統一** — kotlin/flutter/security は Severity 集計テーブルを持つが go/python/typescript/rust/cpp/java/ruby は持たない。偶発的な差に見える。

**N6. 言語 reviewer の `model: sonnet` 固定はセッションモデルを上書き** — 全 language reviewer + build-error-resolver + tdd-guide が sonnet、architect/planner/security-reviewer が opus。旧モデル ID の混入はなし(エイリアスなので現行に解決)。Opus 4.8 常用セッションでも reviewer は sonnet で走る。コスト最適化なら妥当、意図の確認のみ。

**N7. `worktree-git-wt.sh` の jq 未ガードと xargs** — `configs/claude/hooks/worktree-git-wt.sh:7,21`(`set -euo pipefail` 下で jq 不在だと WorktreeCreate が非 0 終了)、`:30`(`| tail -n1 | xargs` はスペース入りパスを壊す)。当該マシンに jq は実在するため実害は低い。

**N8. `scoring-rubric.md` が 2 skill で完全同一** — `agent-team-review/references/` と `codebase-review/references/` で diff 一致(検証済み)。skill 自己完結の原則上コピーは許容だがドリフト注意。

**N9. `dig-plan` に allowed-tools がない** — `configs/claude/skills/dig-plan/SKILL.md:1-4`。全ツール継承(Write/Edit/Bash 可)。他 skill の最小権限方針と不揃い。

**N10. CLAUDE.md のブロック対象列挙が不完全** — `configs/claude/CLAUDE.md:17`。実装は `git clean -f`(:31)と `git branch -D`(:37)もブロック(するつもり)だが列挙にない。"patterns" という書き方なので誤りではない。

**N11. statusline のモデル名短縮が display_name 形式に依存** — `configs/claude/statusline.sh:39-40`。`Opus 4.8` のようなスペース区切りだと短縮が効かずそのまま表示(cosmetic、実フォーマット未確認)。

**N12. install.sh の検証レポートに Claude 系 symlink が含まれない** — `install.sh:116-119,195-205`。setup-claude.sh が別途張るため集計外。機能上は問題なし。

**N13. `additionalDirectories` の `~` 展開(未検証)** — `configs/claude/settings.json:701-704`。展開されない場合は無効。一度確認を推奨。

**N14. `japanese-tech-writing` と `natural-japanese` の AI 臭除去の軽い重なり** — 用途(執筆規範 vs 既存文の humanize)が異なり description で区別可能。統合不要、記録のみ。

---

## 3. 現行モデル(Opus 4.8 / Sonnet 5)適合性の所見

**outputStyle は「対応不要」が結論**です。working tree にも git 履歴(`git log -S outputStyle`)にも一度も設定されたことがなく、`learning-output-style` plugin も無効(検証済み)。「グローバル既定に置かない」という望ましい状態が既に成立しています。将来も、モデルを跨ぐ単一グローバル値として応答を常時冗長化させる性質と、機能自体の deprecated シグナルの両面から、settings.json には入れずセッション単位に留めるのが妥当です。

**旧モデル前提のガードレールはほぼ検出されませんでした。** hooks はモデル非依存の bash パターン検査のみで除去対象なし。グローバル CLAUDE.md は簡潔で、削除すべき防御的指示は見つかりませんでした(`git -C` 回避指示も permission ルールの実挙動に根拠があり保持推奨)。

**削除・簡素化の本丸は skill / agent の「儀式」です。** 具体的には (1) `claude-config-reviewer` の 100 点採点 + S〜F グレード + 1 日 freshness ポリシー(W10)、(2) `build-error-resolver` の同義反復する表群(W13)、(3) `flutter-reviewer` の低発火チェックリスト末端(W13)。いずれも旧モデルの弱いプランニングを補う構造で、現行モデルには中核方針の言い切りで足ります。なお各言語 reviewer のチェックリスト自体はドメイン知識の注入として妥当で、全削除は非推奨です。

**簡潔化方針との綱引きは軽微。** 唯一、claude-config-reviewer の採点儀式が「直接本題へ」の精神と不整合な程度で、settings.json / CLAUDE.md レベルの矛盾はありません。

**Fable 5 固有の副次論点: 該当なし。** 内部推論を応答本文へ再現・転記・説明させる指示は、skills 9 本・agents 14 本のいずれからも検出されませんでした(`reasoning_extraction` refusal を誘発する記述なし)。`MAX_THINKING_TOKENS: "31999"` だけは adaptive thinking / effort 制御との重複が疑われるため、Fable 5 使用時を含め一度挙動確認を推奨します(N1)。

---

## 4. 重複・矛盾マップ

| 箇所 A | 箇所 B | 状態 | リスク・対応 |
|---|---|---|---|
| `configs/claude/CLAUDE.md:17-18`(validator がブロックすると記述) | `pretooluse-validate-command.sh`(実質 no-op) | **矛盾(実害あり)** | C1 修正でドキュメントを真にする。修正しないなら記述を削除 |
| `configs/claude/CLAUDE.md:18`(emoji→意味) | `.claude/rules/claude-config.md` 優先度表 | 重複(現状は一致) | emoji 変更時に 2 箇所更新が必要。global 側は要約に留める設計自体は妥当 |
| `auditing-claude-config` description | `claude-config-reviewer` description | **衝突** | 「audit」が両方にあり起動が不定。統合 or 相互排他化(W7) |
| `codebase-review` の誘導先(code-review のみ) | `agent-team-review` の存在 | 不完全な参照 | diff レビューの入口二重化を description で解消(W14) |
| `agent-team-review/references/scoring-rubric.md` | `codebase-review/references/scoring-rubric.md` | 完全同一の複製 | ドリフト注意(N8) |
| 言語 reviewer 8 本の「hand off」文言 | `go-reviewer` の「recommend escalation」 | 文言不統一 + 実行不可能指示 | go 版に統一(W8) |
| 言語 reviewer の Approval Criteria / diff 取得手順 | rust-reviewer のみ `HEAD~1` | コピペ drift | 統一(N4) |
| `.claude/rules/claude-config.md:1`「Hooks must use tmux-lib.sh」 | 非 tmux hook 3 本の実装 | ルールが overbroad | スコープ限定(W12) |
| root `CLAUDE.md` sacred-file リスト | `.claude/rules/shell-config.md:10` | **良好**(明示委譲で単一情報源) | 対応不要 |
| `settings.json:270` `git push *` ask | `:271` `git push --force *` ask | 部分集合の重複 | 271 は無効果(N2) |

---

## 5. 推奨アクション

### すぐ直すべきもの(実害 or 死んだ設定)

1. **C1: バリデータの出力フォーマット修正**(`hookSpecificOutput` 形式へ)+ 修正後の実機ブロック確認。これを直さない限り W1/W2 の修正は無意味
2. **W1: 検知パターンの穴 5 種を修正**(git グローバルオプション、`+refspec`、`rm -Rf`、`--delete --force`、sed/awk の連結)。あわせて W2 の read-only sed 誤検知を `-i` 限定に
3. **W4 + W5: 死んだ設定の掃除** — `configs/claude/mcp.json` 削除 + `enabledMcpjsonServers` 整理、`rm ~/.claude/RTK.md`
4. **W11: CLAUDE.md:12 の `rules` パス修正**(実在しないパスの案内は毎セッション読み込まれる)
5. **W6: `pkill`/`killall` を ask へ移動**

### 検討の余地があるもの(設計判断を伴う)

6. **W7: レビュー系 skill の統合**(auditing-claude-config ⇄ claude-config-reviewer)。統合しないなら description の相互排他化と W10 の採点儀式廃止・freshness 緩和
7. **W8 + W9: agents の整理** — hand off 文言の go 版統一(8 ファイル)、architect/planner のトリガー差別化
8. **W3: 秘密ファイル保護の方針決定** — バリデータでの cat/head/tail カバーか、「Bash には効かない」の明文化か
9. **W13: build-error-resolver / flutter-reviewer の圧縮**(現行モデル適合の本丸)
10. **W12 + N 群: ドキュメント微修正** — tmux-lib.sh ルールのスコープ限定、rust-reviewer の diff 手順統一、N1(MAX_THINKING_TOKENS)と N13(additionalDirectories の `~`)の挙動確認

---

## 付記: 検証済みで問題なしと確認できた項目

- settings.json の全 13 hook エントリ ↔ `configs/claude/hooks/` 実ファイル: 完全一致
- settings.json / mcp.json の JSON 構文、schemastore スキーマ適合(`defaultMode: "auto"` は enum に正式収録)
- tmux emoji 優先度表(⚠️50/❌40/✅30/🤖20/⏳10): `.claude/rules/claude-config.md` ↔ `tmux-lib.sh` の `_tmux_priority` ↔ グローバル CLAUDE.md の三者一致。force-update イベント・✅→⏳ リセットも実装と一致
- tmux hooks の fail-open 設計(jq 不在時も本来の作業をブロックしない)、subagent カウンタの mkdir mutex(タイムアウト付きでデッドロックなし)
- `.claude/rules/` 2 ファイルの paths frontmatter、root CLAUDE.md の全参照の実在
- agents 14 本の name ↔ ファイル名一致、旧モデル ID 混入なし(全て opus/sonnet エイリアス)
- skills 9 本の scripts/references 参照の実在(壊れた参照なし)、`prompt-review` が skill 一覧に出ないのは `disable-model-invocation: true` によるもので正常
- context7 の permission tool 名と実 MCP tool 名の一致
- setup-claude.sh / install.sh のシェル堅牢性と symlink 整合(RTK.md の残骸を除く)

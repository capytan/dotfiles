---
name: gemini-proofread-prompt
description: 日本語の文章（貼られた文、ファイル、直前の Claude の返答の本文）を Gemini の Web アプリ（gemini.google.com）で校正するためのプロンプトを、オーナーの文体の規則と出力の形を全部入れて作り、pbcopy でクリップボードに入れる。「Gemini で校正するプロンプトを作って」「Gemini に推敲させたい」「Gemini 用の校正プロンプト」「この文を Gemini でチェックしたい」等で発動する。Claude 自身に推敲させたいときは使わない（`natural-japanese` や `yomiyasu` を使う）。技術書や記事の原稿の規範は `japanese-tech-writing` を使う。
allowed-tools: Bash(python3 ${CLAUDE_SKILL_DIR}/scripts/build_prompt.py *), Read, AskUserQuestion
---

# Gemini Proofread Prompt — Gemini の Web アプリに貼る校正プロンプトを作る

## このスキルの目的

オーナーは日本語の校正に Gemini の Web アプリを使う。Gemini はオーナーの好みを知らないので、規則と出力の形と対象の文章を 1 つのプロンプトにまとめて渡す。このスキルはプロンプトを作ってクリップボードに入れるところまでを受け持ち、校正そのものはしない。

規則の本文は `references/prompt-template.md` にある。規則を変えるときはこのファイルだけを直す。否定対比の変種と冗長表現は `natural-japanese` の `references/negation.md` と `references/patterns.md` から取ったもので、Gemini に単独で渡すためにコピーしている。あちらを直したら、こちらも合わせる。`scripts/build_prompt.py` がテンプレートのプレースホルダ（`{{DOC_TYPE}}`、`{{SPACING}}`、`{{FENCE}}`、`{{TEXT}}`）を埋め、認証情報らしい文字列を探し、`pbcopy` でクリップボードに入れる。

## When to Use This Skill

発動する依頼:
- 「Gemini で校正するプロンプトを作って」「Gemini に推敲させたい」「Gemini 用の校正プロンプト」
- 「この文（このファイル、さっきの返答）を Gemini でチェックしたい」

使わないケース:
- Claude 自身に推敲させたい → `natural-japanese`、`yomiyasu`
- 技術書や記事の原稿を執筆の規範に沿わせたい → `japanese-tech-writing`
- 英文の校正

## 手順

### 1. 対象の文章を決める

次の順に探す。

1. 依頼に貼られた文
2. 依頼に書かれたファイルのパス（Read で読む）
3. 「さっきの返答」「今の下書き」のように指されたときは、直前の Claude の返答の本文。下書きがコードブロックに入っているならその中身だけを使い、前後の説明は入れない

どれにも当たらないときは、AskUserQuestion で対象を聞く。

### 2. 入力してよい情報かを確かめる

対象の文章を読んで、次が含まれていそうなら、プロンプトを作る前に止めてオーナーに該当箇所を知らせる。

- 認証情報（トークン、API キー、パスワード、秘密鍵、接続文字列）
- 極秘の情報（「極秘」の表示があるもの、未公表の M&A や人事など）
- 本番の利用者の個人情報（氏名と連絡先の組み合わせ、口座番号、カード番号など）

オーナーが該当箇所を消すか、入力してよいと答えたら先に進む。`build_prompt.py` も認証情報らしい文字列と「極秘」を機械的に探し、見つけたら exit 3 で止まる。オーナーが誤検知と確かめたときだけ `--skip-sensitive-check` を付けて実行し直す。

### 3. 文章の種類とスペースの設定を決める

- `--type`: 文章の種類（「Slack のメッセージ」「Notion のページ」「PR の本文」「Obsidian のノート」など）。分からなければ省略する
- `--spacing`: 和文と半角英数字の間のスペース
  - `none`（既定）: 入れない。Slack、Notion、PR・Issue など人に渡す文書
  - `space`: 入れる。Obsidian のノート
  - 依頼で指定されたらそれに従う。指定が無ければ文章の種類で選び、迷ったら `none` にする

### 4. プロンプトを作ってクリップボードに入れる

スクリプトはファイルのパスを受け取り、組み立てたプロンプトを `pbcopy` でクリップボードに入れる。

```bash
python3 ${CLAUDE_SKILL_DIR}/scripts/build_prompt.py --spacing none --type "PR の本文" path/to/file.md
```

貼られた文や直前の返答が対象のときは、先に Write ツールで `/tmp/gemini-proofread-input.md` に書き出してから、そのパスを渡す。Bash のヒアドキュメントで渡すと、本文に `rm -rf` などの文字列があったとき PreToolUse の hook に止められる。

終わり方:
- exit 0: クリップボードに入れ、文字数と対象の文章の頭を stdout に出す
- exit 2: 文章が空か、区切りの `<<<本文ここまで>>>` を含んでいる。クリップボードは変えない
- exit 3: 認証情報らしい文字列か「極秘」を見つけた。クリップボードは変えない。stderr に出た行を示して手順 2 に戻る

`/tmp/gemini-proofread-input.md` に書き出したときは、exit のコードに関わらず、スクリプトが終わったら `rm -f /tmp/gemini-proofread-input.md` で消す。校正する本文が `/tmp` に残らないようにするため。

### 5. 会話に短く示す

プロンプト全体は会話に出さない。スクリプトの stdout（文字数、種類、スペースの設定、対象の文章の頭）を示し、次の一手として「gemini.google.com に貼り、返ってきた「## 校正後」のコードブロックをコピーして使う」と添える。Gemini の結果はそのまま使わず、元の文と diff で突き合わせてから使うことも添える。


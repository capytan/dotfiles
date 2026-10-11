#!/usr/bin/env python3
"""読点（、）の使い過ぎの候補を一覧にする。形態素解析は使わない目安のチェック。

使い方: python3 -I check_touten.py <file>   （引数なしなら標準入力）
指摘は候補であり、残すかどうかは references/patterns.md の K 節で判断する。
"""
import re
import sys

SHORT_SENTENCE = 25   # これ未満の文に読点があれば候補
SHORT_TOPIC = 5       # 文頭から「は、」までがこれ以下なら候補
SHORT_AFTER_CONJ = 20 # 文頭の接続詞・副詞の後の文がこれ以下なら候補
MAX_TEN = 4           # 一文の読点がこれ以上なら文を分ける候補
DOC_AVG = 1.5         # 文書全体で一文あたりの読点の平均がこれを超えたら見直す
SHORT_CLAUSE_LEN = 12 # 「〜前に、」などの節がこれ以下で、後ろも短ければ候補

# 区切り（文頭、「、読点）から「〜前に、」「〜とき、」などで終わる節と、その後ろ（次の区切りまで）
SHORT_CLAUSE = re.compile(
    r"(?:^|(?<=[「、]))([^「」、。]*?(?:前に|後に|あとで|ときに|とき|際に|ため|ので|から|なら|たら|れば|ると|ても|つつ))、([^「」、。]*)"
)

CONJ = ("また、", "さらに、", "そのため、", "つまり、", "実は、", "正直、",
        "なお、", "まず、", "次に、", "そして、", "これ、", "ただし、")


def strip_markup(text):
    text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)  # frontmatter
    text = re.sub(r"```.*?```", "", text, flags=re.S)          # コードブロック
    text = re.sub(r"`[^`]*`", "X", text)                        # インラインコード
    return text


def sentences(text):
    for lineno, line in enumerate(text.splitlines(), 1):
        body = re.sub(r"^\s*(#+|[-*]|\d+\.|>|\|)\s*", "", line)
        for s in re.split(r"(?<=[。！？])", body):
            s = s.strip()
            if s:
                yield lineno, s, False
        # 「」の中も文として調べる（主張や引用の中の読点を拾うため）。文書全体の集計には入れない
        for s in re.findall(r"「([^「」]*、[^「」]*)」", body):
            yield lineno, s.strip(), True


def check(text):
    findings, n_sent, n_ten = [], 0, 0
    for lineno, s, quoted in sentences(strip_markup(text)):
        ten = s.count("、")
        if not quoted:
            n_sent += 1
            n_ten += ten
        if ten == 0:
            continue
        reasons = []
        if len(s) < SHORT_SENTENCE:
            reasons.append(f"{len(s)}字の短い文に読点")
        m = re.match(r"^(.{1,%d}?(?:は|では|とは))、" % SHORT_TOPIC, s)
        if m:
            reasons.append(f"短い主題「{m.group(1)}、」")
        for c in CONJ:
            if s.startswith(c) and len(s) - len(c) <= SHORT_AFTER_CONJ:
                reasons.append(f"文頭「{c}」の後が短い")
        if len(re.findall(r"[しく]、", s)) >= 2:
            reasons.append("連用中止「〜し、〜し、」の連続")
        if re.search(r"と、(思|考|言|感)", s):
            reasons.append("引用の「と」の直後")
        for m in SHORT_CLAUSE.finditer(s):
            if len(m.group(1)) <= SHORT_CLAUSE_LEN and len(m.group(2)) <= SHORT_AFTER_CONJ:
                reasons.append(f"短い節「{m.group(1)}、」の後も短い")
        if ten >= MAX_TEN:
            reasons.append(f"読点{ten}個。文を分ける")
        if reasons:
            findings.append((lineno, s, reasons))
    return findings, n_sent, n_ten


def main():
    text = open(sys.argv[1], encoding="utf-8").read() if len(sys.argv) > 1 else sys.stdin.read()
    findings, n_sent, n_ten = check(text)
    for lineno, s, reasons in findings:
        print(f"L{lineno}: {' / '.join(reasons)}\n    {s}")
    avg = n_ten / n_sent if n_sent else 0
    flag = "  ← 見直す" if avg > DOC_AVG else ""
    print(f"\n文 {n_sent}、読点 {n_ten}、一文あたり {avg:.2f}{flag}、候補 {len(findings)} 件")


if __name__ == "__main__":
    main()

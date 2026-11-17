#!/usr/bin/env python3
"""references/prompt-template.md に対象の文章を埋め込み、Gemini に貼るプロンプトを pbcopy でクリップボードに入れる。

認証情報らしい文字列や「極秘」を見つけたら、クリップボードに触れずに該当行を stderr に出して exit 3 で終わる。
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

TEMPLATE = Path(__file__).resolve().parent.parent / "references" / "prompt-template.md"
END_MARKER = "<<<本文ここまで>>>"

SPACING = {"none": "入れない", "space": "入れる"}

# 和文に詰めて書かれた値も拾うため、\b ではなく ASCII の英数字だけを境界に使う
B = r"(?<![A-Za-z0-9_])"
SENSITIVE = [
    ("AWS のアクセスキー", re.compile(B + r"(AKIA|ASIA)[0-9A-Z]{16}(?![A-Za-z0-9])")),
    ("GitHub のトークン", re.compile(B + r"(gh[pousr]_[A-Za-z0-9]{20,}|github_pat_\w{20,})")),
    ("Slack のトークン", re.compile(B + r"xox[abeprs][-.][A-Za-z0-9-]{10,}")),
    ("API キー", re.compile(B + r"(sk-[A-Za-z0-9_-]{20,}|AIza[A-Za-z0-9_-]{35})")),
    ("Bearer トークン", re.compile(r"(?i)" + B + r"bearer\s+[A-Za-z0-9._~+/-]{20,}")),
    ("秘密鍵", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("接続文字列", re.compile(r"(?i)(mongodb(\+srv)?|postgres(ql)?|mysql|redis)://[^\s:/]+:[^\s@]+@")),
    # 値がリテラルに見えるときだけ拾う。関数呼び出し、属性、環境変数の参照（( . [ $ を含むもの）は拾わない
    ("パスワードやトークンの代入", re.compile(
        r"(?i)" + B + r"(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*['\"]?"
        r"[^\s'\"().\[\]$<>{}]{8,}(?=$|[\s'\",;])")),
    ("極秘の表示", re.compile(r"極秘")),
]


def find_sensitive(text: str) -> list[str]:
    return [
        f"{lineno}行目: {label}"
        for lineno, line in enumerate(text.splitlines(), 1)
        for label, pattern in SENSITIVE
        if pattern.search(line)
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", help="対象の文章のファイル")
    parser.add_argument("--type", default="Slack、Notion、PR・Issue など人に渡す文書", help="文章の種類")
    parser.add_argument("--spacing", choices=SPACING, default="none", help="和欧間スペース（既定は none）")
    parser.add_argument("--skip-sensitive-check", action="store_true",
                        help="オーナーが誤検知と確かめたときだけ使う")
    args = parser.parse_args()

    text = Path(args.path).read_text(encoding="utf-8").strip("\n")
    if not text.strip():
        print("対象の文章が空です", file=sys.stderr)
        return 2
    if END_MARKER in text:
        print(f"対象の文章に区切りの {END_MARKER} が含まれています", file=sys.stderr)
        return 2

    if not args.skip_sensitive_check:
        hits = find_sensitive(text)
        if hits:
            print("入力してよいか確かめる必要がある箇所があります:", file=sys.stderr)
            print("\n".join(hits), file=sys.stderr)
            return 3

    spacing = SPACING[args.spacing]
    # 校正後の全文を囲むフェンスは、本文の中で最も長いバッククォートの連なりより 1 つ長くする
    fence = "`" * max(4, max((len(r) for r in re.findall(r"`+", text)), default=0) + 1)
    values = {"DOC_TYPE": args.type, "SPACING": spacing, "FENCE": fence, "TEXT": text}
    # 1 回の置換で埋め込み、値の中の {{...}} を展開しない
    prompt = re.sub(r"\{\{(\w+)\}\}", lambda m: values.get(m[1], m[0]),
                    TEMPLATE.read_text(encoding="utf-8"))
    subprocess.run(["pbcopy"], input=prompt, text=True, check=True)

    lines = text.splitlines()
    print(f"クリップボードに入れました（{len(prompt)} 文字、種類: {args.type}、スペース: {spacing}）")
    print("対象の文章の頭:")
    print("\n".join(lines[:5]) + ("\n…" if len(lines) > 5 else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())

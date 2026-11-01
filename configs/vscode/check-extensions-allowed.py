#!/usr/bin/env python3
"""extensions.txt の拡張が、それぞれのエディタの規則で extensions.allowed に通るかを確かめる。

VS Code は configs/vscode/、Cursor は configs/cursor/ の extensions.txt と settings.json を見る。
依存 (extensionDependencies) とパックのメンバー (extensionPack) も辿る。依存が断られると本体の
インストールも失敗し、パックのメンバーが断られるとエラー無しに飛ばされる。
発行元の表示名と依存は ID からはわからないので、各エディタが使う gallery に問い合わせる。
CI (.github/workflows/editor-settings.yml) も使う
"""
import gzip
import json
import re
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# publisher_orgs は各エディタの product.json の extensionPublisherOrgs (VS Code 1.144.0 と Cursor 3.27.22 で確認)。
# 発行元の表示名がここに入っていれば表示名を、入っていなければ発行元の ID を発行元のキーとして引く。
# VS Code では表示名が "Microsoft" の発行元 (ms-python、vscjava、dbaeumer など) は microsoft のキーでしか通らず、
# Cursor は orgs が無いので ms-python などの ID のキーで通る。
# flags は gallery の extensionquery に渡す値。Cursor の gallery は Cursor 自身の拡張以外を
# IncludeFiles などを付けないと返さず、0x10000 (各版の最新だけ) を付けると大半を返さないので全版を取る
EDITORS = {
    "VS Code": {
        "dir": "configs/vscode",
        "gallery": "https://marketplace.visualstudio.com/_apis/public/gallery",
        "flags": 0x10193,
        "publisher_orgs": {"microsoft"},
        "not_in_gallery": set(),
    },
    "Cursor": {
        "dir": "configs/cursor",
        "gallery": "https://marketplace.cursorapi.com/_apis/public/gallery",
        "flags": 0x193,
        "publisher_orgs": set(),
        # Open VSX に無い。会社の Mac の Cursor には入っているので一覧に残している。
        # 表示名と依存がわからないので、ID と発行元の ID のキーだけで判定する
        "not_in_gallery": {"3w36zj6.textlint"},
    },
}
PROPERTY = "Microsoft.VisualStudio.Code."
STRING = r'"(?:\\.|[^"\\])*"'


def load_jsonc(path):
    """コメントと末尾のカンマを許す settings.json を読む。文字列の中の // は残す"""
    text = path.read_text()
    text = re.sub(rf"({STRING})|//[^\n]*|/\*.*?\*/", lambda m: m.group(1) or "", text, flags=re.S)
    text = re.sub(rf"({STRING})|,(\s*[}}\]])", lambda m: m.group(1) or m.group(2), text)
    return json.loads(text)


def allowed_config(settings):
    """VS Code の AllowedExtensionsService と同じく、キーを小文字にし、未設定か {"*": true} なら None"""
    value = settings.get("extensions.allowed")
    if not isinstance(value, dict):
        return None
    value = {k.lower(): v for k, v in value.items()}
    return None if value == {"*": True} else value


def query(editor, ids):
    """ID ごとに (発行元の表示名, 最新の安定版, 依存, パックのメンバー) を返す。gallery に無い ID は含まない"""
    criteria = [{"filterType": 8, "value": "Microsoft.VisualStudio.Code"}]
    criteria += [{"filterType": 7, "value": i} for i in ids]
    body = {"filters": [{"criteria": criteria, "pageNumber": 1, "pageSize": len(ids)}], "flags": editor["flags"]}
    req = urllib.request.Request(
        editor["gallery"] + "/extensionquery",
        data=json.dumps(body).encode(),
        # Cursor の gallery (Cloudflare) は urllib の既定の User-Agent を 403 で断る
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json;api-version=3.0-preview.1",
            "User-Agent": "capytan-dotfiles-check-extensions-allowed",
            # 全版を取る Cursor の応答は素のままだと 10MB を超える
            "Accept-Encoding": "gzip",
        },
    )
    with urllib.request.urlopen(req, timeout=120) as res:
        data = res.read()
        if res.headers.get("Content-Encoding") == "gzip":
            data = gzip.decompress(data)
    extensions = json.loads(data)["results"][0]["extensions"]
    found = {}
    for ext in extensions:
        versions = [
            {p["key"].removeprefix(PROPERTY): p["value"] for p in v.get("properties", [])} | {"version": v["version"]}
            for v in ext["versions"]
        ]
        if not versions:
            continue  # 版の無いものは gallery に無いものとして扱う
        # --install-extension は安定版を入れる。どちらの gallery も新しい順に返す。
        # engine の互換は見ないので、Cursor が古い版を入れるときはその版の依存とずれうる
        stable = next((v for v in versions if v.get("PreRelease") != "true"), versions[0])
        found[f'{ext["publisher"]["publisherName"]}.{ext["extensionName"]}'.lower()] = {
            "display_name": ext["publisher"]["displayName"].lower(),
            "version": stable["version"],
            "dependencies": split_ids(stable.get("ExtensionDependencies")),
            "pack": split_ids(stable.get("ExtensionPack")),
        }
    return found


def split_ids(value):
    return [s for i in (value or "").split(",") if (s := i.strip().lower())]


def denial(allowed, orgs, ext_id, info):
    """断られる理由を返す。通るなら None。info が None なら表示名がわからないので発行元の ID のキーで引く"""
    if allowed is None:
        return None
    publisher = ext_id.split(".")[0]
    display_name = info and info["display_name"]
    key = ext_id if ext_id in allowed else (display_name if display_name in orgs else publisher)
    if key not in allowed:
        if allowed.get("*") is True:
            return None
        hint = f' (the publisher display name "{key}" is matched, not "{publisher}")' if key != publisher else ""
        return f'no "{ext_id}" or "{key}" key{hint}'
    value = allowed[key]
    if value is False:
        return f'"{key}" is false'
    if info and isinstance(value, list) and info["version"] not in [v.split("@")[0] for v in value]:
        return f'"{key}" does not list the latest stable version {info["version"]}'
    return None


def check(name, editor):
    base = ROOT / editor["dir"]
    allowed = allowed_config(load_jsonc(base / "settings.json"))
    listed = [line.strip().lower() for line in (base / "extensions.txt").read_text().splitlines() if line.strip()]
    errors = []
    info = {}
    # 一覧の拡張からの経路。表示に使う
    via = {i: [i] for i in listed}
    pending = list(via)
    while pending:
        try:
            info |= query(editor, pending)
        except OSError as e:  # urllib の HTTPError と URLError、timeout を含む
            print(f"{name}: query to {editor['gallery']} failed: {e}", file=sys.stderr)
            return False
        queue, pending = pending, []
        for ext_id in queue:
            path = " -> ".join(via[ext_id])
            ext = info.get(ext_id)
            if ext is None:
                if ext_id not in editor["not_in_gallery"]:
                    errors.append(f"{path}: not found in {editor['gallery']}")
                    continue
            reason = denial(allowed, editor["publisher_orgs"], ext_id, ext)
            if reason:
                errors.append(f"{path}: not allowed: {reason}")
            for dep in ext["dependencies"] + ext["pack"] if ext else []:
                # vscode.* は組み込みの拡張。gallery には無く、allowed でも判定しない
                if dep not in via and not dep.startswith("vscode."):
                    via[dep] = via[ext_id] + [dep]
                    pending.append(dep)
    for e in errors:
        print(f"{name}: {e}", file=sys.stderr)
    print(f"{name}: checked {len(via)} extensions ({len(listed)} listed), {len(errors)} errors")
    return not errors


def main():
    results = [check(name, editor) for name, editor in EDITORS.items()]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())

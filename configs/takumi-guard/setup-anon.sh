#!/usr/bin/env bash
# Takumi Guard (https://flatt.tech/takumi/features/guard/) の匿名の registry を、ユーザー単位の設定に書く。
# 匿名はトークン不要で、悪性パッケージのブロックだけが効く。install.sh からは呼ばず、使う端末で手で実行する。
# 設定ファイルがすでにあれば何もしない (組織トークンなどの設定を上書きしない)。lockfile への影響は README の
# "Takumi Guard (anonymous)" を参照。
set -euo pipefail

NPM_REGISTRY=https://npm.flatt.tech/
PYPI_INDEX=https://pypi.flatt.tech/simple/
config_home=${XDG_CONFIG_HOME:-$HOME/.config}

# pip の user 設定の場所 (https://pip.pypa.io/en/stable/topics/configuration/)。macOS は ~/Library/Application Support/pip があれば
# そちらで、無ければ XDG_CONFIG_HOME を見ずに ~/.config/pip。legacy の ~/.pip/pip.conf があれば、それを既存の設定とみなす
pip_conf="$config_home/pip/pip.conf"
if [[ "$(uname -s)" == Darwin ]]; then
  pip_conf="$HOME/.config/pip/pip.conf"
  [[ -d "$HOME/Library/Application Support/pip" ]] && pip_conf="$HOME/Library/Application Support/pip/pip.conf"
fi
[[ -e "$HOME/.pip/pip.conf" ]] && pip_conf="$HOME/.pip/pip.conf"

# write_if_absent <path> <content>
write_if_absent() {
  # -L: 壊れた symlink も既存とみなし、リンク先に書かない
  if [[ -e "$1" || -L "$1" ]]; then
    if grep -qE '^[^#;]*flatt\.tech' "$1" 2>/dev/null; then
      echo "[OK]   $1 は Takumi Guard を向いている"
    else
      echo "[WARN] $1 がすでにあるので書かない。Takumi Guard を使うなら手で直す" >&2
    fi
    return
  fi
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >"$1"
  echo "[NEW]  $1"
}

# npm・pnpm・yarn v1・bun が読む
write_if_absent "$HOME/.npmrc" "registry=$NPM_REGISTRY"
write_if_absent "$HOME/.yarnrc.yml" "npmRegistryServer: \"$NPM_REGISTRY\""
write_if_absent "$pip_conf" "[global]
index-url = $PYPI_INDEX"
write_if_absent "$config_home/uv/uv.toml" "[[index]]
url = \"$PYPI_INDEX\"
default = true"

# bun は ~/.bunfig.toml の registry を ~/.npmrc より優先する。書かずに確かめるだけ
bunfig="$HOME/.bunfig.toml"
if grep -qE '^[^#]*registry' "$bunfig" 2>/dev/null && ! grep -qE '^[^#]*flatt\.tech' "$bunfig"; then
  echo "[WARN] bun は $bunfig の registry を使う。Takumi Guard を使うなら手で直す" >&2
fi

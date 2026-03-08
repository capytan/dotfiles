#!/usr/bin/env zsh
# zeno.zsh - snippet expansion, fzf completion, smart history

# Graceful degradation
command -v deno &>/dev/null || return 0
ZENO_DIR="${HOME}/.local/share/zeno"
[[ -f "$ZENO_DIR/zeno.zsh" ]] || return 0

# Environment
export ZENO_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zeno"
export ZENO_ENABLE_FZF_TMUX=1
export ZENO_GIT_CAT="bat --color=always --style=plain"
export ZENO_GIT_TREE="eza --tree --icons --color=always"

source "$ZENO_DIR/zeno.zsh"

# Keybindings
bindkey ' '    zeno-auto-snippet
bindkey '^m'   zeno-auto-snippet-and-accept-line
bindkey '^i'   zeno-completion
bindkey '^r'   zeno-history-selection
bindkey '^x '  zeno-insert-space
bindkey '^x^m' accept-line

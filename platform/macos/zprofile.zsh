#!/usr/bin/env zsh
# macOS-specific login shell settings

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Rye
[[ -f "$HOME/.rye/env" ]] && source "$HOME/.rye/env"

# JetBrains Toolbox
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# OrbStack
[[ -f ~/.orbstack/shell/init.zsh ]] && source ~/.orbstack/shell/init.zsh 2>/dev/null

#!/usr/bin/env zsh
# macOS-specific interactive shell settings

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"


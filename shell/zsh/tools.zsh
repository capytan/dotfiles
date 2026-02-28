#!/usr/bin/env zsh
# Development tools setup

# Editor
export EDITOR=nvim

# Neovim aliases
alias vim='nvim'
alias v='nvim'

# mise (development environment manager)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
  eval "$($HOME/.local/bin/mise activate --shims)"
fi

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

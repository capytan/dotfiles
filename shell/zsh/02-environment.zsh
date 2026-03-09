#!/usr/bin/env zsh
# Environment variables and PATH exports

# Editor
export EDITOR=nvim

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Go binaries
export PATH="$PATH:$HOME/go/bin"

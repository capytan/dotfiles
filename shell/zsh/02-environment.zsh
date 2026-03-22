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

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Go binaries
export PATH="$PATH:$HOME/go/bin"

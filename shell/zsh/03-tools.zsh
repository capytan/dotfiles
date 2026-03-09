#!/usr/bin/env zsh
# Development tool manager activation

# mise (development environment manager)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
  eval "$($HOME/.local/bin/mise activate --shims)"
fi

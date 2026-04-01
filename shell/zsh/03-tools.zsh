#!/usr/bin/env zsh
# Development tool manager activation

# mise (development environment manager)
if [[ -x "$HOME/.local/bin/mise" ]]; then
  eval "$($HOME/.local/bin/mise activate zsh)"
fi

# git-wt (worktree manager)
if command -v git-wt &>/dev/null; then
  eval "$(git wt --init zsh)"
fi

# safe-chain
if [[ -f "$HOME/.safe-chain/scripts/init-posix.sh" ]]; then
  source "$HOME/.safe-chain/scripts/init-posix.sh"
fi

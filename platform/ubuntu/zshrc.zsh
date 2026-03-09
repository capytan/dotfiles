#!/usr/bin/env zsh
# Ubuntu-specific interactive shell settings

# dircolors
eval "$(dircolors -b)"

# asdf completions
if [[ -n "$ASDF_DIR" ]]; then
  fpath=(${ASDF_DIR}/completions $fpath)
fi

# Prompt (Ubuntu uses simple prompt, no starship)
autoload -Uz promptinit
promptinit
prompt adam1

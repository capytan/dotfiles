#!/usr/bin/env zsh
# Ubuntu-specific interactive shell settings

# install.sh links nvim here; keep it ahead of /usr/bin so it wins over apt's neovim.
# Set here, not in zprofile: terminals on Ubuntu start non-login shells
path=("$HOME/.local/bin" ${path:#$HOME/.local/bin})

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

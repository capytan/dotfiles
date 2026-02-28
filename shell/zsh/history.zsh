#!/usr/bin/env zsh
# History settings and shell options

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt share_history         # share history between sessions
setopt hist_ignore_dups      # don't add the same command as previous one to history
setopt hist_ignore_all_dups  # delete the old command if the same command is added again
setopt hist_ignore_space     # don't add commands that start with a space to history
setopt hist_reduce_blanks    # delete extra spaces from history

# Shell convenience options (rescued from legacy root .zshrc)
setopt auto_cd
setopt auto_pushd
setopt correct

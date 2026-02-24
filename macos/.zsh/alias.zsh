#!/usr/bin/env zsh
# Shell aliases (non-git)
# Git aliases and helper functions → git-aliases.zsh

# =============================================================================
# File Listing
# =============================================================================
alias l='ls -lFh'
alias la='ls -lAFh'
alias lr='ls -tRFh'
alias lt='ls -ltFh'
alias ll='ls -l'
alias ldot='ls -ld .*'
alias lS='ls -1FSsh'
alias lart='ls -1Fcart'
alias lrt='ls -1Fcrt'
alias lsr='ls -lARFh'
alias lsn='ls -1'

# =============================================================================
# Directory Navigation
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

# =============================================================================
# Search and Filter
# =============================================================================
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
alias ff='find . -type f -name'

# =============================================================================
# Process and System
# =============================================================================
alias p='ps -f'
alias t='tail -f'
alias k9='kill -9'
alias killall='killall -9'

# =============================================================================
# History
# =============================================================================
alias h='history'
alias hgrep='fc -El 0 | grep'

# =============================================================================
# Disk Usage
# =============================================================================
alias dud='du -d 1 -h'
alias duf='du -sh *'

# =============================================================================
# Miscellaneous
# =============================================================================
alias sortnr='sort -n -r'
alias unexport='unset'
alias help='man'

# =============================================================================
# Global Aliases
# =============================================================================
alias -g G='| grep'
alias -g L='| less'
alias -g NUL='> /dev/null 2>&1'
alias -g CA='2>&1 | cat -A'
alias -g H='| head'
alias -g T='| tail'
alias -g LL='2>&1 | less'
alias -g M='| most'
alias -g NE='2> /dev/null'

# =============================================================================
# macOS specific
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles TRUE && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles FALSE && killall Finder'
fi

# =============================================================================
# Modern CLI tools (installed via Brewfile)
# =============================================================================
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
fi
if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias l='eza -lh --icons'
    alias la='eza -lah --icons'
    alias lt='eza --tree --icons -L 2'
fi
if command -v fd &>/dev/null; then
    alias ff='fd'
fi
if command -v dust &>/dev/null; then
    alias du='dust'
fi
if command -v btm &>/dev/null; then
    alias top='btm'
fi

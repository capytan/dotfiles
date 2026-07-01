#!/usr/bin/env zsh
# Shell aliases (non-git, non-zeno)
# Git aliases → zeno snippets (configs/zeno/snippets.yml)
# Global aliases (pipes) → zeno context snippets

# =============================================================================
# Editor
# =============================================================================
alias vim='nvim'
alias v='nvim'

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
# macOS specific
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles TRUE && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles FALSE && killall Finder'
fi

# =============================================================================
# Claude Code - past model shortcuts
# `/model` picker only allows one custom entry, so wrap older models as aliases.
# The `[1m]` suffix (1M context) contains glob metacharacters, so quote it.
# =============================================================================
alias cc-opus46='claude --model claude-opus-4-6'
alias cc-opus46-1m='claude --model "claude-opus-4-6[1m]"'
alias cc-opus47='claude --model claude-opus-4-7'
alias cc-opus47-1m='claude --model "claude-opus-4-7[1m]"'
alias cc-opus48='claude --model claude-opus-4-8'
alias cc-opus48-1m='claude --model "claude-opus-4-8[1m]"'

# =============================================================================
# Modern CLI tools (installed via Brewfile)
# Skip in Claude Code sessions to avoid confusing Claude with aliased output
# =============================================================================
if [[ -z "$CLAUDECODE" ]]; then
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
fi

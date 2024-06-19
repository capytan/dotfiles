# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

# setting environment variables
## encoding
export LANG=ja_JP.UTF-8

# auto-completion & prompt
autoload -U compinit promptinit
compinit
promptinit

# This will set the default prompt to the walters theme
prompt adam1

# editor
export EDITOR=vim

# direnv
eval "$(direnv hook zsh)"

# rbenv
eval "$(rbenv init - zsh)"

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history

# aliases
alias vim='vim'
alias v='vim'
alias g='git'
alias gb='git branch'
alias gs='git switch'
alias gsd='git switch develop'
alias gr='git restore'
alias gd='git diff'
alias gdh='git diff HEAD'
alias gst='git status'
alias gf='git fetch --prune'
alias gp='git pull --prune'
alias be='bundle exec'
alias ls='ls -G'
alias ll='ls -alF'

# fzf completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# for fzf completion
# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# for cd completion
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                        -o -type d -print 2> /dev/null | fzf +m) &&
                      cd "$dir"
}

# ghq with fzf
function fzf-src () {
  local selected_dir=$(ghq list -p | fzf --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-src
bindkey '^]' fzf-src

# Volta - The Hassle-Free JavaScript Tool Manager
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# OpenSSL@1.1 の場合のセットアップ
# export PATH="$HOMEBREW_PREFIX/opt/openssl@1.1/bin:$PATH"
# export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@1.1/lib/pkgconfig"
# export RUBY_CONFIGURE_OPTS="$RUBY_CONFIGURE_OPTS --with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@1.1"

# OpenSSL@3 の場合のセットアップ
# export PATH="$HOMEBREW_PREFIX/opt/openssl@3/bin:$PATH"
# export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@3/lib/pkgconfig"
# export RUBY_CONFIGURE_OPTS="$RUBY_CONFIGURE_OPTS --enable-yjit --with-openssl-dir=$HOMEBREW_PREFIX/opt/openssl@3"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

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

# ruby-build
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# pyenv, pyenv-virtualenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Node Version Manager(nvm)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

# Kubernetes
# Install kubectl stable binary with curl on macOS
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
# Target ver
# curl -LO "https://dl.k8s.io/release/v1.21.12/bin/darwin/amd64/kubectl"
alias kubectl='kubectl1_21'
alias kb='kubectl1_21'
alias k='kubectl1_21'

# krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

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

# ghq with peco
function peco-src () {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

# brew keg-only
## mysql@5.7 is keg-only, which means it was not symlinked into /usr/local,
## because this is an alternate version of another formula.
##
## If you need to have mysql@5.7 first in your PATH, run:
##   echo 'export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"' >> ~/.zshrc
##
## For compilers to find mysql@5.7 you may need to set:
##   export LDFLAGS="-L/usr/local/opt/mysql@5.7/lib"
##   export CPPFLAGS="-I/usr/local/opt/mysql@5.7/include"
##
## For pkg-config to find mysql@5.7 you may need to set:
##   export PKG_CONFIG_PATH="/usr/local/opt/mysql@5.7/lib/pkgconfig"

export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
## export LDFLAGS="-L/usr/local/opt/mysql@5.6/lib"
## export CPPFLAGS="-I/usr/local/opt/mysql@5.6/include"

export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
# export LDFLAGS="-L/usr/local/opt/imagemagick@6/lib"
# export CPPFLAGS="-I/usr/local/opt/imagemagick@6/include"
# export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"

# gnu command
PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/capytan/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/capytan/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/capytan/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/capytan/google-cloud-sdk/completion.zsh.inc'; fi

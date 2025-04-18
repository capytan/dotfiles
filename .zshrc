# encoding
export LANG=ja_JP.UTF-8

# colors
autoload -U colors && colors

# completions

# for heroku completion
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# for git completion
fpath=(~/dotfiles $fpath)
autoload -Uz compinit && compinit

# for fzf completion
# fbr - checkout git branch
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fbr - checkout git branch (including remote branches)
fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

fzf-add() {
	local selected
	selected="$(git status -s | fzf | cut -c3-)"
	if [ -n "$selected" ]; then
		echo $selected
		git add $selected
	fi
}
alias fa="fzf-add"

# for cd completion
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                        -o -type d -print 2> /dev/null | fzf +m) &&
                      cd "$dir"
                  }

# editor
export EDITOR=vim

# history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history

# prompt
# git-completion
# https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
source ~/dotfiles/git-utils/.git-prompt.sh
setopt PROMPT_SUBST ; PROMPT='╭─○ %{$fg_bold[green]%}%n%{$reset_color%}:%{$fg_bold[cyan]%}%~ %{$reset_color%}$(__git_ps1 " (%s)")
╰─○ '

# aliases
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

# other
setopt auto_cd
setopt auto_pushd
setopt correct

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# direnv
eval "$(direnv hook zsh)"
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
export PATH="/usr/local/opt/sphinx-doc/bin:$PATH"
export PATH="/usr/local/opt/libxml2/bin:$PATH"
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
export PATH="/usr/local/opt/openjdk/bin:$PATH"
# export PATH="$(brew --prefix qt@5.5)/bin:$PATH"
export PATH="$(brew --prefix imagemagick@6)/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"

export PATH="/usr/local/opt/m4/bin:$PATH"
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export PATH="/usr/local/opt/python@3.8/bin:$PATH"
export PATH="/usr/local/opt/krb5/bin:$PATH"
export PATH="/usr/local/opt/krb5/sbin:$PATH"
export PATH="/usr/local/opt/sphinx-doc/bin:$PATH"
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

# Elasticsearch@6
export PATH="/usr/local/opt/elasticsearch@6/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ymizuguchi/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/ymizuguchi/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/ymizuguchi/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/ymizuguchi/google-cloud-sdk/completion.zsh.inc'; fi

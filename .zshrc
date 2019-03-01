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
source ~/dotfiles/.git-prompt.sh
setopt PROMPT_SUBST ; PROMPT='╭─○ %{$fg_bold[green]%}%n%{$reset_color%}:%{$fg_bold[cyan]%}%~ %{$reset_color%}$(__git_ps1 " (%s)")
╰─○ '

# aliases
alias v='vim'
alias reload='source ~/.zshrc'
alias g='git'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gdh='git diff HEAD'
alias gst='git status'
alias gp='git pull'
alias dc='docker'
alias dcc='docker-compose'

# other
setopt auto_cd
setopt auto_pushd
setopt correct

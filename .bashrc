export EDITOR=atom
export PATH=$HOME/.nodebrew/current/bin:$PATH

# prompt
# show git branch
# https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
source ~/dotfiles/git-completion.bash
source ~/dotfiles/.git-prompt.sh
export PS1='╭─○ \[\033[1;32m\]\u\[\033[m\]:\[\033[1;36m\]\w \[\033[m\]$(__git_ps1 "(%s)")\n\[\033[m\]╰─○ '

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

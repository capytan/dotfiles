# anyenv
eval "$(anyenv init -)"

# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

test -r ~/.bashrc && . ~/.bashrc
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

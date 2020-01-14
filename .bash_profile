# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

# nodenv
eval "$(nodenv init -)"

test -r ~/.bashrc && . ~/.bashrc
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

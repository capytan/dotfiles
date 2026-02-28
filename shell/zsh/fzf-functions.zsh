#!/usr/bin/env zsh
# Shared fzf functions (cross-platform)

# fbr - switch git branch (local)
fbr() {
  local branches branch
  branches=$(git branch -vv) &&
  branch=$(echo "$branches" | fzf +m) &&
  git switch $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fbrm - switch git branch (including remote)
fbrm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fzf-add - interactive git add
fzf-add() {
  local selected
  selected="$(git status -s | fzf | cut -c3-)"
  if [ -n "$selected" ]; then
    echo $selected
    git add $selected
  fi
}
alias fa="fzf-add"

# fd - interactive cd into directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                        -o -type d -print 2> /dev/null | fzf +m) &&
                      cd "$dir"
}

# fzf-src - ghq + fzf repository switcher
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

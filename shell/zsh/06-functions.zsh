#!/usr/bin/env zsh
# Shell functions (git helpers, fzf-src)

# =============================================================================
# Git helper functions (used by zeno snippets via evaluate: true)
# =============================================================================

git_main_branch() {
    command git rev-parse --git-dir &>/dev/null || return
    local ref
    for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,master}; do
        if command git show-ref -q --verify $ref; then
            echo ${ref:t}
            return 0
        fi
    done
    echo master
    return 1
}

git_develop_branch() {
    command git rev-parse --git-dir &>/dev/null || return
    local branch
    for branch in dev devel develop development; do
        if command git show-ref -q --verify refs/heads/$branch; then
            echo $branch
            return 0
        fi
    done
    echo develop
    return 1
}

git_current_branch() {
    local ref
    ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null)
    local ret=$?
    if [[ $ret != 0 ]]; then
        [[ $ret == 128 ]] && return  # no git repo.
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
    fi
    echo ${ref#refs/heads/}
}

# =============================================================================
# fbr / fbrm - fzf git branch switcher
# =============================================================================

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

# =============================================================================
# fzf-add / fa - interactive git add
# =============================================================================

fzf-add() {
  local selected
  selected="$(git status -s | fzf | cut -c3-)"
  if [ -n "$selected" ]; then
    echo $selected
    git add $selected
  fi
}
alias fa="fzf-add"

# =============================================================================
# gtl - git tag list with version sorting
# =============================================================================
gtl() { git tag --sort=-v:refname -n --list "${1}*" }
alias gtl='noglob gtl'

# =============================================================================
# fzf-src - ghq + fzf repository switcher (Ctrl-])
# =============================================================================
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

# =============================================================================
# tfj - Terraform directory fuzzy finder (fzf + rg)
# https://github.com/shmokmt/tfj
# =============================================================================

tfj() {
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$git_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi
    local selected_dir=$(
        cd "$git_root"
        rg --files --hidden --no-ignore --glob '**/.terraform/terraform.tfstate' . 2>/dev/null |
            sed 's|/\.terraform/terraform\.tfstate||' |
            sort -u |
            sed 's|^\./||' |
            fzf --prompt="Select Terraform directory: " --height=40% --reverse
    )
    if [[ -n "$selected_dir" ]]; then
        cd "$git_root/$selected_dir"
    else
        echo "No directory selected"
        return 1
    fi
}

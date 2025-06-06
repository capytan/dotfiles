#!/usr/bin/env zsh

# Common Shell Aliases
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

# Directory Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'

# File Operations (with safety)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Search and Filter
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
alias fd='find . -type d -name'
alias ff='find . -type f -name'

# Process and System
alias p='ps -f'
alias t='tail -f'
alias k9='kill -9'
alias killall='killall -9'

# History
alias h='history'
alias hgrep='fc -El 0 | grep'

# Disk Usage
alias dud='du -d 1 -h'
alias duf='du -sh *'

# Miscellaneous
alias sortnr='sort -n -r'
alias unexport='unset'
alias help='man'

# Global Aliases
alias -g G='| grep'
alias -g L='| less'
alias -g NUL='> /dev/null 2>&1'
alias -g CA='2>&1 | cat -A'
alias -g H='| head'
alias -g T='| tail'
alias -g LL='2>&1 | less'
alias -g M='| most'
alias -g NE='2> /dev/null'

# Git Aliases
alias g='git'
alias gst='git status'
alias gss='git status -s'
alias gsb='git status -sb'

# Git Add
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'
alias gap='git apply'
alias gapt='git apply --3way'

# Git Branch
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'

# Git Checkout
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcB='git checkout -B'
alias gcd='git checkout $(git_develop_branch)'
alias gcm='git checkout $(git_main_branch)'
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# Git Commit
alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcam='git commit --all --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcsm='git commit --signoff --message'
alias gcmsg='git commit --message'
alias gcs='git commit --gpg-sign'

# Git Clone
alias gcl='git clone --recurse-submodules'
alias gclean='git clean --interactive -d'

# Git Diff
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdup='git diff @{upstream}'
alias gdw='git diff --word-diff'

# Git Fetch
alias gf='git fetch'
alias gfa='git fetch --all --prune --jobs=10'
alias gfo='git fetch origin'

# Git Log
alias glg='git log --stat'
alias glgp='git log --stat --patch'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'

# Git Merge
alias gm='git merge'
alias gma='git merge --abort'
alias gmom='git merge origin/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
alias gmum='git merge upstream/$(git_main_branch)'

# Git Pull
alias gl='git pull'
alias glr='git pull --rebase'
alias glrv='git pull --rebase -v'
alias glra='git pull --rebase --autostash'
alias glrav='git pull --rebase --autostash -v'
alias glrom='git pull --rebase origin $(git_main_branch)'
alias glrum='git pull --rebase upstream $(git_main_branch)'
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'

# Git Push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf='git push --force-with-lease --force-if-includes'
alias gpf!='git push --force'
alias gpoat='git push origin --all && git push origin --tags'
alias gpr='git pull --rebase'
alias gpu='git push upstream'
alias gpv='git push --verbose'

# Git Rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'

# Git Remote
alias gr='git remote'
alias gra='git remote add'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grup='git remote update'
alias grv='git remote --verbose'

# Git Reset
alias grh='git reset'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias groh='git reset origin/$(git_current_branch) --hard'
alias grok='git reset origin/$(git_current_branch) --keep'
alias gros='git reset origin/$(git_current_branch) --soft'

# Git Restore
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

# Git Remove
alias grm='git rm'
alias grmc='git rm --cached'

# Git Stash
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show'
alias gstu='git stash --include-untracked'
alias gstall='git stash --all'

# Git Show
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'

# Git Switch
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'

# Git Tag
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gunignore='git update-index --no-assume-unchanged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "--wip--" && git reset HEAD~1'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'

# Other Git Commands
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gfg='git ls-files | grep'
alias gcount='git shortlog --summary --numbered'
alias gke='\gitk --all $(git log --walk-reflogs --pretty=%h) &!'
alias gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'

# macOS specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias showfiles='defaults write com.apple.finder AppleShowAllFiles TRUE && killall Finder'
    alias hidefiles='defaults write com.apple.finder AppleShowAllFiles FALSE && killall Finder'
fi

# Helper functions that some git aliases depend on
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

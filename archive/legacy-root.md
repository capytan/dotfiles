# Legacy Root Files Archive

Archived: 2026-02-28
Reason: Intel Mac era files, no longer linked from any active configuration.

---

## .zshrc (root)

Full content of the root-level `.zshrc` used during the Intel Mac era.

```zsh
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
source ~/dotfiles/git-utils/.git-prompt.sh
setopt PROMPT_SUBST ; PROMPT='...' # custom prompt with git info

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
export PATH="$(brew --prefix imagemagick@6)/bin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/imagemagick@6/lib/pkgconfig"
export PATH="/usr/local/opt/m4/bin:$PATH"
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export PATH="/usr/local/opt/sqlite/bin:$PATH"
export PATH="/usr/local/opt/python@3.8/bin:$PATH"
export PATH="/usr/local/opt/krb5/bin:$PATH"
export PATH="/usr/local/opt/krb5/sbin:$PATH"
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
export PATH="/usr/local/opt/elasticsearch@6/bin:$PATH"
# Google Cloud SDK
if [ -f '/Users/ymizuguchi/google-cloud-sdk/path.zsh.inc' ]; then . '...'; fi
if [ -f '/Users/ymizuguchi/google-cloud-sdk/completion.zsh.inc' ]; then . '...'; fi
```

### Settings rescued to new structure:
- `fzf-add()` + `fa` alias -> `shell/zsh/fzf-functions.zsh`
- `setopt auto_cd auto_pushd correct` -> `shell/zsh/history.zsh`
- `export LANG=ja_JP.UTF-8` -> `shell/zprofile`
- `export EDITOR=vim` -> updated to `nvim` in `shell/zsh/tools.zsh`

---

## .zprofile (root)

```zsh
# rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# tfenv
export PATH="$HOME/.tfenv/bin:$PATH"

# nodenv
eval "$(nodenv init -)"

# phpenv
export PATH="$HOME/.phpenv/bin:$PATH"
eval "$(phpenv init -)"

export PATH="$HOME/.cargo/bin:$PATH"
```

All version managers (rbenv, tfenv, nodenv, phpenv) replaced by `mise` in current setup.

---

## dotfileslink.sh (root)

```sh
#!/bin/sh
ln -sf ~/dotfiles/.zprofile ~/.zprofile
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.ideavimrc ~/.ideavimrc
ln -sf ~/dotfiles/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf ~/dotfiles/init.vim ~/.config/nvim/init.vim
```

Replaced by `macos/dotfileslink.sh` (now `install.sh`).

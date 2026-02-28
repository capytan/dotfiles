# Legacy macOS Intel Archive

Archived: 2026-02-28
Source: `macos_intel/` directory
Reason: Intel Mac era configurations, superseded by Apple Silicon setup.

---

## Migration Map

| Intel era tool | Current replacement |
|---|---|
| rbenv | mise |
| nodenv | mise |
| pyenv | mise |
| nvm | mise |
| tfenv | mise |
| phpenv | mise |
| peco | fzf |
| Amazon Q | Kiro CLI |
| vim | nvim (LazyVim) |
| .tmux.conf (standalone) | configs/tmux/tmux.conf |
| Google Cloud SDK (hardcoded) | Removed |
| kubectl aliases | Removed |
| krew | Removed |

---

## .zshrc (macos_intel)

```zsh
# Amazon Q pre block
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "..."

# setting environment variables
export LANG=ja_JP.UTF-8

# auto-completion & prompt
autoload -U compinit promptinit
compinit
promptinit
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
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Golang
export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

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
alias kubectl='kubectl1_21'
alias kb='kubectl1_21'
alias k='kubectl1_21'

# krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# fzf completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fbr, fbrm, fd (same as current)

# ghq with peco (replaced by fzf-src)
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

# brew keg-only paths
export PATH="/usr/local/opt/mysql@5.6/bin:$PATH"
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"

# Google Cloud SDK (hardcoded path)
if [ -f '/Users/capytan/google-cloud-sdk/path.zsh.inc' ]; then . '...'; fi
if [ -f '/Users/capytan/google-cloud-sdk/completion.zsh.inc' ]; then . '...'; fi

# Amazon Q post block
```

---

## .zprofile (macos_intel)

```zsh
# Amazon Q pre block
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "..."

# Amazon Q post block
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "..."
```

---

## .tmux.conf (macos_intel)

```
set -g prefix C-a
set -g base-index 1
setw -g pane-base-index 1

# status bar
set-option -g status-position top
set-option -g status-interval 1
set-option -g status-justify "centre"
set-option -g status-bg "colour238"
set-option -g status-fg "colour255"
set-option -g status-left-length 20
set-option -g status-left "#[fg=colour255,bg=colour241]Session: #S #[default]"
set-option -g status-right-length 60
set-option -g status-right "#[fg=colour255,bg=colour241] #h | LA: #(cut -d' ' -f-3 /proc/loadavg) | %m/%d %H:%M:%S#[default]"

# window option
set-window-option -g window-status-format " #I: #W "
set-window-option -g window-status-current-format "#[fg=colour255,bg=colour27,bold] #I: #W #[default]"

# vim navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r C-h resize-pane -L 10
bind -r C-l resize-pane -R 10
bind -r C-j resize-pane -D 10
bind -r C-k resize-pane -U 10

set-option -g history-limit 15000
```

---

## .ideavimrc (macos_intel)

```
set clipboard-=ideaput
set hlsearch
set ignorecase
set smartcase
set cmdheight=2
set laststatus=2
```

---

## .direnvrc (macos_intel)

```zsh
use_aws_profile(){
  profile_name=$1
  export $(aws-vault exec $profile_name -- env | grep AWS_ | grep -v AWS_VAULT)
}
```

---

## defaults.sh (macos_intel)

```sh
# Do not write RAM backup during sleep (Intel-specific)
sudo pmset hibernatemode 0

# hidden
defaults write com.apple.finder AppleShowAllFiles TRUE

# vscode
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
```

Note: `pmset hibernatemode 0` was Intel-specific workaround for sleep crashes.
The Finder and VSCode settings are now in `platform/macos/defaults.sh`.

---

## dotfileslink.sh (macos_intel)

```sh
#!/bin/sh
ln -sf ~/dotfiles/macos_intel/.direnvrc ~/.direnvrc
ln -sf ~/dotfiles/macos_intel/.ideavimrc ~/.ideavimrc
ln -sf ~/dotfiles/macos_intel/.tmux.conf ~/.tmux.conf
ln -sf ~/dotfiles/macos_intel/.vimrc ~/.vimrc
ln -sf ~/dotfiles/macos_intel/.zshrc ~/.zshrc

# ln -sf ~/dotfiles/macos_intel/.zprofile ~/.zprofile
# ln -sf ~/dotfiles/macos_intel/.vscode/settings.json ~/Library/ApplicationSupport/Code/User/settings.json
```

---

## .vimrc (macos_intel)

Moved to `configs/vim/vimrc` for reference.
vim-plug based config with plugins: fern, commentary, endwise, fugitive, surround,
airline, gitgutter, grep, delimitMate, tagbar, ale, indentLine, polyglot, fzf,
vim-session, ultisnips, molokai, html/css plugins, ruby/rails plugins, vim-lsp.

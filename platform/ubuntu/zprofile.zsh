#!/usr/bin/env zsh
# Ubuntu-specific login shell settings

# Golang
export PATH=$PATH:/usr/local/go/bin

# asdf
[[ -f "$HOME/.asdf/asdf.sh" ]] && . "$HOME/.asdf/asdf.sh"

# Rust Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

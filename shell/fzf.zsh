# fzf setup - platform-specific source paths
if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
  # Homebrew fzf
  if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
  fi
  [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
elif [[ "$DOTFILES_PLATFORM" == "ubuntu" ]]; then
  # apt fzf
  source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null
  source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null
fi

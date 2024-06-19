
# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.pre.zsh"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Rye
source "$HOME/.rye/env"

# Added by Toolbox App
export PATH="$PATH:/Users/capytan/Library/Application Support/JetBrains/Toolbox/scripts"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zprofile.post.zsh"

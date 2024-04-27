# CodeWhisperer pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.pre.zsh"

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Rye
source "$HOME/.rye/env"

# Added by Toolbox App
export PATH="$PATH:/Users/capytan/Library/Application Support/JetBrains/Toolbox/scripts"

# CodeWhisperer post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/codewhisperer/shell/zprofile.post.zsh"

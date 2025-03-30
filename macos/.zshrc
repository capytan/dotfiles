# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"

source ~/dotfiles/macos/.zsh/ohmy.zsh
source ~/dotfiles/macos/.zsh/custom.zsh
if [ -f ~/dotfiles/macos/.zsh/local.zsh ]; then
  source ~/dotfiles/macos/.zsh/local.zsh
fi

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"

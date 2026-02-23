# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
source ~/dotfiles/macos/.zsh/alias.zsh
source ~/dotfiles/macos/.zsh/git-aliases.zsh
source ~/dotfiles/macos/.zsh/custom.zsh
source ~/dotfiles/macos/.zsh/tfj.zsh
if [ -f ~/dotfiles/macos/.zsh/local.zsh ]; then
  source ~/dotfiles/macos/.zsh/local.zsh
fi

# Setup Starship
eval "$(starship init zsh)"

# kiro
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

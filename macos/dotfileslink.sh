#!/bin/sh

ln -sf ~/dotfiles/macos/.fzf.zsh ~/.fzf.zsh
mkdir -p ~/.config/tmux
ln -sf ~/dotfiles/configs/tmux/tmux.conf ~/.config/tmux/tmux.conf
ln -sf ~/dotfiles/configs/tmux/keybindings.txt ~/.config/tmux/keybindings.txt
ln -sf ~/dotfiles/configs/tmux/tmux-start.sh ~/.config/tmux/tmux-start.sh
ln -sf ~/dotfiles/macos/.zprofile ~/.zprofile
ln -sf ~/dotfiles/macos/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.vscode/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -sf ~/dotfiles/.vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf ~/dotfiles/.vscode/extensions.json ~/Library/Application\ Support/Code/User/extensions.json
ln -sf ~/dotfiles/mise/config.toml ~/.config/mise/config.toml
mkdir -p ~/.config/alacritty/fonts
ln -sf ~/dotfiles/configs/alacritty.toml ~/.config/alacritty.toml
ln -sf ~/dotfiles/configs/alacritty/shared.toml ~/.config/alacritty/shared.toml
ln -sf ~/dotfiles/configs/alacritty/font-size.toml ~/.config/alacritty/font-size.toml
ln -sf ~/dotfiles/configs/alacritty/pane.toml ~/.config/alacritty/pane.toml
ln -sf ~/dotfiles/configs/alacritty/fonts/JetBrainsMono.toml ~/.config/alacritty/fonts/JetBrainsMono.toml
ln -sf ~/dotfiles/configs/claude/settings.json ~/.claude/settings.json
ln -sf ~/dotfiles/configs/claude/mcp.json ~/.mcp.json
ln -sf ~/dotfiles/configs/ghostty/config ~/.config/ghostty/config
mkdir -p ~/.config/git
ln -sf ~/dotfiles/configs/git/config ~/.config/git/config
ln -sf ~/dotfiles/configs/git/ignore ~/.config/git/ignore

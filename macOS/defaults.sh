# /usr/bin/sh

defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# Do not write RAM backup during sleep
# See: https://aotamasaki.hatenablog.com/entry/intelmac_crash_during_sleep
sudo pmset hibernatemode 0

# hidden
defaults write com.apple.finder AppleShowAllFiles TRUE

# vscode
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

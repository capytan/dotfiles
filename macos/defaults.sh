#!/bin/sh
# macOS System Preferences via defaults command
# Run: source macos/defaults.sh
# To revert a setting: defaults delete <domain> <key>

echo "Applying macOS defaults..."

# =============================================================================
# Finder
# =============================================================================

# Show hidden files (default: FALSE)
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions (default: false)
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show path bar at bottom of Finder window (default: false)
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar at bottom of Finder window (default: false)
defaults write com.apple.finder ShowStatusBar -bool true

# Search within current folder by default (default: "SCev" = This Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# =============================================================================
# Keyboard
# =============================================================================

# VSCode: disable press-and-hold for character picker (default: true)
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

# Key repeat rate (default: 6, lower = faster, min = 1)
defaults write NSGlobalDomain KeyRepeat -int 1

# Delay before key repeat starts (default: 25, lower = shorter, min = 10)
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# =============================================================================
# Screenshot
# =============================================================================

# Screenshot save location (default: ~/Desktop)
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

# Disable window shadow in screenshots (default: false)
defaults write com.apple.screencapture disable-shadow -bool true

# =============================================================================
# Dock
# =============================================================================

# Auto-hide Dock (default: false)
defaults write com.apple.dock autohide -bool true

# Remove Dock auto-hide delay (default: 0.5)
defaults write com.apple.dock autohide-delay -float 0

# Speed up Dock show/hide animation (default: 0.5)
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Dock icon size in pixels (default: 48)
defaults write com.apple.dock tilesize -int 48

# Hide recent apps section from Dock (default: true)
defaults write com.apple.dock show-recents -bool false

# Minimize windows into their app icon (default: false)
defaults write com.apple.dock minimize-to-application -bool true

# =============================================================================
# Trackpad
# =============================================================================

# Enable tap-to-click for Bluetooth trackpad (default: false)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Enable tap-to-click for built-in trackpad (default: false)
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# Enable tap-to-click at login screen (default: 0)
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad cursor speed (default: 1.5, higher = faster)
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# =============================================================================
# Apply changes (restart affected services)
# =============================================================================

echo "Restarting Finder and Dock..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "Done. Some settings require logout/restart to take effect."
echo "Verify with: defaults read NSGlobalDomain KeyRepeat"

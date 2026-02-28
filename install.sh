#!/bin/bash
set -euo pipefail

# =============================================================================
# dotfiles installer - single entry point for all platforms
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# 1. Platform detection
# =============================================================================
case "$(uname -s)" in
  Darwin) PLATFORM="macos" ;;
  Linux)  PLATFORM="ubuntu" ;;
  *)      error "Unsupported platform: $(uname -s)"; exit 1 ;;
esac
info "Detected platform: $PLATFORM"

# =============================================================================
# 2. Helper: create symlink with backup
# =============================================================================
LINKS=()

link_file() {
  local src="$1" dst="$2"
  local dst_dir="$(dirname "$dst")"

  # Create parent directory if needed
  if [[ ! -d "$dst_dir" ]]; then
    mkdir -p "$dst_dir"
    info "Created directory: $dst_dir"
  fi

  # Remove existing symlink or back up existing file
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    warn "Backing up existing file: $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -sf "$src" "$dst"
  LINKS+=("$dst -> $src")
}

# =============================================================================
# 3. Shell configuration
# =============================================================================
info "Setting up shell configuration..."
link_file "$DOTFILES_DIR/shell/zshrc"    "$HOME/.zshrc"
link_file "$DOTFILES_DIR/shell/zprofile" "$HOME/.zprofile"

# =============================================================================
# 4. Git configuration
# =============================================================================
info "Setting up git configuration..."
link_file "$DOTFILES_DIR/configs/git/config" "$HOME/.config/git/config"
link_file "$DOTFILES_DIR/configs/git/ignore" "$HOME/.config/git/ignore"

# =============================================================================
# 5. tmux configuration
# =============================================================================
info "Setting up tmux configuration..."
link_file "$DOTFILES_DIR/configs/tmux/tmux.conf"      "$HOME/.config/tmux/tmux.conf"
link_file "$DOTFILES_DIR/configs/tmux/keybindings.txt" "$HOME/.config/tmux/keybindings.txt"
link_file "$DOTFILES_DIR/configs/tmux/tmux-start.sh"   "$HOME/.config/tmux/tmux-start.sh"

# =============================================================================
# 6. Alacritty configuration
# =============================================================================
info "Setting up Alacritty configuration..."
link_file "$DOTFILES_DIR/configs/alacritty/alacritty.toml"       "$HOME/.config/alacritty/alacritty.toml"
link_file "$DOTFILES_DIR/configs/alacritty/shared.toml"          "$HOME/.config/alacritty/shared.toml"
link_file "$DOTFILES_DIR/configs/alacritty/font-size.toml"       "$HOME/.config/alacritty/font-size.toml"
link_file "$DOTFILES_DIR/configs/alacritty/pane.toml"            "$HOME/.config/alacritty/pane.toml"
link_file "$DOTFILES_DIR/configs/alacritty/fonts/JetBrainsMono.toml" "$HOME/.config/alacritty/fonts/JetBrainsMono.toml"

# =============================================================================
# 7. Ghostty configuration
# =============================================================================
info "Setting up Ghostty configuration..."
link_file "$DOTFILES_DIR/configs/ghostty/config" "$HOME/.config/ghostty/config"

# =============================================================================
# 8. mise configuration
# =============================================================================
info "Setting up mise configuration..."
link_file "$DOTFILES_DIR/configs/mise/config.toml" "$HOME/.config/mise/config.toml"

# =============================================================================
# 9. Claude Code configuration
# =============================================================================
info "Setting up Claude Code configuration..."
if [[ -x "$DOTFILES_DIR/configs/claude/setup-claude-commands.sh" ]]; then
  "$DOTFILES_DIR/configs/claude/setup-claude-commands.sh"
fi

# =============================================================================
# 10. Platform-specific setup
# =============================================================================
if [[ "$PLATFORM" == "macos" ]]; then
  info "Setting up macOS-specific configurations..."

  # VSCode / Cursor settings
  link_file "$DOTFILES_DIR/configs/vscode/settings.json" \
    "$HOME/Library/Application Support/Cursor/User/settings.json"
  link_file "$DOTFILES_DIR/configs/vscode/settings.json" \
    "$HOME/Library/Application Support/Code/User/settings.json"
  link_file "$DOTFILES_DIR/configs/vscode/extensions.json" \
    "$HOME/Library/Application Support/Code/User/extensions.json"

  # Homebrew packages: platform/macos/Brewfile is for reference only
  # Run manually if needed: brew bundle --file=platform/macos/Brewfile

elif [[ "$PLATFORM" == "ubuntu" ]]; then
  info "Setting up Ubuntu-specific configurations..."
  # Ubuntu Alacritty config (TOML version)
  if [[ -f "$DOTFILES_DIR/platform/ubuntu/alacritty.toml" ]]; then
    link_file "$DOTFILES_DIR/platform/ubuntu/alacritty.toml" \
      "$HOME/.config/alacritty/alacritty.toml"
  fi
fi

# =============================================================================
# 11. Migrate local.zsh from old path (if needed)
# =============================================================================
OLD_LOCAL_ZSH="$HOME/dotfiles/macos/.zsh/local.zsh"
NEW_LOCAL_ZSH="$DOTFILES_DIR/shell/zsh/local.zsh"

if [[ -f "$OLD_LOCAL_ZSH" && ! -f "$NEW_LOCAL_ZSH" ]]; then
  warn "Found local.zsh at old path: $OLD_LOCAL_ZSH"
  info "Moving to new path: $NEW_LOCAL_ZSH"
  cp "$OLD_LOCAL_ZSH" "$NEW_LOCAL_ZSH"
  ok "Migrated local.zsh to new location"
fi

# =============================================================================
# 12. Symlink verification report
# =============================================================================
echo ""
echo "============================================="
echo "  Symlink Verification Report"
echo "============================================="

PASS=0
FAIL=0

for entry in "${LINKS[@]}"; do
  dst="${entry%% -> *}"
  src="${entry##* -> }"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo -e "  ${GREEN}OK${NC}  $dst"
    ((PASS++))
  else
    echo -e "  ${RED}NG${NC}  $dst"
    ((FAIL++))
  fi
done

echo ""
echo "  Total: $((PASS + FAIL))  Pass: $PASS  Fail: $FAIL"
echo "============================================="

if [[ $FAIL -gt 0 ]]; then
  error "Some symlinks failed. Check the report above."
  exit 1
else
  ok "All symlinks created successfully!"
  echo ""
  info "Next steps:"
  info "  1. Open a new terminal to verify shell loads correctly"
  info "  2. Run 'mise doctor' to check tool installations"
  if [[ "$PLATFORM" == "macos" ]]; then
    info "  3. Run 'source platform/macos/defaults.sh' for macOS system preferences"
  fi
fi

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
    # mv into an existing .bak directory would nest dst inside it
    local backup="${dst}.bak"
    if [[ -e "$backup" || -L "$backup" ]]; then
      backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    warn "Backing up existing file: $dst -> $backup"
    mv "$dst" "$backup"
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
# 5. herdr configuration
# =============================================================================
info "Setting up herdr configuration..."
link_file "$DOTFILES_DIR/configs/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_file "$DOTFILES_DIR/configs/herdr/scripts/claude-usage.sh" \
  "$HOME/.config/herdr/scripts/claude-usage.sh"

# =============================================================================
# 6. Alacritty configuration
# =============================================================================
info "Setting up Alacritty configuration..."
link_file "$DOTFILES_DIR/configs/alacritty/alacritty.toml"       "$HOME/.config/alacritty/alacritty.toml"
link_file "$DOTFILES_DIR/configs/alacritty/shared.toml"          "$HOME/.config/alacritty/shared.toml"
link_file "$DOTFILES_DIR/configs/alacritty/theme.toml"           "$HOME/.config/alacritty/theme.toml"
link_file "$DOTFILES_DIR/configs/alacritty/font.toml"            "$HOME/.config/alacritty/font.toml"
link_file "$DOTFILES_DIR/configs/alacritty/font-size.toml"       "$HOME/.config/alacritty/font-size.toml"
link_file "$DOTFILES_DIR/configs/alacritty/pane.toml"            "$HOME/.config/alacritty/pane.toml"
link_file "$DOTFILES_DIR/configs/alacritty/fonts/JetBrainsMono.toml" "$HOME/.config/alacritty/fonts/JetBrainsMono.toml"

# =============================================================================
# 7. Ghostty configuration
# =============================================================================
info "Setting up Ghostty configuration..."
link_file "$DOTFILES_DIR/configs/ghostty/config" "$HOME/.config/ghostty/config"

# =============================================================================
# 8. Starship configuration
# =============================================================================
info "Setting up Starship configuration..."
link_file "$DOTFILES_DIR/configs/starship/starship.toml" "$HOME/.config/starship.toml"

# =============================================================================
# 9. mise configuration
# =============================================================================
info "Setting up mise configuration..."
link_file "$DOTFILES_DIR/configs/mise/config.toml" "$HOME/.config/mise/config.toml"

# =============================================================================
# 10. Claude Code configuration
# =============================================================================
info "Setting up Claude Code configuration..."
if [[ -x "$DOTFILES_DIR/configs/claude/setup-claude.sh" ]]; then
  "$DOTFILES_DIR/configs/claude/setup-claude.sh"
fi

# =============================================================================
# 11. Zed configuration
# =============================================================================
info "Setting up Zed configuration..."
link_file "$DOTFILES_DIR/configs/zed/settings.json" "$HOME/.config/zed/settings.json"

# =============================================================================
# 12. Neovim (LazyVim) configuration
# =============================================================================
# Link the whole directory so lazy.nvim writes lazy-lock.json back into dotfiles
info "Setting up Neovim configuration..."
link_file "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"

# =============================================================================
# 13. zeno.zsh (optional - snippet expansion engine)
# =============================================================================
# Pinned to a commit (upstream has no tags or releases); bump it with the update-local-tools skill
ZENO_COMMIT="f6ed8fc16cc32dc110fa4f77a50386624067fbe2"
ZENO_DIR="$HOME/.local/share/zeno"
if [[ ! -d "$ZENO_DIR" ]]; then
  info "Installing zeno.zsh..."
  # --no-checkout: if the pinned checkout below fails, no unpinned zeno.zsh is left to source
  git clone --no-checkout --filter=blob:none https://github.com/yuki-yano/zeno.zsh.git "$ZENO_DIR" ||
    warn "zeno.zsh clone failed (non-fatal)"
fi
if [[ -d "$ZENO_DIR/.git" ]]; then
  if [[ -f "$ZENO_DIR/zeno.zsh" && "$(git -C "$ZENO_DIR" rev-parse -q --verify HEAD)" == "$ZENO_COMMIT" ]]; then
    info "zeno.zsh already at ${ZENO_COMMIT:0:7}"
  else
    info "Checking out zeno.zsh ${ZENO_COMMIT:0:7}..."
    { git -C "$ZENO_DIR" cat-file -e "$ZENO_COMMIT^{commit}" 2>/dev/null ||
      git -C "$ZENO_DIR" fetch --quiet origin "$ZENO_COMMIT"; } &&
      git -C "$ZENO_DIR" checkout --quiet --detach "$ZENO_COMMIT" ||
      warn "zeno.zsh checkout failed (non-fatal)"
  fi
elif [[ -d "$ZENO_DIR" ]]; then
  warn "$ZENO_DIR is not a git clone; cannot pin zeno.zsh (non-fatal)"
fi

# zeno configuration
info "Setting up zeno configuration..."
link_file "$DOTFILES_DIR/configs/zeno" "$HOME/.config/zeno"

# =============================================================================
# 14. Platform-specific setup
# =============================================================================
if [[ "$PLATFORM" == "macos" ]]; then
  info "Setting up macOS-specific configurations..."

  # VSCode / Cursor settings
  link_file "$DOTFILES_DIR/configs/cursor/settings.json" \
    "$HOME/Library/Application Support/Cursor/User/settings.json"
  link_file "$DOTFILES_DIR/configs/vscode/settings.json" \
    "$HOME/Library/Application Support/Code/User/settings.json"
  link_file "$DOTFILES_DIR/configs/vscode/extensions.json" \
    "$HOME/Library/Application Support/Code/User/extensions.json"
  link_file "$DOTFILES_DIR/configs/vscode/extensions.json" \
    "$HOME/Library/Application Support/Cursor/User/extensions.json"

  # Cursor Agent sandbox: copy, not symlink. A symlink would let sandboxed
  # commands in a dotfiles workspace rewrite the live policy, which Cursor
  # write-protects only under ~/.cursor
  CURSOR_SANDBOX_SRC="$DOTFILES_DIR/configs/cursor/sandbox.json"
  CURSOR_SANDBOX="$HOME/.cursor/sandbox.json"
  if [[ -L "$CURSOR_SANDBOX" ]]; then
    warn "$CURSOR_SANDBOX is a symlink; replace it with a copy of $CURSOR_SANDBOX_SRC"
  elif [[ ! -e "$CURSOR_SANDBOX" ]]; then
    mkdir -p "$(dirname "$CURSOR_SANDBOX")"
    cp "$CURSOR_SANDBOX_SRC" "$CURSOR_SANDBOX"
    ok "Copied Cursor sandbox policy: $CURSOR_SANDBOX"
  elif ! cmp -s "$CURSOR_SANDBOX_SRC" "$CURSOR_SANDBOX"; then
    warn "$CURSOR_SANDBOX differs from $CURSOR_SANDBOX_SRC (left unchanged; diff and copy by hand)"
  fi

  # Homebrew packages: platform/macos/Brewfile is for reference only
  # Run manually if needed: brew bundle --file=platform/macos/Brewfile

elif [[ "$PLATFORM" == "ubuntu" ]]; then
  info "Setting up Ubuntu-specific configurations..."
  # Ubuntu Alacritty config (TOML version)
  if [[ -f "$DOTFILES_DIR/platform/ubuntu/alacritty.toml" ]]; then
    link_file "$DOTFILES_DIR/platform/ubuntu/alacritty.toml" \
      "$HOME/.config/alacritty/alacritty.toml"
  fi

  # Neovim from the official release tarball: apt's neovim is older than
  # LazyVim's minimum (0.11.2). Pinned; bump only to a release published 7+ days ago
  NVIM_VERSION="0.12.6"
  NVIM_DIR="$HOME/.local/opt/nvim-$NVIM_VERSION"
  case "$(uname -m)" in
    x86_64)        NVIM_ARCH="x86_64" ;;
    aarch64|arm64) NVIM_ARCH="arm64" ;;
    *)             NVIM_ARCH="" ;;
  esac

  # Verifies the tarball against the sha256 digest GitHub reports for the asset
  # Runs in a subshell so the EXIT trap cleans up the temp dir on any exit
  install_nvim() (
    local asset="nvim-linux-${NVIM_ARCH}.tar.gz"
    local url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/${asset}"
    local tmp expected
    tmp="$(mktemp -d)" || exit 1
    trap 'rm -r "$tmp"' EXIT

    expected="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/tags/v${NVIM_VERSION}" |
      python3 -c 'import json, sys; print(next(a["digest"] for a in json.load(sys.stdin)["assets"] if a["name"] == sys.argv[1]))' "$asset")" || exit 1
    curl -fsSL -o "$tmp/$asset" "$url" || exit 1

    if ! echo "${expected#sha256:}  $tmp/$asset" | sha256sum -c --quiet; then
      error "Neovim checksum mismatch (expected $expected)"
      exit 1
    fi

    # Clear a partial install left by an interrupted run, or mv would nest into it
    tar -xzf "$tmp/$asset" -C "$tmp" &&
      rm -rf "$NVIM_DIR" &&
      mkdir -p "$(dirname "$NVIM_DIR")" &&
      mv "$tmp/nvim-linux-${NVIM_ARCH}" "$NVIM_DIR"
  )

  if [[ -z "$NVIM_ARCH" ]]; then
    warn "No Neovim release for $(uname -m), skipping"
  elif [[ -x "$NVIM_DIR/bin/nvim" ]]; then
    info "Neovim $NVIM_VERSION already installed"
  else
    info "Installing Neovim $NVIM_VERSION..."
    install_nvim || warn "Neovim install failed (non-fatal)"
  fi
  if [[ -x "$NVIM_DIR/bin/nvim" ]]; then
    link_file "$NVIM_DIR/bin/nvim" "$HOME/.local/bin/nvim"
  fi
fi

# =============================================================================
# 15. Migrate local.zsh from old path (if needed)
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
# 16. Symlink verification report
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
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}NG${NC}  $dst"
    FAIL=$((FAIL + 1))
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

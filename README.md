# dotfiles

Personal development environment configuration for macOS (Apple Silicon) and Ubuntu.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/capytan/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer (auto-detects platform)
./install.sh

# Apply macOS system preferences (optional)
source platform/macos/defaults.sh
```

## Repository Structure

```
dotfiles/
├── configs/              # Application configs (XDG-oriented)
│   ├── alacritty/       # Terminal emulator configuration
│   ├── claude/          # Claude Code custom commands & settings, default PR/issue templates
│   ├── cursor/          # Cursor IDE rules, settings, extension list, Agent sandbox policy (copied, not linked)
│   ├── ghostty/         # Ghostty terminal config
│   ├── git/             # Git config, ignore, completion, prompt
│   ├── herdr/           # herdr multiplexer config and tab bar scripts
│   ├── mise/            # Development environment manager config
│   ├── nvim/            # Neovim (LazyVim) config and lazy-lock.json
│   ├── takumi-guard/    # Opt-in script for the anonymous Takumi Guard registry
│   └── vscode/          # VSCode settings and extension list
├── shell/               # Shell configuration (shared layer)
│   ├── zshrc            # Thin loader (auto-detects platform)
│   ├── zprofile         # Login shell settings
│   ├── fzf.zsh          # fzf setup (platform-aware)
│   └── zsh/             # Shared modules
│       ├── aliases.zsh        # Shell aliases
│       ├── fzf-functions.zsh  # fzf interactive functions
│       ├── git-aliases.zsh    # Git aliases (oh-my-zsh style)
│       ├── history.zsh        # History settings & shell options
│       ├── tfj.zsh            # Terraform directory jumper
│       └── tools.zsh          # mise, nvim, pnpm, gdcp
├── platform/            # Platform-specific layer
│   ├── macos/           # Brewfile, defaults.sh, zprofile, zshrc
│   └── ubuntu/          # zprofile, zshrc, alacritty config
├── archive/             # Legacy config records
├── install.sh           # Single setup entry point
└── CLAUDE.md            # AI assistant guidelines
```

## Shell Loading Order

```
~/.zprofile → shell/zprofile
  └─ platform/$DOTFILES_PLATFORM/zprofile.zsh

~/.zshrc → shell/zshrc
  ├─ shell/zsh/*.zsh (shared modules)
  ├─ shell/fzf.zsh (platform-aware fzf setup)
  ├─ platform/$DOTFILES_PLATFORM/zshrc.zsh
  └─ shell/zsh/local.zsh (if exists, gitignored)
```

`$DOTFILES_PLATFORM` is auto-detected from `uname -s` (`Darwin` → `macos`, `Linux` → `ubuntu`).

## Key Aliases & Functions

- **Git shortcuts**: `g` (git), `gb` (branch), `gsw` (switch), `gd` (diff), `gst` (status)
- **FZF functions**: `fbr` (branch switch), `fbrm` (remote branch), `fa` (git add), `fzf-src` (ghq + fzf)
- **Commit helpers**: `gdcp` (diff to Japanese commit msg), `gdcpe` (English)
- **Modern CLI**: `cat` → bat, `ls` → eza, `du` → dust, `top` → btm

## Neovim Plugin Updates

`configs/nvim/lazy-lock.json` pins every plugin to a commit. lazy.nvim only checks for updates in the background and never installs them on its own.

1. Update plugins with the `update-nvim-plugins` Claude Code skill (`configs/claude/skills/update-nvim-plugins/`). It holds back commits pushed less than 7 days ago, checks each candidate for supply-chain risks, edits `lazy-lock.json` only for the approved ones, and opens a PR
2. Inside nvim, stop at `:Lazy check` to see what is incoming. Don't use `:Lazy update`, `:Lazy sync`, or `U`/`S` in the `:Lazy` window — they jump to the latest commit or tag without those checks
3. If something breaks, revert `lazy-lock.json` and run `:Lazy restore`

## VS Code / Cursor Extensions

`configs/vscode/extensions.txt` (VS Code) and `configs/cursor/extensions.txt` (Cursor) list the extensions to install, one ID per line, in `--list-extensions` format. `install.sh` does not install them; run this on a new Mac:

```bash
awk '{print "--install-extension", $0}' configs/vscode/extensions.txt | xargs code
awk '{print "--install-extension", $0}' configs/cursor/extensions.txt | xargs cursor
```

- `extensions.allowed` in both `settings.json` files is the gate: in VS Code, unlisted extensions are blocked from installing, even from the CLI, and disabled if already installed. Add a new extension to the list and to `extensions.allowed`
- Allow Microsoft extensions with both keys: VS Code matches `microsoft`, and Cursor matches the `ms-*` publisher IDs (`ms-python`, `ms-vscode`, and so on). In VS Code 1.144 the `ms-*` keys do not take effect, and those extensions fail to install with a misleading "not available in Visual Studio Code for the Mac Silicon platform" error. In Cursor 3.27, `microsoft` does not take effect, and Microsoft extensions such as `ms-vscode.makefile-tools` are reported as not in the allowed list
  - The rule behind this: a publisher key is looked up by the publisher's Marketplace display name when that name is in the editor's `product.json` `extensionPublisherOrgs` (`["microsoft"]` in VS Code, unset in Cursor), and by the publisher ID otherwise. So in VS Code it covers every publisher whose display name is "Microsoft", including ones without the `ms-` prefix (`dbaeumer`, `vscjava`), and not `github`. An extension ID key always takes precedence
  - Dependencies are checked too: a blocked dependency fails the install, and a blocked extension pack member is skipped silently
- `configs/vscode/check-extensions-allowed.py` checks each list against its editor's `extensions.allowed` with these rules, following dependencies and pack members. It queries the gallery each editor uses for display names and dependencies, so it needs network access. CI (`.github/workflows/editor-settings.yml`) runs it when a list, a `settings.json`, or the script changes
- In VS Code, `--install-extension` installs the latest version, without the 168-hour wait that `extensions.autoUpdateDelay` applies to auto updates. Append `@<version>` to an ID to install a specific version
- Cursor does not document whether it honors `extensions.allowed`, or whether `extensions.installCooldownHours` covers CLI installs
- Check for drift between the lists and the installed extensions:

  ```bash
  diff <(code --list-extensions) configs/vscode/extensions.txt
  diff <(cursor --list-extensions) configs/cursor/extensions.txt
  ```

## Takumi Guard (anonymous)

`configs/takumi-guard/setup-anon.sh` points npm, pnpm, yarn, bun, pip, and uv at the anonymous [Takumi Guard](https://flatt.tech/takumi/features/guard/) registry, which blocks known-malicious packages. `install.sh` does not run it; run it by hand on machines that should use it. It skips any config file that already exists, so machines set up with an organization token keep their settings.

npm, yarn v1, bun, and uv may record `npm.flatt.tech` / `pypi.flatt.tech` URLs in lockfiles (including `uv.lock`), and those URLs end up in committed lockfiles.

## safe-chain

[safe-chain](https://github.com/AikidoSec/safe-chain) wraps npm, pnpm, yarn, bun, pip, uv, and other package managers in shell functions that route downloads through a local proxy. It complements Takumi Guard:

- Both block known-malicious packages
- Only safe-chain blocks packages published less than 48 hours ago (its default minimum package age)
- Only Takumi Guard covers contexts without the shell functions (non-interactive shells, IDEs, mise's `npm:`/`pypi:` backends), since it is registry configuration

`shell/zsh/03-tools.zsh` sources `~/.safe-chain/scripts/init-posix.sh` only when it exists, and sets `SAFE_CHAIN_NPM_CUSTOM_REGISTRIES` / `SAFE_CHAIN_PIP_CUSTOM_REGISTRIES` first so the Takumi Guard registries get inspected too. `install.sh` does not install safe-chain, and nothing warns when it is missing; install it by hand on a new machine:

```bash
curl -fsSL https://github.com/AikidoSec/safe-chain/releases/download/1.5.27/install-safe-chain.sh -o /tmp/install-safe-chain.sh \
  && echo "600ebddcb3aaf1fd53653a8d7985df44528722c0f5ee7eb9fff86f26a1a4e5a8  /tmp/install-safe-chain.sh" | sha256sum -c - \
  && sh /tmp/install-safe-chain.sh \
  && rm /tmp/install-safe-chain.sh
```

- The checksum is the one in safe-chain's README "Installation" section, and matches the `install-safe-chain.sh` asset digest on the [release](https://github.com/AikidoSec/safe-chain/releases/tag/1.5.27). The installer has the version and the binary checksums baked in, so it also verifies the binary it downloads
- The installer runs `safe-chain setup` (it has no option to skip it), which appends `source ~/.safe-chain/scripts/init-posix.sh` to `~/.zshrc` and `~/.bashrc`. `~/.zshrc` is the symlinked `shell/zshrc`, where the line would source the script a second time, after the Takumi Guard settings. Revert it with `git checkout -- shell/zshrc`, or delete just that line if the file has other uncommitted edits
- Check it in a new zsh: `type uv` should report a shell function from `init-posix.sh`, and `command -v safe-chain` should print the path under `~/.safe-chain/bin/`. `npm safe-chain-verify` (or `uv`, `pip`, ...) should print "OK: Safe-chain works!"
- To upgrade, replace `1.5.27` throughout this section, take the new checksum from the same places, rerun the command, and revert `shell/zshrc`. Check the release notes for changes to the `SAFE_CHAIN_*_CUSTOM_REGISTRIES` variables that `03-tools.zsh` relies on

## Machine-Specific Settings

For settings that differ between personal and work machines, use gitignored local files:

```bash
# Shell-level (proxy, API keys, team aliases)
cp shell/zsh/local.zsh.example shell/zsh/local.zsh
```

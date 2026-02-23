# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Ubuntu systems. It contains configuration files for various development tools, shell environments, and system settings.

## Common Commands

### Initial Setup
```bash
# Clone repository to home directory
git clone https://github.com/capytan/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Setup dotfiles links (choose your platform)
./macos/dotfileslink.sh      # macOS (Apple Silicon)
./macos_intel/dotfileslink.sh # macOS (Intel) - deprecated
./ubuntu/dotfileslink.sh      # Ubuntu
./dotfileslink.sh            # Generic link script

# Install dependencies (macOS)
brew bundle --file=Brewfile

# Setup Claude custom commands
./configs/claude/setup-claude-commands.sh
```

### Verify Setup
```bash
# Check if links are created correctly
ls -la ~ | grep "^l.*dotfiles"

# Verify zsh configuration loaded
echo $SHELL  # Should show /bin/zsh or similar
source ~/.zshrc  # Reload shell configuration

# Test git aliases are working
g status  # Should run git status
```

### Update Dependencies
```bash
# Update Homebrew packages
brew update && brew upgrade

# Update mise/asdf tools
mise upgrade
```

## Repository Architecture

The repository follows a platform-specific organization:

- **Platform-specific directories**: `macos/`, `macos_intel/`, `ubuntu/` - contain OS-specific configurations and link scripts
- **Configuration files**: Root directory contains common dotfiles (.zshrc, .tmux.conf, .zprofile, init.vim, etc.)
- **Tool configurations**:
  - `configs/alacritty/` - Alacritty terminal configuration with shared settings and fonts
  - `configs/claude/` - Claude Code commands, skills, and settings
  - `.vscode/` - VSCode/Cursor settings and extensions
  - `mise/` - mise (development environment manager) configuration
- **Git utilities**: `git-utils/` - Contains git completion and prompt scripts
- **Package management**: `Brewfile` - Homebrew packages for macOS

## Key Configurations

### Shell Environment
- Primary shell: zsh with custom prompt showing git status
- Key aliases configured in .zshrc:
  - Git shortcuts (g, gb, gs, gd, gst, etc.)
  - FZF functions for interactive git branch switching (fbr, fbrm)
  - Interactive file staging with fzf (fa)

### Editor
- Primary editor: vim/neovim (configuration in init.vim)
- VSCode/Cursor with vim extension and specific formatting settings

### Development Tools
- Version management: mise, jenv, direnv
- Language support: Python, Ruby, Go, Java, Node.js
- Container tools: Docker, Kubernetes (kind)
- Infrastructure: Terraform, AWS Copilot CLI

## Claude Code Configuration

### Custom Commands and Skills

Available in `configs/claude/`:

| Command/Skill | Location | Description |
|---------------|----------|-------------|
| `/commit` | `commands/commit.md` | Creates Conventional Commits formatted commit message |
| `/switch` | `commands/switch.md` | Creates appropriately named feature branch from changes |
| `/magi` | `skills/magi-decision-support/` | Multi-perspective decision analysis (MELCHIOR/BALTHASAR/CASPER) |

Setup:
```bash
./configs/claude/setup-claude-commands.sh
```

### Settings (`configs/claude/settings.json`)

- **Model**: claude-sonnet with extended thinking enabled
- **MCP Servers**: GitHub (`gh mcp-server`)
- **Permissions**: Configured allow/ask rules for safe defaults
- **Telemetry**: Disabled (DISABLE_TELEMETRY, DISABLE_ERROR_REPORTING)

## Claude Code Behavior

This section defines how Claude Code should operate when working in this repository.

### Core Principles

- **Simplicity First**: Make every change as simple as possible. Minimize code impact.
- **No Laziness**: Find root causes. No temporary fixes. Apply senior developer standards.
- **Minimal Impact**: Only touch what is necessary. Avoid unrelated side effects.
- **Verify Before Done**: Never consider a task complete without demonstrating it works.

### Workflow

**Plan First**: Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
If something goes sideways, stop and re-plan. Do not keep pushing forward.

**Subagents**: Use subagents to keep the main context clean. One focused task per subagent.
Offload research, exploration, and parallel analysis to subagents.

**Verification**: Run tests and check logs before marking work complete.
Ask: "Would a staff engineer approve this?"

**Elegance**: For non-trivial changes, ask "Is there a more elegant way?"
If a fix feels hacky, implement the clean solution. Skip for simple/obvious fixes.

**Bug Fixing**: Fix autonomously when given a bug report. Use logs, errors, and failing
tests as the entry point. No hand-holding required.

### Task Management

1. Write plan with checkable items before starting
2. Confirm approach before implementation
3. Mark items complete as you go
4. Provide high-level summary at each step
5. Update `tasks/lessons.md` after any user correction

### Self-Improvement Loop

After any user correction: update `tasks/lessons.md` with the pattern to prevent recurrence.
Review `tasks/lessons.md` at session start for relevant context.

### Agent Teams

For tasks with parallel, independent workstreams, prefer agent teams over sequential work.

**Use agent teams when:**
- Research from multiple angles simultaneously (security + performance + test coverage)
- Independent modules or features that don't share files
- Debugging with competing hypotheses — let teammates disprove each other
- Cross-layer changes (frontend / backend / tests) where each layer is independent

**Use subagents (Task tool) when:**
- Focused research that only needs to report results back
- Sequential tasks with dependencies
- Same-file edits or tightly coupled changes

**Patterns:**
```
# Research team (3 perspectives)
Create an agent team: one teammate on X, one on Y, one playing devil's advocate.

# Parallel implementation
Create a team with N teammates to implement these modules in parallel.

# Hypothesis-driven debugging
Spawn teammates to investigate different root causes. Have them challenge each other.
```

**Quality gates:** Require plan approval before implementation for risky tasks:
```
Spawn a teammate to refactor X. Require plan approval before they make changes.
```

**Cleanup:** Always tell the lead to clean up when done. Teammates must be shut down first.

## Important Guidelines

### When modifying this repository:
- Respect the platform-specific directory structure
- Maintain consistency with existing shell aliases and functions
- Update the appropriate dotfileslink.sh script when adding new configuration files
- Test link scripts on the target platform before committing
- Preserve file permissions (especially for executable scripts)

### Cursor AI Rules (`.cursor/rules/`)
Key constraints from `global.mdc` (Japanese):
- Never change technology stack versions without approval
- Check for duplicate implementations before adding code
- No UI/UX design changes without approval
- Follow existing directory structure and naming conventions

## Troubleshooting

### Common Issues
```bash
# If dotfiles links are broken
ls -la ~ | grep "dotfiles"  # Check existing links
rm ~/.zshrc ~/.tmux.conf    # Remove broken links if needed
./dotfileslink.sh           # Re-run setup

# If shell aliases not working
source ~/.zshrc             # Reload configuration
which g                     # Check if alias exists
type g                      # Show alias definition

# If mise/asdf commands not found
export PATH="$HOME/.local/share/mise/shims:$PATH"
mise doctor                 # Check mise installation
```

## File Locations
- Shell configs: `~/.zshrc`, `~/.zprofile` (symlinked from repo)
- Neovim config: `~/.config/nvim/init.vim` (symlinked)
- VSCode settings: `~/Library/Application Support/Code/User/settings.json` (macOS)
- Claude commands: `~/.claude/commands/` (symlinked)
- Alacritty config: Platform-specific in `configs/alacritty/`

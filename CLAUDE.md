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
./ubuntu/dotfileslink.sh      # Ubuntu
./dotfileslink.sh            # Generic link script

# Install dependencies (macOS)
brew bundle --file=Brewfile

# Setup Claude custom commands
./configs/claude/setup-claude-commands.sh
```

## Repository Architecture

The repository follows a platform-specific organization:

- **Platform-specific directories**: `macos/`, `ubuntu/` - contain OS-specific configurations and link scripts
- **Configuration files**: Root directory contains common dotfiles (.zshrc, .tmux.conf, .zprofile, init.vim, etc.)
- **Tool configurations**:
  - `configs/alacritty/` - Alacritty terminal configuration with shared settings and fonts
  - `configs/claude/` - Claude Code commands, agents, skills, hooks, and settings
  - `.vscode/` - VSCode/Cursor settings and extensions
  - `mise/` - mise (development environment manager) configuration
- **Git utilities**: `git-utils/` - Contains git completion and prompt scripts
- **Package management**: `Brewfile` - Homebrew packages for macOS

## Claude Code Configuration

### Custom Commands

Available in `configs/claude/commands/`:

| Command | Location | Description |
|---------|----------|-------------|
| `/commit` | `commands/commit.md` | Creates Conventional Commits formatted commit message |
| `/switch` | `commands/switch.md` | Creates appropriately named feature branch from changes |

Setup:
```bash
./configs/claude/setup-claude-commands.sh
```

### Agents

Available in `configs/claude/agents/`:

| Agent | Description |
|-------|-------------|
| `agent-reviewer` | Reviews agent `.md` files against Anthropic best practices |
| `claude-md-reviewer` | Audits CLAUDE.md for token efficiency and quality |
| `skill-reviewer` | Reviews SKILL.md files against best practices |

### Skills

Available in `configs/claude/skills/`:

| Skill | Description |
|-------|-------------|
| `/magi` | Multi-perspective decision analysis (MELCHIOR/BALTHASAR/CASPER) |

### Hooks (Tmux Integration)

Displays status icons in tmux window names automatically:
- ⏳ Working / ✅ Done / 🤖 Subagent running / ❌ Error / ⚠️ Awaiting permission
- All hooks in `configs/claude/hooks/`, shared logic in `tmux-lib.sh`

### Settings

- `settings.json` — Permissions, hooks, and plugin settings (auto-loaded by Claude Code)
- `mcp.json` — MCP servers: Context7 (`@upstash/context7-mcp`) for library documentation lookup

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


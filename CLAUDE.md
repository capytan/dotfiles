# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Ubuntu systems. It contains configuration files for various development tools, shell environments, and system settings.

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

Custom commands, agents, skills, hooks, and settings are in `configs/claude/`. Setup: `./configs/claude/setup-claude-commands.sh`

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

**Verification**: Check that symlinks are intact (`ls -la ~ | grep "\-> .*dotfiles"`) and scripts are executable before marking work complete.
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

**Quality gates:** Require plan approval before implementation for risky tasks.

**Cleanup:** Always tell the lead to clean up when done. Teammates must be shut down first.

## Important Guidelines

### When modifying this repository:
- Respect the platform-specific directory structure
- Maintain consistency with existing shell aliases and functions
- Update the appropriate dotfileslink.sh script when adding new configuration files
- Test link scripts on the target platform before committing
- Preserve file permissions (especially for executable scripts)

### Cursor AI Rules
See `.cursor/rules/global.mdc` for Cursor-specific constraints.


#!/bin/bash
# WorktreeCreate / WorktreeRemove hook: delegate to git-wt
# stdin: JSON with hook_event_name + common fields (session_id, cwd, etc.)
# stdout (WorktreeCreate only): absolute path to created worktree
# Requires: jq, git-wt (k1LoW/tap/git-wt)

set -euo pipefail

if ! command -v git-wt &>/dev/null; then
  echo "[worktree-git-wt] WARNING: git-wt is not installed" >&2
  exit 0
fi

input=$(cat)

# Debug logging (enable with DEBUG_WT=1)
if [[ "${DEBUG_WT:-}" == "1" ]]; then
  echo "$(date -Iseconds) $input" >> /tmp/worktree-git-wt.log
fi

hook_event=$(printf '%s' "$input" | jq -r '.hook_event_name')

case "$hook_event" in
WorktreeCreate)
    # Try .name first (blog post pattern), fall back to session_id
    wt_name=$(printf '%s' "$input" | jq -r '.name // empty')
    if [[ -z "$wt_name" ]]; then
      wt_name="wt-$(printf '%s' "$input" | jq -r '.session_id // empty' | head -c 8)"
    fi
    wt_abs_path=$(git wt "$wt_name" --nocd 2>/dev/null | tail -n 1 | xargs)
    echo "$wt_abs_path"
    ;;
WorktreeRemove)
    # Try .worktree_path first (blog post pattern), fall back to .cwd
    wt_path=$(printf '%s' "$input" | jq -r '.worktree_path // empty')
    if [[ -z "$wt_path" ]]; then
      wt_path=$(printf '%s' "$input" | jq -r '.cwd // empty')
    fi
    if [[ -n "$wt_path" ]]; then
      git wt -d "$wt_path" 2>/dev/null || true
    fi
    ;;
esac

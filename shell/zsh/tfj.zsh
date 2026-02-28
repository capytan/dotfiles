#!/usr/bin/env zsh

# shmokmt/tfj
# https://github.com/shmokmt/tfj/blob/e814d90f0ee1301d11ba52f1cb594efb2b03fcd0/tfj.zsh
tfj() {
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -z "$git_root" ]]; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    local selected_dir=$(
        cd "$git_root"
        rg --files --hidden --no-ignore --glob '**/.terraform/terraform.tfstate' . 2>/dev/null | \
            sed 's|/\.terraform/terraform\.tfstate||' | \
            sort -u | \
            sed 's|^\./||' | \
            fzf --prompt="Select Terraform directory: " --height=40% --reverse
    )

    if [[ -n "$selected_dir" ]]; then
        cd "$git_root/$selected_dir"
    else
        echo "No directory selected"
        return 1
    fi
}

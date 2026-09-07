#!/usr/bin/env bash

# Interactive local branch deletion (fzf multi-select, plain bash fallback)

set -euo pipefail

log() {
    level="$1"
    shift
    printf "[%s] %s\n" "$level" "$*" >&2
}

if ! command -v git > /dev/null 2>&1; then
    log "ERROR" "git is not installed."
    exit 1
fi
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    log "ERROR" "Not inside a git repository."
    exit 1
fi

# current branch is excluded: git refuses to delete it anyway
mapfile -t branches < <(git branch --format='%(if)%(HEAD)%(then)%(else)%(refname:short)%(end)' | sed '/^$/d')
if [ "${#branches[@]}" -eq 0 ]; then
    log "INFO" "No branches to delete."
    exit 0
fi

selected=()
if command -v fzf > /dev/null 2>&1; then
    mapfile -t selected < <(printf '%s\n' "${branches[@]}" | fzf \
        --multi \
        --height=40% \
        --layout=reverse \
        --border \
        --prompt="Delete branch > " \
        --header="TAB to select, ENTER to confirm" \
        --preview="git log --oneline --color=always -n 15 {}" || true)
else
    log "INFO" "fzf not found, falling back to numbered selection."
    for i in "${!branches[@]}"; do
        printf "%3d) %s\n" "$((i + 1))" "${branches[$i]}" >&2
    done
    read -r -p "Branches to delete (numbers, space separated): " -a picks
    for pick in "${picks[@]}"; do
        if ! [[ "$pick" =~ ^[0-9]+$ ]] || [ "$pick" -lt 1 ] || [ "$pick" -gt "${#branches[@]}" ]; then
            log "ERROR" "Invalid selection: $pick"
            exit 1
        fi
        selected+=("${branches[$((pick - 1))]}")
    done
fi

if [ "${#selected[@]}" -eq 0 ]; then
    log "INFO" "Nothing selected."
    exit 0
fi

log "INFO" "Branches to delete:"
printf "  %s\n" "${selected[@]}" >&2
read -r -p "Delete ${#selected[@]} branch(es)? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { log "INFO" "Aborted."; exit 0; }

for branch in "${selected[@]}"; do
    if git branch -d "$branch" 2> /dev/null; then
        continue
    fi
    read -r -p "'$branch' is not fully merged. Force delete? [y/N] " force
    if [[ "$force" =~ ^[Yy]$ ]]; then
        git branch -D "$branch"
    else
        log "INFO" "Skipped $branch"
    fi
done

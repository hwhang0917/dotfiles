#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$DOTFILES_DIR"

git submodule update --remote

changed_modules=$(git diff --name-only)
if [[ -z "$changed_modules" ]]; then
    echo "All submodules are already up to date."
    exit 0
fi

echo "Updated submodules:"
echo "$changed_modules"

git add -A
git commit -m "chore: update submodules"

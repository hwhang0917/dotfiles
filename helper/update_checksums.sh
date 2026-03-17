#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts/.local/scripts" && pwd)"
SHA256_FILE="$SCRIPT_DIR/scripts.sha256"

cd "$SCRIPT_DIR"

scripts=()
while IFS= read -r -d '' file; do
    name=$(basename "$file")
    [[ "$name" == "scripts.sha256" || "$name" == "verify-scripts" ]] && continue
    scripts+=("$name")
done < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -executable -print0 | sort -z)

scripts+=("verify-scripts")

: > "$SHA256_FILE"
for name in "${scripts[@]}"; do
    sha256sum "$name" >> "$SHA256_FILE"
done

echo "Updated $SHA256_FILE (${#scripts[@]} scripts)"

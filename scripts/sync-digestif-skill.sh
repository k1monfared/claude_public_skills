#!/usr/bin/env bash
# Sync the vendored skills/digestif from the standalone digestif repo.
#
# Usage: scripts/sync-digestif-skill.sh [path-to-digestif-checkout]
# Source resolution: first argument, else $DIGESTIF_REPO, else ../digestif
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-${DIGESTIF_REPO:-$REPO_DIR/../digestif}}"
SKILL_SRC="$SRC/src/digestif/skill"
DEST="$REPO_DIR/skills/digestif"

if [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
    echo "error: no digestif skill at $SKILL_SRC" >&2
    echo "pass the digestif checkout path, or set DIGESTIF_REPO" >&2
    exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$SKILL_SRC/." "$DEST/"
find "$DEST" -name "__pycache__" -type d -exec rm -rf {} +
cp "$SRC/LICENSE" "$DEST/LICENSE"

"$REPO_DIR/skill.sh" build-manifest
"$REPO_DIR/skill.sh" validate
echo "synced digestif skill from $SKILL_SRC"

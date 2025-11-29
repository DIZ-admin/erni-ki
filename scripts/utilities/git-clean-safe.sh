#!/usr/bin/env bash
# Clean untracked/ignored artifacts (Finder/backup files) without touching git hooks.
# - Uses -fdX to remove ignored + untracked files/dirs.
# - Skips .git/hooks to preserve pre-commit installs.
# - Prints what will be removed in dry-run mode when CLEAN_DRY_RUN=1 is set.

set -euo pipefail

DRY_RUN=${CLEAN_DRY_RUN:-0}

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "Dry run: showing files that would be removed..."
  git clean -fdX -n -- ':!/.git/hooks'
else
  git clean -fdX -e .git/hooks -- ":!/.git/hooks"
  echo "✅ Working tree cleaned (ignored + untracked removed, hooks kept)."
fi

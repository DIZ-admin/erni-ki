#!/usr/bin/env bash
# Simple guard to ensure Docker image references are lowercase-only.
# Reads tags from arguments or STDIN; exits non-zero on uppercase characters.

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

if [[ $# -gt 0 ]]; then
  tags="$*"
else
  tags="$(cat)"
fi

# Strip surrounding whitespace/newlines for consistent checks
tags="$(printf "%s" "$tags" | sed '/^[[:space:]]*$/d')"

# Treat empty/whitespace-only input as no-op (graceful pass)
if [[ -z "$tags" ]]; then
  echo "No tags provided to check-docker-tags.sh; skipping check." >&2
  exit 0
fi

if echo "$tags" | grep -q '[A-Z]'; then
  echo "❌ Uppercase characters detected in Docker tags:" >&2
  echo "$tags" >&2
  exit 1
fi

echo "✅ Docker tags are lowercase only."

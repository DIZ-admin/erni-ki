#!/usr/bin/env bash
# Simple guard to ensure Docker image references are lowercase-only.
# Reads tags from arguments or STDIN; exits non-zero on uppercase characters.

set -euo pipefail

if [[ $# -gt 0 ]]; then
  tags="$*"
else
  tags="$(cat)"
fi

# Strip surrounding whitespace/newlines for consistent checks
tags="$(printf "%s" "$tags" | sed '/^[[:space:]]*$/d')"

if [[ -z "$tags" ]]; then
  echo "No tags provided to check-docker-tags.sh" >&2
  exit 1
fi

if echo "$tags" | grep -q '[A-Z]'; then
  echo "❌ Uppercase characters detected in Docker tags:" >&2
  echo "$tags" >&2
  exit 1
fi

echo "✅ Docker tags are lowercase only."

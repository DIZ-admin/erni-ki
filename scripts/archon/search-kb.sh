#!/usr/bin/env bash
# Archon API Helper - Search Knowledge Base
# Usage: ./scripts/archon/search-kb.sh "query text"
# Example: ./scripts/archon/search-kb.sh "authentication JWT"

set -euo pipefail
IFS=$'\n\t'

ARCHON_API="${ARCHON_API:-http://localhost:8181/api}"
QUERY="${1:-}"

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

if [ -z "$QUERY" ]; then
    echo "Usage: $0 \"query text\""
    exit 1
fi

curl -s -X POST "${ARCHON_API}/knowledge/search" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$QUERY\", \"limit\": 5}" | jq .

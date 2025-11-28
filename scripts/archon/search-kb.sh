#!/bin/bash
# Archon API Helper - Search Knowledge Base
# Usage: ./scripts/archon/search-kb.sh "query text"
# Example: ./scripts/archon/search-kb.sh "authentication JWT"

ARCHON_API="http://localhost:8181/api"
QUERY="${1:-}"

if [ -z "$QUERY" ]; then
    echo "Usage: $0 \"query text\""
    exit 1
fi

curl -s -X POST "${ARCHON_API}/knowledge/search" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$QUERY\", \"limit\": 5}" | jq .

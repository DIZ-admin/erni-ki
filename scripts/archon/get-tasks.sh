#!/usr/bin/env bash
# Archon API Helper - Get Tasks
# Usage: ./scripts/archon/get-tasks.sh [status]
# Example: ./scripts/archon/get-tasks.sh todo

set -euo pipefail
IFS=$'\n\t'

ARCHON_API="${ARCHON_API:-http://localhost:8181/api}"
STATUS="${1:-all}"

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

if [ "$STATUS" = "all" ]; then
    curl -s "${ARCHON_API}/tasks" | jq '.tasks[] | {id, title, status, priority, assignee}'
else
    curl -s "${ARCHON_API}/tasks" | jq ".tasks[] | select(.status == \"$STATUS\") | {id, title, status, priority, assignee}"
fi

#!/bin/bash
# Archon API Helper - Get Tasks
# Usage: ./scripts/archon/get-tasks.sh [status]
# Example: ./scripts/archon/get-tasks.sh todo

ARCHON_API="http://localhost:8181/api"
STATUS="${1:-all}"

if [ "$STATUS" = "all" ]; then
    curl -s "${ARCHON_API}/tasks" | jq '.tasks[] | {id, title, status, priority, assignee}'
else
    curl -s "${ARCHON_API}/tasks" | jq ".tasks[] | select(.status == \"$STATUS\") | {id, title, status, priority, assignee}"
fi

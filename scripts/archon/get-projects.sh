#!/usr/bin/env bash
# Archon API Helper - Get Projects
# Usage: ./scripts/archon/get-projects.sh

set -euo pipefail
IFS=$'\n\t'

ARCHON_API="${ARCHON_API:-http://localhost:8181/api}"

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required" >&2; exit 1; }

curl -s "${ARCHON_API}/projects" | jq '.projects[] | {id, title, description, status, created_at}'

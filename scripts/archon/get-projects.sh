#!/bin/bash
# Archon API Helper - Get Projects
# Usage: ./scripts/archon/get-projects.sh

ARCHON_API="http://localhost:8181/api"

curl -s "${ARCHON_API}/projects" | jq '.projects[] | {id, title, description, status, created_at}'

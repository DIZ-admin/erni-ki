#!/usr/bin/env bash
# ============================================================================
# ERNI-KI Docker Compose Wrapper
# ============================================================================
# Convenient wrapper for modular docker-compose configuration.
#
# Usage:
#   ./docker-compose.sh up -d           # Start all services
#   ./docker-compose.sh down            # Stop all services
#   ./docker-compose.sh ps              # List services
#   ./docker-compose.sh logs -f nginx   # Follow nginx logs
#
# Modules:
#   - base.yml:       Networks, logging, infrastructure (watchtower)
#   - data.yml:       PostgreSQL, Redis
#   - ai.yml:         Ollama, LiteLLM, OpenWebUI, Docling, Auth, Support
#   - gateway.yml:    Nginx, Cloudflared, Backrest
#   - monitoring.yml: Prometheus, Grafana, Loki, Alertmanager, Exporters
#
# Author: ERNI-KI Team
# Version: 1.0.0
# ============================================================================

set -euo pipefail

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Compose files in dependency order
COMPOSE_FILES=(
  "compose/base.yml"
  "compose/data.yml"
  "compose/ai.yml"
  "compose/gateway.yml"
  "compose/monitoring.yml"
)

# macOS override (CPU, Apple Silicon). Auto-added on Darwin if file exists.
MAC_OVERRIDE="compose/mac.override.yml"
if [ "$(uname -s)" = "Darwin" ] && [ -f "$MAC_OVERRIDE" ]; then
  COMPOSE_FILES+=("$MAC_OVERRIDE")
fi

# Build docker compose command
build_compose_cmd() {
  local cmd="docker compose"
  for file in "${COMPOSE_FILES[@]}"; do
    if [ ! -f "$file" ]; then
      echo -e "${RED}Error: Required file $file not found${NC}" >&2
      exit 1
    fi
    cmd="$cmd -f $file"
  done
  echo "$cmd"
}

# Main execution
main() {
  # Check if docker compose is available
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}" >&2
    exit 1
  fi

  if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not available${NC}" >&2
    echo -e "${YELLOW}Please install Docker Compose v2 or update Docker Desktop${NC}" >&2
    exit 1
  fi

  # Build and execute command
  local compose_cmd
  compose_cmd=$(build_compose_cmd)

  # Show what we're doing
  if [ "${1:-}" != "ps" ] && [ "${1:-}" != "version" ]; then
    echo -e "${GREEN}Executing:${NC} $compose_cmd $*"
  fi

  # Execute
  eval "$compose_cmd $*"
}

# Show help if no arguments
if [ $# -eq 0 ]; then
  echo "ERNI-KI Docker Compose Wrapper"
  echo
  echo "Usage: $0 <docker-compose-command> [options]"
  echo
  echo "Examples:"
  echo "  $0 up -d              Start all services in background"
  echo "  $0 up ai              Start only AI services (requires base, data)"
  echo "  $0 down               Stop all services"
  echo "  $0 ps                 List all services"
  echo "  $0 logs -f nginx      Follow nginx logs"
  echo "  $0 restart openwebui  Restart OpenWebUI"
  echo "  $0 exec db psql       Execute psql in database container"
  echo
  echo "Modules loaded (in order):"
  for file in "${COMPOSE_FILES[@]}"; do
    echo "  - $file"
  done
  echo
  exit 0
fi

main "$@"

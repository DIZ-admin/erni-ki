#!/usr/bin/env bash
# =============================================================================
# Docker Compose Integration Test Runner
# =============================================================================
# Usage: ./scripts/integration-test.sh [--no-cleanup]
#
# This script:
# 1. Starts the test Docker Compose stack
# 2. Waits for all services to be healthy
# 3. Runs integration tests
# 4. Cleans up (unless --no-cleanup is specified)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="${PROJECT_ROOT}/compose.test.yml"
WAIT_TIMEOUT=120  # seconds
CLEANUP=${CLEANUP:-true}

# Parse arguments
for arg in "$@"; do
  case $arg in
    --no-cleanup)
      CLEANUP=false
      shift
      ;;
  esac
done

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
  if [ "$CLEANUP" = true ]; then
    log_info "Cleaning up test containers..."
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true
  else
    log_warn "Skipping cleanup (--no-cleanup specified)"
    log_info "To clean up manually: docker compose -f compose.test.yml down -v"
  fi
}

# Trap for cleanup on exit
trap cleanup EXIT

main() {
  cd "$PROJECT_ROOT"

  log_info "Starting Docker Compose integration tests..."
  log_info "Compose file: ${COMPOSE_FILE}"

  # Validate compose file
  log_info "Validating compose configuration..."
  if ! docker compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null; then
    log_error "Invalid compose configuration"
    exit 1
  fi

  # Clean up any previous test containers
  log_info "Cleaning up previous test containers..."
  docker compose -f "$COMPOSE_FILE" down -v --remove-orphans 2>/dev/null || true

  # Build and start services
  log_info "Building and starting test services..."
  docker compose -f "$COMPOSE_FILE" build --quiet
  docker compose -f "$COMPOSE_FILE" up -d

  # Wait for services to be healthy
  log_info "Waiting for services to be healthy (timeout: ${WAIT_TIMEOUT}s)..."

  local start_time
  start_time=$(date +%s)
  local all_healthy=false

  while [ $(($(date +%s) - start_time)) -lt "$WAIT_TIMEOUT" ]; do
    local unhealthy_count
    unhealthy_count=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | \
      jq -r 'select(.Health != "healthy" and .Health != "" and .State == "running")' | \
      wc -l || echo "0")

    if [ "$unhealthy_count" -eq 0 ]; then
      # Double check all services are running
      local running_count
      running_count=$(docker compose -f "$COMPOSE_FILE" ps --format json 2>/dev/null | \
        jq -r 'select(.State == "running")' | wc -l || echo "0")

      if [ "$running_count" -ge 5 ]; then
        all_healthy=true
        break
      fi
    fi

    echo -n "."
    sleep 2
  done
  echo ""

  if [ "$all_healthy" = false ]; then
    log_error "Timeout waiting for services to be healthy"
    log_info "Container status:"
    docker compose -f "$COMPOSE_FILE" ps
    log_info "Container logs:"
    docker compose -f "$COMPOSE_FILE" logs --tail=50
    exit 1
  fi

  log_info "All services are healthy!"
  docker compose -f "$COMPOSE_FILE" ps

  # Run integration tests
  log_info "Running integration tests..."
  INTEGRATION_TEST=1 bun test tests/integration/docker-compose-smoke.test.ts
  local test_exit_code=$?

  if [ $test_exit_code -eq 0 ]; then
    log_info "All integration tests passed!"
  else
    log_error "Integration tests failed with exit code: $test_exit_code"
    log_info "Container logs for debugging:"
    docker compose -f "$COMPOSE_FILE" logs --tail=100
  fi

  exit $test_exit_code
}

main "$@"

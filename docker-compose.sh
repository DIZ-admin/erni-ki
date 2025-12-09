#!/usr/bin/env bash
# ============================================================================
# ERNI-KI Docker Compose Wrapper
# ============================================================================
# Convenient wrapper for modular docker-compose configuration.
# Automatically detects OS and loads appropriate configuration.
#
# IMPORTANT: This script ensures correct configuration for each platform:
#   - Linux:  Uses NVIDIA GPU runtime, production secrets, full features
#   - macOS:  Uses CPU-only mode, simplified secrets, development features
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
# Platform-specific:
#   - mac.override.yml: macOS overrides (CPU mode, no NVIDIA)
#
# Author: ERNI-KI Team
# Version: 2.0.0
# ============================================================================

set -euo pipefail

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# ============================================================================
# OS Detection
# ============================================================================
detect_os() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Get current OS
readonly CURRENT_OS=$(detect_os)

# ============================================================================
# Platform Validation
# ============================================================================
validate_linux_environment() {
  local errors=0

  # Check NVIDIA driver
  if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Warning: nvidia-smi not found - GPU features may not work${NC}" >&2
    errors=$((errors + 1))
  else
    if ! nvidia-smi &> /dev/null; then
      echo -e "${YELLOW}Warning: NVIDIA driver not responding${NC}" >&2
      errors=$((errors + 1))
    fi
  fi

  # Check Docker NVIDIA runtime
  if ! docker info 2>/dev/null | grep -q "nvidia"; then
    echo -e "${YELLOW}Warning: NVIDIA Docker runtime not detected${NC}" >&2
    echo -e "${YELLOW}  Install: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html${NC}" >&2
    errors=$((errors + 1))
  fi

  # Check OS-specific secrets directory
  local secrets_dir="secrets/linux"
  if [ ! -d "$secrets_dir" ]; then
    echo -e "${RED}Error: $secrets_dir/ directory not found${NC}" >&2
    echo -e "${YELLOW}  Create it and add required secret files${NC}" >&2
    return 1
  fi

  # Check critical secrets exist
  local required_secrets=(
    "postgres_password.txt"
    "redis_password.txt"
    "litellm_db_password.txt"
    "openwebui_secret_key.txt"
  )

  for secret in "${required_secrets[@]}"; do
    if [ ! -f "$secrets_dir/$secret" ]; then
      echo -e "${RED}Error: Required secret $secrets_dir/$secret not found${NC}" >&2
      errors=$((errors + 1))
    fi
  done

  if [ $errors -gt 0 ]; then
    echo -e "${YELLOW}Found $errors warning(s). System may not function correctly.${NC}" >&2
  fi

  return 0
}

validate_macos_environment() {
  local errors=0

  # Check Docker Desktop
  if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running${NC}" >&2
    echo -e "${YELLOW}  Start Docker Desktop and try again${NC}" >&2
    return 1
  fi

  # Check mac.override.yml exists
  if [ ! -f "compose/mac.override.yml" ]; then
    echo -e "${RED}Error: compose/mac.override.yml not found${NC}" >&2
    echo -e "${YELLOW}  This file is required for macOS compatibility${NC}" >&2
    return 1
  fi

  # Check OS-specific secrets directory
  local secrets_dir="secrets/mac"
  if [ ! -d "$secrets_dir" ]; then
    echo -e "${RED}Error: $secrets_dir/ directory not found${NC}" >&2
    echo -e "${YELLOW}  Create it and add required secret files for macOS${NC}" >&2
    return 1
  fi

  # Check critical secrets exist
  local required_secrets=(
    "postgres_password.txt"
    "redis_password.txt"
    "litellm_db_password.txt"
    "openwebui_secret_key.txt"
  )

  for secret in "${required_secrets[@]}"; do
    if [ ! -f "$secrets_dir/$secret" ]; then
      echo -e "${RED}Error: Required secret $secrets_dir/$secret not found${NC}" >&2
      errors=$((errors + 1))
    fi
  done

  # Check local env files
  if [ ! -f "env/litellm.local" ]; then
    echo -e "${YELLOW}Warning: env/litellm.local not found - using defaults${NC}" >&2
  fi

  # Warn about GPU limitations
  echo -e "${BLUE}Info: Running in macOS CPU mode (no NVIDIA GPU)${NC}" >&2

  if [ $errors -gt 0 ]; then
    echo -e "${YELLOW}Found $errors warning(s). System may not function correctly.${NC}" >&2
  fi

  return 0
}

# ============================================================================
# Compose File Selection
# ============================================================================
get_compose_files() {
  local files=()

  # Base modules (always loaded)
  files+=(
    "compose/base.yml"
    "compose/data.yml"
    "compose/ai.yml"
    "compose/gateway.yml"
    "compose/monitoring.yml"
  )

  # Platform-specific overrides
  case "$CURRENT_OS" in
    macos)
      if [ -f "compose/mac.override.yml" ]; then
        files+=("compose/mac.override.yml")
      else
        echo -e "${RED}Error: macOS detected but compose/mac.override.yml not found!${NC}" >&2
        exit 1
      fi
      ;;
    linux)
      # Linux uses base config with NVIDIA runtime
      # Optional: linux.override.yml if exists
      if [ -f "compose/linux.override.yml" ]; then
        files+=("compose/linux.override.yml")
      fi
      ;;
    *)
      echo -e "${RED}Error: Unsupported operating system: $CURRENT_OS${NC}" >&2
      echo -e "${YELLOW}Supported: Linux, macOS${NC}" >&2
      exit 1
      ;;
  esac

  # Local customizations (optional, loaded last)
  if [ -f "compose.override.yml" ]; then
    files+=("compose.override.yml")
  fi

  echo "${files[@]}"
}

# ============================================================================
# Build Docker Compose Command
# ============================================================================
build_compose_cmd() {
  local cmd="docker compose"
  local files
  read -ra files <<< "$(get_compose_files)"

  for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
      echo -e "${RED}Error: Required file $file not found${NC}" >&2
      exit 1
    fi
    cmd="$cmd -f $file"
  done

  echo "$cmd"
}

# ============================================================================
# Display Configuration Info
# ============================================================================
show_config() {
  echo -e "${BOLD}ERNI-KI Docker Compose Wrapper v2.0${NC}"
  echo

  # OS Info
  case "$CURRENT_OS" in
    linux)
      echo -e "Platform:    ${GREEN}Linux (Production)${NC}"
      echo -e "GPU:         ${GREEN}NVIDIA enabled${NC}"
      echo -e "Secrets:     ${GREEN}secrets/linux/${NC}"
      ;;
    macos)
      echo -e "Platform:    ${YELLOW}macOS (Development)${NC}"
      echo -e "GPU:         ${YELLOW}CPU-only mode${NC}"
      echo -e "Secrets:     ${YELLOW}secrets/mac/${NC}"
      ;;
    *)
      echo -e "Platform:    ${RED}Unknown ($CURRENT_OS)${NC}"
      ;;
  esac

  echo
  echo "Compose files loaded:"
  local files
  read -ra files <<< "$(get_compose_files)"
  for file in "${files[@]}"; do
    if [[ "$file" == *"mac.override"* ]]; then
      echo -e "  ${YELLOW}+ $file${NC} (macOS override)"
    elif [[ "$file" == *"linux.override"* ]]; then
      echo -e "  ${GREEN}+ $file${NC} (Linux override)"
    elif [[ "$file" == *"override"* ]]; then
      echo -e "  ${BLUE}+ $file${NC} (local override)"
    else
      echo "  - $file"
    fi
  done
  echo
}

# ============================================================================
# Help
# ============================================================================
show_help() {
  show_config

  echo "Usage: $0 <docker-compose-command> [options]"
  echo
  echo "Commands:"
  echo "  up -d              Start all services in background"
  echo "  down               Stop all services"
  echo "  ps                 List all services"
  echo "  logs -f <service>  Follow service logs"
  echo "  restart <service>  Restart a service"
  echo "  exec <svc> <cmd>   Execute command in container"
  echo "  config             Show merged compose config"
  echo
  echo "Examples:"
  echo "  $0 up -d                    # Start everything"
  echo "  $0 logs -f ollama           # Watch Ollama logs"
  echo "  $0 restart litellm          # Restart LiteLLM"
  echo "  $0 exec db psql -U postgres # Connect to PostgreSQL"
  echo

  case "$CURRENT_OS" in
    linux)
      echo -e "${GREEN}Linux Mode:${NC}"
      echo "  - NVIDIA GPU runtime enabled"
      echo "  - Production secrets from secrets/"
      echo "  - Full monitoring stack"
      ;;
    macos)
      echo -e "${YELLOW}macOS Mode:${NC}"
      echo "  - CPU-only (no GPU acceleration)"
      echo "  - Simplified secrets handling"
      echo "  - Some services may be slower"
      echo "  - Watchtower disabled"
      ;;
  esac
  echo
}

# ============================================================================
# OS-Specific Secrets Setup
# ============================================================================
setup_secrets_symlink() {
  local secrets_link="compose/secrets"
  local target_dir

  case "$CURRENT_OS" in
    linux)
      target_dir="../secrets/linux"
      ;;
    macos)
      target_dir="../secrets/mac"
      ;;
    *)
      echo -e "${RED}Error: Unknown OS for secrets setup${NC}" >&2
      return 1
      ;;
  esac

  # Check if target directory exists
  if [ ! -d "secrets/${CURRENT_OS}" ]; then
    echo -e "${RED}Error: Secrets directory 'secrets/${CURRENT_OS}' not found${NC}" >&2
    echo -e "${YELLOW}  Create it and add required secret files${NC}" >&2
    return 1
  fi

  # Create or update symlink
  if [ -L "$secrets_link" ]; then
    local current_target
    current_target=$(readlink "$secrets_link")
    if [ "$current_target" != "$target_dir" ]; then
      echo -e "${BLUE}Updating secrets symlink: $current_target -> $target_dir${NC}"
      rm "$secrets_link"
      ln -sf "$target_dir" "$secrets_link"
    fi
  elif [ -d "$secrets_link" ]; then
    echo -e "${RED}Error: $secrets_link is a directory, not a symlink${NC}" >&2
    echo -e "${YELLOW}  Remove it and re-run: rm -rf $secrets_link${NC}" >&2
    return 1
  else
    echo -e "${BLUE}Creating secrets symlink: $secrets_link -> $target_dir${NC}"
    ln -sf "$target_dir" "$secrets_link"
  fi

  return 0
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
  # Check Docker availability
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}" >&2
    exit 1
  fi

  if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose v2 is not available${NC}" >&2
    echo -e "${YELLOW}Install: https://docs.docker.com/compose/install/${NC}" >&2
    exit 1
  fi

  # Setup OS-specific secrets symlink
  setup_secrets_symlink || exit 1

  # Validate environment for startup commands
  if [[ "${1:-}" == "up" ]] || [[ "${1:-}" == "start" ]]; then
    case "$CURRENT_OS" in
      linux)
        validate_linux_environment || exit 1
        ;;
      macos)
        validate_macos_environment || exit 1
        ;;
    esac
  fi

  # Build command
  local compose_cmd
  compose_cmd=$(build_compose_cmd)

  # Show execution info (except for ps/version)
  if [[ "${1:-}" != "ps" ]] && [[ "${1:-}" != "version" ]] && [[ "${1:-}" != "config" ]]; then
    echo -e "${GREEN}[$CURRENT_OS]${NC} $compose_cmd $*"
  fi

  # Execute
  eval "$compose_cmd $*"
}

# ============================================================================
# Entry Point
# ============================================================================
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  show_help
  exit 0
fi

main "$@"

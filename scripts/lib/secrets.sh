#!/usr/bin/env bash
# =============================================================================
# ERNI-KI Docker Entrypoint Secrets Library
# =============================================================================
# Unified functions for secret loading in container entrypoints.
# Source this file in entrypoint scripts:
#   source /opt/erni/lib/secrets.sh
#
# Functions:
#   log         - Log message to stderr with script name prefix
#   log_error   - Log error and exit with code 1
#   read_secret - Read secret from /run/secrets/, trimming CRLF/LF
#   require_secret - Read secret or exit if missing (for required secrets)
#   optional_secret - Read secret or return empty (for optional secrets)
# =============================================================================

# Strict mode for reliable error handling
set -euo pipefail

# Script name for logging (basename of calling script)
__SCRIPT_NAME="${__SCRIPT_NAME:-$(basename "${BASH_SOURCE[1]:-$0}")}"

# =============================================================================
# Logging Functions
# =============================================================================

log() {
  echo "[${__SCRIPT_NAME}] $*" >&2
}

log_error() {
  echo "[${__SCRIPT_NAME}] ERROR: $*" >&2
  exit 1
}

log_warn() {
  echo "[${__SCRIPT_NAME}] WARNING: $*" >&2
}

log_debug() {
  if [[ "${DEBUG:-0}" != "0" ]]; then
    echo "[${__SCRIPT_NAME}] DEBUG: $*" >&2
  fi
}

# =============================================================================
# Secret Loading Functions
# =============================================================================

# Read secret from /run/secrets/, trimming CRLF and LF
# Usage: value=$(read_secret "secret_name")
# Returns: 0 on success, 1 if secret not found
read_secret() {
  local secret_name="$1"
  local secret_file="/run/secrets/${secret_name}"

  if [[ ! -f "${secret_file}" ]]; then
    log_debug "Secret file not found: ${secret_file}"
    return 1
  fi

  # Read and trim CRLF/LF (handles both Unix and Windows line endings)
  tr -d '\r\n' < "${secret_file}"
  return 0
}

# Read required secret or exit with error
# Usage: value=$(require_secret "secret_name")
require_secret() {
  local secret_name="$1"
  local value

  if ! value=$(read_secret "${secret_name}"); then
    log_error "Required secret not found: ${secret_name}"
  fi

  if [[ -z "${value}" ]]; then
    log_error "Required secret is empty: ${secret_name}"
  fi

  echo "${value}"
}

# Read optional secret, return empty string if not found
# Usage: value=$(optional_secret "secret_name" "default_value")
optional_secret() {
  local secret_name="$1"
  local default_value="${2:-}"
  local value

  if value=$(read_secret "${secret_name}"); then
    if [[ -n "${value}" ]]; then
      echo "${value}"
      return 0
    fi
  fi

  log_debug "Optional secret not found or empty: ${secret_name}, using default"
  echo "${default_value}"
}

# =============================================================================
# Environment Variable Helpers
# =============================================================================

# Export secret as environment variable
# Usage: export_secret "SECRET_NAME" "secret_file_name" [required|optional]
export_secret() {
  local env_var="$1"
  local secret_name="$2"
  local mode="${3:-required}"
  local value

  case "${mode}" in
    required)
      value=$(require_secret "${secret_name}")
      ;;
    optional)
      value=$(optional_secret "${secret_name}")
      if [[ -z "${value}" ]]; then
        log_debug "Skipping export of ${env_var} (optional secret not found)"
        return 0
      fi
      ;;
    *)
      log_error "Invalid mode: ${mode}. Use 'required' or 'optional'"
      ;;
  esac

  export "${env_var}=${value}"
  log_debug "Exported ${env_var} from secret ${secret_name}"
}

# =============================================================================
# Debug Helper
# =============================================================================

# Dump all environment variables (for debugging, excludes secrets)
dump_env() {
  if [[ "${DEBUG:-0}" != "0" ]]; then
    log_debug "Environment variables (excluding sensitive):"
    env | grep -vE '(PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL)' | sort | while read -r line; do
      log_debug "  ${line}"
    done
  fi
}

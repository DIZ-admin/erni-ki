#!/bin/sh
# =============================================================================
# ERNI-KI Docker Entrypoint Secrets Library (POSIX-compatible)
# =============================================================================
# Unified functions for secret loading in container entrypoints.
# Source this file in entrypoint scripts:
#   . /opt/erni/lib/secrets.sh
#
# Functions:
#   log         - Log message to stderr with script name prefix
#   log_error   - Log error and exit with code 1
#   read_secret - Read secret from /run/secrets/, trimming CRLF/LF
#   require_secret - Read secret or exit if missing (for required secrets)
#   optional_secret - Read secret or return empty (for optional secrets)
# =============================================================================

# Strict mode for reliable error handling (POSIX-compatible)
set -eu

# Script name for logging (basename of calling script)
# Use __SCRIPT_NAME if already set, otherwise derive from $0
# Uses POSIX parameter expansion instead of basename for minimal containers
__SCRIPT_NAME="${__SCRIPT_NAME:-${0##*/}}"

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
  if [ "${DEBUG:-0}" != "0" ]; then
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
  secret_name="$1"
  secret_file="/run/secrets/${secret_name}"

  if [ ! -f "${secret_file}" ]; then
    log_debug "Secret file not found: ${secret_file}"
    return 1
  fi

  # Read and trim CRLF/LF using shell read (POSIX-compatible, no external commands)
  # This handles minimal containers without tr/sed
  while IFS= read -r line || [ -n "$line" ]; do
    printf '%s' "$line"
  done < "${secret_file}"
  return 0
}

# Read required secret or exit with error
# Usage: value=$(require_secret "secret_name")
require_secret() {
  secret_name="$1"

  if ! value=$(read_secret "${secret_name}"); then
    log_error "Required secret not found: ${secret_name}"
  fi

  if [ -z "${value}" ]; then
    log_error "Required secret is empty: ${secret_name}"
  fi

  echo "${value}"
}

# Read optional secret, return empty string if not found
# Usage: value=$(optional_secret "secret_name" "default_value")
optional_secret() {
  secret_name="$1"
  default_value="${2:-}"

  if value=$(read_secret "${secret_name}"); then
    if [ -n "${value}" ]; then
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
  env_var="$1"
  secret_name="$2"
  mode="${3:-required}"

  case "${mode}" in
    required)
      value=$(require_secret "${secret_name}")
      ;;
    optional)
      value=$(optional_secret "${secret_name}")
      if [ -z "${value}" ]; then
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
  if [ "${DEBUG:-0}" != "0" ]; then
    log_debug "Environment variables (excluding sensitive):"
    # Case-insensitive filtering to catch lowercase variants like my_password, api_key
    env | grep -viE '(PASSWORD|SECRET|KEY|TOKEN|CREDENTIAL|API_KEY|AUTH|BEARER)' | sort | while read -r line; do
      log_debug "  ${line}"
    done
  fi
}

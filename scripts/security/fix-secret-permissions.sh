#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Fix secret file permissions to secure mode (600)
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

fix_pattern() {
  local dir=$1
  local pattern=$2
  local fixed_ref=$3
  local skipped_ref=$4

  [[ ! -d "$dir" ]] && return 0

  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      # Use -L to follow symlinks and check actual file permissions
      current_perms=$(stat -L -c "%a" "$file" 2>/dev/null || stat -L -f "%OLp" "$file" 2>/dev/null)
      if [[ "$current_perms" != "600" ]]; then
        # For symlinks, resolve to actual file; chmod follows symlinks by default
        if chmod 600 "$file" 2>/dev/null; then
          log_info "✅ Fixed: $file ($current_perms → 600)"
          ((${fixed_ref}++)) || true
        else
          log_info "⚠️  Cannot fix: $file (run with sudo)"
        fi
      else
        ((${skipped_ref}++)) || true
      fi
    fi
  done < <(find "$dir" -name "$pattern" ! -name "*.example" -print0 2>/dev/null || true)
}

main() {
  local fixed=0
  local skipped=0

  log_info "Fixing secret file permissions..."

  # Fix secrets/ directory - .txt files (passwords, API keys)
  fix_pattern "secrets" "*.txt" fixed skipped

  # Fix secrets/ directory - private keys
  fix_pattern "secrets" "*.key" fixed skipped

  # Fix secrets/ directory - sensitive configs
  fix_pattern "secrets" "*.ini" fixed skipped
  fix_pattern "secrets" "*.conf" fixed skipped

  # Fix env/ directory
  fix_pattern "env" "*.env" fixed skipped

  log_info ""
  log_info "Summary:"
  log_info "  Fixed: $fixed files"
  log_info "  Already secure: $skipped files"
  log_info ""
  log_info "✅ Secret permissions secured"
}

main "$@"

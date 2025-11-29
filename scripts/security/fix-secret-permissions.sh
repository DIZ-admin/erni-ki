#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Fix secret file permissions to secure mode (600)
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

main() {
  local fixed=0
  local skipped=0

  log_info "Fixing secret file permissions..."

  # Fix secrets/ directory
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      current_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
      if [[ "$current_perms" != "600" ]]; then
        chmod 600 "$file"
        log_info "✅ Fixed: $file ($current_perms → 600)"
        ((fixed++))
      else
        ((skipped++))
      fi
    fi
  done < <(find secrets -name "*.txt" ! -name "*.example" -print0)

  # Fix env/ directory
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      current_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
      if [[ "$current_perms" != "600" ]]; then
        chmod 600 "$file"
        log_info "✅ Fixed: $file ($current_perms → 600)"
        ((fixed++))
      else
        ((skipped++))
      fi
    fi
  done < <(find env -name "*.env" ! -name "*.example" -print0 2>/dev/null || true)

  log_info ""
  log_info "Summary:"
  log_info "  Fixed: $fixed files"
  log_info "  Already secure: $skipped files"
  log_info ""
  log_info "✅ Secret permissions secured"
}

main "$@"

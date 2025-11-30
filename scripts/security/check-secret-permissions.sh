#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# Check secret file permissions (pre-commit hook)
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

check_permissions() {
  local dir=$1
  local pattern=$2
  local issues=0

  if [[ ! -d "$dir" ]]; then
    return 0
  fi

  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      current_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
      if [[ "$current_perms" != "600" ]]; then
        log_info "❌ INSECURE: $file has permissions $current_perms (should be 600)"
        ((issues++))
      fi
    fi
  done < <(find "$dir" -name "$pattern" ! -name "*.example" -print0 2>/dev/null || true)

  return $issues
}

main() {
  local total_issues=0

  log_info "Checking secret file permissions..."

  # Check secrets/ directory
  check_permissions "secrets" "*.txt" || total_issues=$((total_issues + $?))

  # Check env/ directory
  check_permissions "env" "*.env" || total_issues=$((total_issues + $?))

  if [[ $total_issues -gt 0 ]]; then
    log_info ""
    log_info "❌ Found $total_issues file(s) with insecure permissions"
    log_info ""
    log_info "Fix with: ./scripts/security/fix-secret-permissions.sh"
    exit 1
  fi

  log_info "✅ All secret files have secure permissions"
}

main "$@"

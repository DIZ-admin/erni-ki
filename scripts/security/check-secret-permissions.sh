#!/usr/bin/env bash
set -euo pipefail

# Check secret file permissions (pre-commit hook)
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

log() {
  echo "[check-secret-permissions] $*" >&2
}

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
        log "❌ INSECURE: $file has permissions $current_perms (should be 600)"
        ((issues++))
      fi
    fi
  done < <(find "$dir" -name "$pattern" ! -name "*.example" -print0 2>/dev/null || true)

  return $issues
}

main() {
  local total_issues=0

  log "Checking secret file permissions..."

  # Check secrets/ directory
  check_permissions "secrets" "*.txt" || total_issues=$((total_issues + $?))

  # Check env/ directory
  check_permissions "env" "*.env" || total_issues=$((total_issues + $?))

  if [[ $total_issues -gt 0 ]]; then
    log ""
    log "❌ Found $total_issues file(s) with insecure permissions"
    log ""
    log "Fix with: ./scripts/security/fix-secret-permissions.sh"
    exit 1
  fi

  log "✅ All secret files have secure permissions"
}

main "$@"

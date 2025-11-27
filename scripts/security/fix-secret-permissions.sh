#!/usr/bin/env bash
set -euo pipefail

# Fix secret file permissions to secure mode (600)
# Part of ERNI-KI security hardening
# Reference: docs/security/secrets-audit-2025-11-27.md

log() {
  echo "[fix-secret-permissions] $*" >&2
}

main() {
  local fixed=0
  local skipped=0

  log "Fixing secret file permissions..."

  # Fix secrets/ directory
  while IFS= read -r -d '' file; do
    if [[ -f "$file" ]]; then
      current_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
      if [[ "$current_perms" != "600" ]]; then
        chmod 600 "$file"
        log "✅ Fixed: $file ($current_perms → 600)"
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
        log "✅ Fixed: $file ($current_perms → 600)"
        ((fixed++))
      else
        ((skipped++))
      fi
    fi
  done < <(find env -name "*.env" ! -name "*.example" -print0 2>/dev/null || true)

  log ""
  log "Summary:"
  log "  Fixed: $fixed files"
  log "  Already secure: $skipped files"
  log ""
  log "✅ Secret permissions secured"
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${DOC_SHARED_ROOT:-$REPO_ROOT/data/docling/shared}"
WRITABLE_GROUP="${DOC_SHARED_GROUP:-docling-data}"
READONLY_GROUP="${DOC_SHARED_READONLY_GROUP:-docling-readonly}"
OWNER="${DOC_SHARED_OWNER:-${USER:-docling-maint}}"
PERMS="${DOC_SHARED_PERMS:-770}"
USE_SUDO="${DOC_SHARED_USE_SUDO:-true}"

run() {
  if "$@"; then
    return 0
  fi
  if [[ "$USE_SUDO" == "true" ]] && command -v sudo >/dev/null; then
    sudo "$@"
  else
    return 1
  fi
}

ensure_group() {
  local group="$1"
  if getent group "$group" >/dev/null; then
    return 0
  fi
  log_info "Creating group $group"
  run groupadd -r "$group" || log_info "WARN: cannot create group $group (already exists?)"
}

ensure_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    return 0
  fi
  log_info "Creating directory $dir"
  run mkdir -p "$dir"
}

ensure_group "$WRITABLE_GROUP"
ensure_group "$READONLY_GROUP"

ensure_dir "$ROOT"
ensure_dir "$ROOT/uploads"
ensure_dir "$ROOT/processed"
ensure_dir "$ROOT/exports"
ensure_dir "$ROOT/quarantine"
ensure_dir "$ROOT/tmp"

log_info "Setting owner ${OWNER}:${WRITABLE_GROUP} and permissions ${PERMS}"
run chown -R "${OWNER}:${WRITABLE_GROUP}" "$ROOT"
run chmod 770 "$ROOT"
run chmod "$PERMS" "$ROOT"/{uploads,processed,exports,quarantine,tmp}

log_info "Applying ACL for readonly group ${READONLY_GROUP} on exports/"
if command -v setfacl >/dev/null; then
  run setfacl -m "g:${READONLY_GROUP}:rx" "$ROOT/exports"
else
  log_info "WARN: setfacl not available, skipping readonly ACL"
fi

log_info "Docling shared volume policy enforced at $ROOT"

#!/usr/bin/env bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
USER_NAME="${DOCLING_CLEANUP_USER:-${USER:-docling-maint}}"
SCRIPT_PATH="$REPO_ROOT/scripts/maintenance/docling-shared-cleanup.sh --apply"

cat <<EOF
# /etc/sudoers.d/docling-cleanup
Defaults!$SCRIPT_PATH env_keep += DOC_SHARED_ROOT,DOC_SHARED_OWNER,DOC_SHARED_GROUP,DOC_SHARED_USE_SUDO
$USER_NAME ALL=(root) NOPASSWD: $SCRIPT_PATH
EOF

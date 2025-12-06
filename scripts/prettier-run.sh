#!/usr/bin/env bash

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

MODE=${1:-check} # check or write

if [[ "$MODE" != "check" && "$MODE" != "write" ]]; then
  echo "Usage: $0 [check|write]" >&2
  exit 2
fi

PATTERNS=(
  "*.js"
  "*.jsx"
  "*.ts"
  "*.tsx"
  "*.mjs"
  "*.cjs"
  "*.json"
  "*.md"
  "*.mdx"
  "*.yml"
  "*.yaml"
  "*.css"
  "*.scss"
)

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must be run inside a git repository." >&2
  exit 2
fi

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

git ls-files -z -- "${PATTERNS[@]}" >"$tmpfile"

PRETTIER_VERSION=${PRETTIER_VERSION:-"3.6.2"}

if [[ ! -s "$tmpfile" ]]; then
  echo "No files matched for Prettier."
  exit 0
fi

CMD_ARGS=("--log-level" "warn" "--ignore-unknown")
if [[ "$MODE" == "check" ]]; then
  CMD_ARGS=("prettier@${PRETTIER_VERSION}" "--check" "--cache" "${CMD_ARGS[@]}")
else
  CMD_ARGS=("prettier@${PRETTIER_VERSION}" "--write" "${CMD_ARGS[@]}")
fi

xargs -0 bunx "${CMD_ARGS[@]}" <"$tmpfile"

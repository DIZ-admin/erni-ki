#!/usr/bin/env bash
# Shared shell helpers for ERNI-KI scripts

set -euo pipefail

__common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__project_root="$(cd "${__common_dir}/../.." && pwd)"

log_info() {
  printf "[INFO] %s\n" "$*"
}

log_warn() {
  printf "[WARN] %s\n" "$*"
}

log_error() {
  printf "[ERROR] %s\n" "$*" >&2
}

log_success() {
  printf "[SUCCESS] %s\n" "$*"
}

log_fatal() {
  local msg="$1"
  local code="${2:-1}"
  printf "[FATAL] %s\n" "$msg" >&2
  exit "$code"
}

get_project_root() {
  echo "${__project_root}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

version_compare() {
  # returns 1 if $1>$2, 0 if equal, -1 if $1<$2
  local v1="${1#v}"
  local v2="${2#v}"
  if [[ "$v1" == "$v2" ]]; then
    echo 0
    return 0
  fi
  # sort -V compares versions
  if [[ "$(printf "%s\n%s\n" "$v1" "$v2" | sort -V | head -n1)" == "$v1" ]]; then
    echo -1
  else
    echo 1
  fi
}

read_secret() {
  local name="$1"
  local paths=(
    "/run/secrets/${name}"
    "${__project_root}/secrets/${name}.txt"
  )
  for p in "${paths[@]}"; do
    if [[ -f "$p" ]]; then
      cat "$p"
      return 0
    fi
  done
  return 1
}

ensure_directory() {
  local dir="$1"
  mkdir -p "$dir"
}

get_docker_compose_cmd() {
  if command_exists "docker"; then
    if docker compose version >/dev/null 2>&1; then
      echo "docker compose"
      return 0
    fi
  fi
  if command_exists "docker-compose"; then
    echo "docker-compose"
    return 0
  fi
  log_error "docker compose not found"
  return 1
}

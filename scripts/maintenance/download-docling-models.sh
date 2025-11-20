#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ARTIFACT_DIR="${REPO_ROOT}/data/docling/docling-models"
IMAGE="ghcr.io/docling-project/docling-serve-cu126:main"

mkdir -p "${ARTIFACT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[docling-models] Требуется Docker" >&2
  exit 1
fi

echo "[docling-models] Подтягиваем образ ${IMAGE}"
docker pull "${IMAGE}"

echo "[docling-models] Скачиваем модели в ${ARTIFACT_DIR}" \
  && docker run --rm \
       -v "${ARTIFACT_DIR}:/docling-artifacts" \
       "${IMAGE}" \
       docling-tools models download --output-dir /docling-artifacts --all

echo "[docling-models] Готово"

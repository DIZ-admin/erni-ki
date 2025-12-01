---
language: ru
translation_status: draft
doc_version: '2025.11'
last_updated: '2025-11-30'
---

# Стандарты качества кода

Минимальный набор правил для внутренних скриптов и сервисов:

- Используйте shebang `#!/usr/bin/env bash` и `set -euo pipefail` для
  bash-скриптов.
- Придерживайтесь PEP8/ruff для Python; gofmt/goimports для Go.
- Обязательно добавляйте pre-commit хуки и проверяйте их перед коммитом.
- Документируйте сторонние зависимости и версии в README/requirements/go.mod.
- Пишите короткие описания целей в Makefile (`## описание`), чтобы работала цель
  `help`.

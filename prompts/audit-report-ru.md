Отчёт по аудиту ERNI-KI (DIZ-admin)

Дата: 2025-12-01
Статус: Обзор кода/безопасности/DevOps завершён; реализация рекомендаций не выполнялась.

Краткое резюме
- Общая зрелость высокая: CI охватывает ESLint+Ruff+Vitest+Go tests+Playwright mock, security workflow включает CodeQL, Trivy, Grype, Checkov, Gitleaks/Trufflehog.
- Основные риски: неподтверждённые версии контейнеров (SearXNG latest), неоднородные toolchain’ы (Go 1.24.0/1.24.4/1.24.10), референсные .env рядом с боевыми файлами, политика «только английский» нарушена в корневых файлах.
- Требуются правки в документации (версии, языки) и в шаблонах окружений; усиление секрет-сканирования и отказ от подавлений CKV_DOCKER_3 после миграции на non-root.

Ключевые риски (P0–P1)
- Контейнеры: `compose.yml` тянет `searxng/searxng:latest`; нет пинования digest. `watchtower` с root + docker.sock; CKV_DOCKER_3 подавлен. → Закрепить digest, план миграции на non-root/ socket proxy, снять подавление.
- Окружения: в `env/` лежат `.env` и `.example` бок о бок (`env/auth.env`, `env/db.env`). Риск утечки реальных конфигов и рассинхронизации. → Оставить только `*.example`, реальные файлы вынести/игнорировать.
- Языковая политика и точность: `README.md`, `.env.example`, `auth/Dockerfile`, env файлы на русском; версии (OpenWebUI 0.6.36) не совпадают с `compose.yml` (0.6.40). → Привести каноничные файлы к английскому и синхронизировать версии/даты.
- Инструменты Go: go.mod (1.24.4) vs auth/go.mod (1.24.0 + toolchain 1.24.10) vs CI (1.24.4/1.24.10). → Выбрать единый toolchain (рекомендуется 1.24.10) и обновить go.mod + CI.
- Secret scanning: Gitleaks в security workflow помечен `continue-on-error`; SARIF есть, но билд не падает. → Включить fail-on-verified или отдельный gate.

Рекомендации (приоритет)
1) Безопасность/контейнеры (P0): закрепить образы (особенно SearXNG), добавить non-root там, где возможно; пересмотреть `.checkov.yml` и снять CKV_DOCKER_3 после миграции. Рассмотреть docker socket proxy для watchtower.
2) Окружения и секреты (P0): перевести `env/*.env` → `*.env.example`, убедиться, что реальные .env в .gitignore; проверить secrets/*.example на полноту. Запустить `gitleaks detect` с fail-on-verified.
3) Документация и язык (P1): README/status/версии привести к фактическим версиям compose; основной контент — на английском, локализации хранить в `docs/en`, `docs/de`.
4) Toolchain консистентность (P1): единый Go toolchain в go.mod, auth/go.mod и CI; единый source of truth для Python tooling (pyproject vs requirements-dev) — удалить/обновить устаревшие pinned версии.
5) Качество/тесты (P2): поднять pytest `--cov-fail-under` с 60 до ≥80, добавить opt-in e2e smoke (Playwright real) в CI, расширить `npm audit`/Trivy на dev deps по расписанию.
6) Скрипты и устаревшие артефакты (P2): пометить legacy в `scripts/` (health-monitor.sh vs v2, мониторинги), удалить сгенерированные директории (`node_modules`, кеши) из репо и git history при наличии.

Наблюдения по покрытию и CI
- JS/TS: Vitest порог 90% задан, Playwright гоняется в mock-режиме; нет реального smoke-прогона.
- Python: порог 60% в CI; ruff/format присутствует, но dev зависимости размечены по двум файлам.
- Go: тесты с `-race` и coverage, golangci-lint в CI.
- Security: CodeQL, Trivy (FS + образ), Grype, Checkov soft-fail, Bandit/Ruff security. Node версии в CI (22.14.0) совпадают с package.json/volta.

Документация и онбординг
- README устарел по версиям и языку; env инструкции не отображают текущее разнообразие env/*.example и secrets/*.example.
- Политика английского языка нарушена в корневых файлах и env примерах; необходимо вынести локализации в docs/*.

Следующие шаги для внедрения
- Создать задачи: пинning образов, миграция на non-root + снятие CKV подавления, чистка env, синк README/версий/языка, унификация Go/Python tooling, поднятие pytest порога, усиление Gitleaks.

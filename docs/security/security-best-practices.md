---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Лучшие практики безопасности'
---

# Лучшие практики безопасности

## Управление секретами

- Не храните секреты в `compose.yml`; используйте Docker secrets, `.env` файлы
  вне git и Vault/Pass.
- Меняйте секреты при каждом релизе ядра или при инцидентах.

## Доступ к данным

- В PostgreSQL включайте Row-Level Security и создавайте отдельные роли для
  сервисов (`openwebui_reader`, `docling_ingestor`).
- В Redis применяйте ACL с командами `on ~* +@all` только для админов, остальные
  используют read-only профили.

## CI/CD и зависимости

- В CI (`security.yml`) запускайте `npm audit --omit=dev`, `gosec`, `trivy` и
  `grype`.
- Watchtower обновляет контейнеры только после проверки релиз-нотов и digest.

## Мониторинг и логирование

- Включайте централизованный сбор логов через Fluent Bit → Loki и
  Alertmanager-алерты для аномалий входа.
- Настройте `auditd` на хостах для отслеживания изменений в `/etc`, `/opt/erni`.

## Процедуры

- Проводите квартальные tabletop-учения: сценарии утечки секретов, DoS,
  компрометация API ключей.
- Документируйте runbook-и по отзывам токенов и смене сертификатов.

См. [security-policy.md](security-policy.md) и
[ssl-tls-setup.md](ssl-tls-setup.md) для деталей.

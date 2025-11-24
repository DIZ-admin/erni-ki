---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Лучшие практики безопасности'
---

# Лучшие практики безопасности

- Минимизируйте секреты в `compose.yml`: храните их в Docker secrets/ENV и не
  коммитьте в git.
- Включайте RLS и отдельные учётки для баз данных и кэша; избегайте общих
  паролей.
- Регулярно запускайте `npm audit --omit=dev` и `gosec` (см. CI workflow
  `security.yml`).
- Применяйте обновления образов через Watchtower/GitHub Actions и проверяйте
  changelog критичных зависимостей.
- Логируйте попытки аутентификации и используйте централизованный сбор логов
  (Loki/Fluent Bit).

Политики и роли — в [security-policy.md](security-policy.md). TLS и прокси — в
[ssl-tls-setup.md](ssl-tls-setup.md).

---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Аутентификация и авторизация'
---

# Аутентификация и авторизация

- Используйте JWT, выпускаемые auth-сервисом (`auth/main.go`), с секретом
  `WEBUI_SECRET_KEY` из Docker secrets/ENV.
- Для внешнего доступа рекомендуются Cloudflare Zero Trust туннели с mTLS или
  SSO.
- Минимизируйте срок жизни токенов и включайте `X-Request-ID` для трассировки.
- Проверяйте токены на каждом запросе к API и фронтенду; добавьте health-check
  `/validate` для автоматизации.

Дополнительно см. [security-policy.md](security-policy.md) для общих требований
и [ssl-tls-setup.md](ssl-tls-setup.md) для настройки TLS.

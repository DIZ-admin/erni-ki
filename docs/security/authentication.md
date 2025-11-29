---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'Аутентификация и авторизация'
---

# Аутентификация и авторизация

## Архитектура

-**Auth service**(`auth/main.go`) выдаёт JWT с aud=\"erni-ki\" и scope (`user`,
`admin`, `service`). -**Open WebUI**проверяет подпись через секрет
`WEBUI_SECRET_KEY`, дополнительно сверяет `session_id` в Redis. -**Внешние
клиенты**подключаются через Cloudflare Zero Trust либо OpenID Provider
(переносимый `id_token`).

## Рекомендации

1.**Срок жизни**токена ≤ 30 минут, рефреш через mTLS или SSO. 2.**Принудительный
logout**– инвалидация токена при смене пароля/ролей. 3.**Tracing**– добавляйте
`X-Request-ID` и сохраняйте связь токена с этим
идентификатором. 4.**Health-check**`/validate` – автоматическая проверка подписи
и срока действия.

## Onboarding новых пользователей

1. Создайте запись в `users` с минимальными правами.
2. Выдайте временный пароль по out-of-band каналу.
3. Принудите смену пароля при первом входе и активируйте 2FA (TOTP).
4. Добавьте пользователя в соответствующую группу Archon/LDAP.

## Incident response

- При подозрении на компрометацию токена используйте `revoke-token` API auth
  сервиса (встроенный CLI `make auth-revoke <token>`).
- Снимите дамп активных сессий и сравните IP/UA с baseline.
- Обновите секреты в Docker secrets, перезапустите `auth` и Open WebUI.

Дополнительно см. [security-policy.md](security-policy.md) и
[ssl-tls-setup.md](ssl-tls-setup.md).

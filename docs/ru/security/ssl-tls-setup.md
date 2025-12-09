---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
title: 'SSL/TLS настройка'
---

# Настройка SSL/TLS

## Сертификаты

- Публичные домены — Cloudflare Managed Certificates или Let’s Encrypt.
- Внутренние сервисы — mTLS с корпоративным CA.
- Обновление: автоматизируйте через certbot/CF API, храним секреты в `secrets/`.

## Конфигурация Nginx

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256';
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
add_header Content-Security-Policy "upgrade-insecure-requests";
```

- Включайте OCSP stapling (`ssl_stapling on`).
- Ограничьте доступ к `/conf/nginx/ssl` (`chmod 600`).

## Мониторинг

- Добавьте Prometheus экспортер `ssl_exporter` и алерты по сроку истечения.<
- Еженедельно запускайте `openssl s_client -connect host:443 -servername host`.
- Используйте Qualys SSL Labs для внешних проверок после каждого релиза.

## Инциденты

- При компрометации ключа немедленно отзовите сертификат и перевыпустите новые
  ключи с ротацией секретов.
- Уведомите клиентов через статус-страницу и security рассылку.

Дополнительно см. [security-policy.md](security-policy.md) и сетевые настройки в
`compose.yml`, `conf/nginx/`.

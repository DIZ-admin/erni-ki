---
language: ru
title: 'SSL/TLS настройка'
---

# Настройка SSL/TLS

- Для публичных доменов используйте Cloudflare Managed Certificates или Let’s
  Encrypt; закрытый трафик — через mTLS.
- Настаивайте TLS 1.2/1.3, запрещайте устаревшие шифры, включайте HSTS на
  фронт-прокси.
- Обновляйте сертификаты автоматически (certbot/CF API) и мониторьте сроки
  истечения.
- Храните приватные ключи вне репозитория (`secrets/`, Docker secrets) и
  ограничивайте доступ.
- Тестируйте конфигурации через `openssl s_client` и внешние сканеры (Mozilla
  Observatory/Qualys SSL Labs).

Подробнее о политиках см. [security-policy.md](security-policy.md); сетевые
настройки описаны в `compose.yml` и `conf/nginx/`.

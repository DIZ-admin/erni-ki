# Security & Governance

## Секреты и конфигурации

- Секреты хранятся в Docker secrets (пароли БД, ключи LiteLLM/OpenWebUI и др.).
- Конфиги Prometheus/Alertmanager/gitignored версии — используйте `.example`
  файлы или шаблоны; не храните прод-данные в репозитории.
- Обновление digest для образов без версий — обязательное требование (см.
  `docs/operations/maintenance/image-upgrade-checklist.md`).

## Доступ и CI/CD

- Политики GitHub: `docs/operations/core/github-governance.md`.
- Environments и секреты GitHub Actions:
  `docs/reference/github-environments-setup.md`.
- Branch protection: PR+review, обязательные проверки `ci`, `security`,
  `deploy-environments`.

## Сеть и периметр

- Nginx — единственная публичная точка; Cloudflared Tunnel публикует Nginx.
- Мониторинг и экспортёры доступны только с localhost (или через защищённый
  прокси/VPN/SSH).
- JWT Auth сервис защищает внутренние API.

## Хардненинг контейнеров

- Следите, чтобы образы использовали pinned версии, не `latest`.
- Non-root пользователи и снижение `oom_score_adj` для критичных сервисов — см.
  `docs/architecture/service-inventory.md`.

## Аудиты

- Конфигурационный аудит: `docs/archive/audits/`, в т.ч. предупреждения по
  закреплению версий, non-root, консистентности Node.js.

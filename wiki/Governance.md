# Governance & Updates

- **Ответственность:** изменения wiki вносятся вместе с изменениями
  конфигов/кода (PR → develop). За релиз/проверку отвечает владелец задачи.
- **Когда обновлять:** после правок в `compose.yml`, `conf/nginx/*`,
  `conf/litellm/config.yaml`, security/perimeter, CI/CD, secrets. Перед релизом
  — сверить Checklists.
- **Запреты:** не добавлять секреты, токены, реальные пароли/ключи/URLs
  приватных сервисов. Проверять detect-secrets/commit hooks.
- **Синхронизация:** фиксировать дату обновления на Home, указывать pending
  задачи, вычищать устаревшие комментарии.
- **Домены/CORS/CSP/ACL:** при добавлении доменов обновлять allowlist в
  `conf/nginx/nginx.conf` и `conf/nginx/conf.d/default.conf`; проверять CSP/CORS
  и ACL (SearXNG API закрыт на RFC1918/localhost).
- **Ревью:** wiki-правки проходят обычный PR-ревью. При смене политики
  безопасности — обязательный просмотр владельцем безопасности/DevOps.
- **Проверки:** перед коммитом — husky/pre-commit, detect-secrets,
  prettier/markdownlint. После изменений — убедиться, что ссылки на задачи
  актуальны.

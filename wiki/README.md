# ERNI-KI Wiki — Maintainers Guide

## Purpose

- Централизованная справка по эксплуатации стека (OpenWebUI, LiteLLM, Ollama,
  Docling, Tika, EdgeTTS, Nginx/Auth, PostgreSQL, Redis, observability).
- Быстрый вход для инженеров (деплой, операции, безопасность, чек-листы).
- Источник диаграмм и актуальных pending-задач.

## Структура страниц

- Home — навигация, дата обновления, pending-задачи.
- Architecture — слои/сервисы, ресурсы, ACL; ссылки на диаграммы.
- Deployment — локал/прод, secrets, GPU, pinned образы.
- Operations — рутины, бэкапы, read-only rollout (pending), интеграционные тесты
  (pending).
- Monitoring-Alerts — стек, дашборды, алерты, ACL для SearXNG API.
- Security — секреты, CORS/CSP/ACL, периметр, hardening, pending работы.
- Checklists — релиз/обновления/безопасность + проверка открытых задач.
- FAQ — частые вопросы.
- Diagrams — mermaid-схемы (архитектура, потоки, observability, периметр).
- Governance — правила обновления wiki, запрет секретов, ревью.

## Правила обновления

- Обновляйте wiki при любых изменениях конфигов/периметра/CI/secrets.
- Фиксируйте дату на Home и актуальный список pending задач.
- Не размещайте секреты, токены, реальные пароли или приватные URL.
- Проверяйте CORS/CSP/ACL при добавлении доменов; SearXNG API остаётся закрытым
  (RFC1918/localhost).
- Удаляйте устаревшие комментарии/пометки, синхронизируйте с Archon задачами.

## Диаграммы (mermaid)

- Используйте базовый синтаксис (`flowchart`/`sequence`), избегайте dotted
  labels/неподдерживаемых стилей — GitHub может не рендерить.
- Проверяйте рендер на GitHub Wiki после пуша.

## Публикация в GitHub Wiki

```bash
git clone https://github.com/DIZ-admin/erni-ki.wiki.git
cd erni-ki.wiki
cp -r ../erni-ki/wiki/* .
git status
git add .
git commit -m "Update wiki content"
git push origin master   # wiki использует master
```

## Чек-лист перед коммитом

- husky/pre-commit прошёл (prettier, detect-secrets).
- Pending задачи отражены на Home/Checklists/Security/Operations.
- Ссылки на диаграммы/страницы работают; mermaid отображается на GitHub.
- Нет секретов/паролей/чувствительных URL.

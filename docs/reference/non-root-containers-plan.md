---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'План перехода на non-root контейнеры (CKV_DOCKER_3)'
---

# План перехода на non-root контейнеры (CKV_DOCKER_3)

## Цели

- Выполнить рекомендацию Checkov CKV_DOCKER_3: запуск контейнеров не от root.
- Сформировать перечень сервисов, где переход возможен, и исключений.
- Подготовить uid/gid и обновить Compose/Dockerfile, не ломая права на volume.

## Текущее состояние

- В `compose.yml` задано `user: "0"` в глобальном секшене (эффективно root).
- Ряд образов уже работают под non-root (обычно официальные exporters).
- Локальные Dockerfile: `auth`, `conf/Dockerfile.rag-exporter`,
  `conf/webhook-receiver`, `ops/ollama-exporter` — требуют проверки.

## План действий

1.**Убрать глобальный `user: "0"`**в `compose.yml` и задать user на уровне
сервисов:

- Определить uid/gid для: `nginx`, `openwebui`, `ollama`, `litellm`, `docling`,
  `prometheus`, `grafana`, `loki`, `alertmanager`, `fluent-bit`, `watchtower`,
  `redis`, `postgres-exporter`, `node-exporter`, `cadvisor`,
  `blackbox-exporter`, `webhook-receiver`, `rag-exporter`, `mcposerver`, `auth`.
- Где образ уже имеет non-root (node-exporter, cadvisor, многие официальные),
  оставить дефолт.

  2.**Обновить Dockerfile для локальных образов**:

- `auth/Dockerfile`: добавить non-root user (`USER 1001:1001`), chmod для
  бинаря/артефактов.
- `conf/Dockerfile.rag-exporter`: добавить non-root user, обновить entrypoint
  права.
- `conf/webhook-receiver/Dockerfile`: добавить non-root user.
- `ops/ollama-exporter/Dockerfile`: добавить non-root user.

  3.**Volumes и права**:

- Прописать chown/chmod для томов, где нужны записи: `./data/*`, `./logs`,
  `./conf/*` (где монтируется).
- Проверить secrets/ssl: оставить root only или задать корректные маски.

  4.**Документация**:

- Обновить `docs/architecture/service-inventory.md` и
  `docs/de/architecture/service-inventory.md` с uid/gid/`user` примечаниями.
- Добавить раздел в `docs/reference/documentation-maintenance-strategy.md` о
  non-root политике.

  5.**Проверка/CI**:

- Добавить Checkov правило обратно (не disable CKV_DOCKER_3) после миграции.
- Запустить `docker compose config` и smoke-тест контейнеров под non-root.

## Приоритетные сервисы для миграции (предлагаемые uid/gid)

| Сервис           | Предложение user | Примечания                                    |
| ---------------- | ---------------- | --------------------------------------------- |
| nginx            | 101:101          | www-data; требуется права на `conf/nginx` SSL |
| openwebui        | 1000:1000        | node base; volume `./data/openwebui`          |
| litellm          | 1000:1000        | python/node mix; volume `./data/litellm`      |
| docling          | 1000:1000        | python; shared `./data/docling`               |
| ollama           | 1000:1000        | GPU; volume `./data/ollama`                   |
| mcposerver       | 1000:1000        | node; data dir `./data/mcpo-*`                |
| prometheus       | 65534:65534      | nobody; data dir `./data/prometheus`          |
| grafana          | 472:472          | grafana uid                                   |
| loki             | 10001:10001      | upstream uid                                  |
| alertmanager     | 65534:65534      | nobody                                        |
| fluent-bit       | 0:0 -> 1000:1000 | убедиться в доступе к log volume              |
| webhook-receiver | 1000:1000        | локальный Dockerfile                          |
| rag-exporter     | 1000:1000        | локальный Dockerfile                          |
| auth             | 1001:1001        | Go бинарь; локальный Dockerfile               |
| redis            | 999:999          | оф. uid                                       |
| searxng          | 1000:1000        | оф. образ, проверить uid                      |
| watchtower       | 1000:1000        | доступ к docker.sock                          |

## Исключения / TBD

- `postgres` (db) — остаётся под оф. UID (999), root не используется; already
  non-root.
- `node-exporter`, `cadvisor`, `blackbox-exporter` — upstream non-root,
  оставить.
- Если сервис требует root для init-скриптов (редко) — оставить как исключение,
  документировать.

## Дальнейшие шаги

- Создать PR с изменениями `compose.yml` (персональные user), обновлениями
  Dockerfile.
- Добавить CI проверку CKV_DOCKER_3 (enable) и smoke-тест под non-root.
- Обновить документацию (inventory + maintenance strategy).

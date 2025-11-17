# Alertmanager Silence Cleanup Plan

## Current silences (via `amtool silence query`)

| Silence ID                           | Matchers                                                        | Ends At (UTC)    | Comment                        |
| ------------------------------------ | --------------------------------------------------------------- | ---------------- | ------------------------------ |
| 1c0ccb58-8d0a-4beb-bd94-cdea3e7f77e1 | alertname="ServiceDown"                                         | 2025-11-17 09:15 | Logging stack restored         |
| 2600cbe5-74e4-4625-a8e3-14904fb9521e | alertname="LokiDown"                                            | 2025-11-17 09:15 | Logging stack restored         |
| a9064144-553f-47ba-a590-789037db503c | alertname="FluentBitContainerDown" OR alertname="ContainerDown" | 2025-11-17 09:15 | Logging stack restored         |
| 92a53749-1762-4d7a-b78b-f36b0bc1b052 | alertname="RedisCriticalMemoryFragmentation"                    | 2025-11-17 09:16 | Redis fragmentation suppressed |
| 96e54824-6622-41b3-af6e-26bc39bab564 | alertname="PrometheusTargetDown" etc.                           | 2025-11-17 09:16 | Cron/HTTPErrors suppressed     |
| 0befe00b-c7bd-4a1b-89fb-4bd79778849e | alertname="FluentBitContainerDown"                              | 2025-11-17 09:16 | Cron/HTTPErrors suppressed     |
| 5b1186d0-9430-41b3-b499-097112286d46 | alertname="ContainerDown"                                       | 2025-11-17 09:16 | Cron/HTTPErrors suppressed     |
| 08ca434f-dd4a-4d27-a9b8-ceb1d0d4e5c2 | alertname="PrometheusTargetDown"                                | 2025-11-17 09:16 | Cron/HTTPErrors suppressed     |
| 0deb49ec-7ce0-44ee-9177-afb64e01572c | alertname="CriticalServiceLogsMissing"                          | 2025-11-17 09:17 | Cron/HTTPErrors suppressed     |
| 506ba22b-9170-4aec-bc99-5cce95b90677 | alertname="SLAViolationCritical"                                | 2025-11-17 09:17 | Cron/HTTPErrors suppressed     |
| 6d355b9c-5ffa-4c3e-abab-65721d822616 | alertname="AlertmanagerClusterHealthLow"                        | 2025-11-17 09:17 | Cron/HTTPErrors suppressed     |
| c0d80893-0293-4b7f-8d98-7212d1d58823 | alertname="RedisHTTPErrors"                                     | 2025-11-17 09:17 | Cron/HTTPErrors suppressed     |
| 1ca3cbf3-42e9-4c92-bdc3-2524a489f62b | alertname="RedisNoRecentSave"                                   | 2025-11-17 09:17 | Cron/HTTPErrors suppressed     |

## Removal sequence

1. Подтвердить, что `alertmanager_cluster_messages_queued` < 100 минимум 60
   минут и нет новых алертов в `amtool alert query --active`.
2. Снять тишины из блоков "Logging stack restored":
   ```bash
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 1c0ccb58-8d0a-4beb-bd94-cdea3e7f77e1
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 2600cbe5-74e4-4625-a8e3-14904fb9521e
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire a9064144-553f-47ba-a590-789037db503c
   ```
3. Если стек стабилен, снять `RedisCriticalMemoryFragmentation`:
   ```bash
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 92a53749-1762-4d7a-b78b-f36b0bc1b052
   ```
4. Снять пакет cron/synthetic silences:
   ```bash
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 96e54824-6622-41b3-af6e-26bc39bab564
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 0befe00b-c7bd-4a1b-89fb-4bd79778849e
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 5b1186d0-9430-41b3-b499-097112286d46
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 08ca434f-dd4a-4d27-a9b8-ceb1d0d4e5c2
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 0deb49ec-7ce0-44ee-9177-afb64e01572c
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 506ba22b-9170-4aec-bc99-5cce95b90677
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 6d355b9c-5ffa-4c3e-abab-65721d822616
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire c0d80893-0293-4b7f-8d98-7212d1d58823
   docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire 1ca3cbf3-42e9-4c92-bdc3-2524a489f62b
   ```
5. После каждого блока проверять `amtool alert query --active` и
   `Grafana → Alertmanager Queue`.
6. Логировать действия в Ops-канале и обновлять Runbook/incident log.

## Automation notes

- Все фоновые silences должны включать тег `[auto-cleanup]` в комментарии.
- Добавить cron/systemd timer для
  `scripts/monitoring/alertmanager-queue-cleanup.sh` (см. Monitoring Guide).
- Для новых incident’ов придерживаться SLA: silences максимум на 2 часа.

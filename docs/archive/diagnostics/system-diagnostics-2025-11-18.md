# ERNI-KI System Diagnostics — 2025-11-18

## Исходные данные

- Health monitor: `logs/diagnostics/full-audit-20251118.md`
- Контейнеры: `docker compose ps` (снято 10:38 UTC)
- Логи: `docker compose logs --since 30m`

## Результаты проверок

### 1. Общий статус

- ✅ Критичные сервисы (OpenWebUI, LiteLLM, Ollama, Redis, PostgreSQL, Nginx)
  проходят HTTP/health проверки.
- ⚠️ `health-monitor` отмечает 24/30 healthy: шесть вспомогательных контейнеров
  (fluent-bit, nginx-exporter, nvidia-exporter, ollama-exporter,
  postgres-exporter-proxy, redis-exporter) не имеют Docker healthcheck и всегда
  считаются “unhealthy”.
- ❌ Лог-мониторинг: 17 632 записей уровня ERROR/FATAL/CRITICAL за 30 минут.

### 2. Ключевые проблемы

1. **LiteLLM auth flood** (`docker compose logs litellm --since 10m`): каждую
   минуту падает `ProxyException` из `user_api_key_auth`. Источник `172.18.0.1`
   (OpenWebUI или internal scheduler) опрашивает
   `/schedule/model_cost_map_reload/status` без токена → HTTP 400 и ERROR-логи.
   Требуется либо выдать валидный `X-API-KEY`, либо отключить cron/endpoint.
2. **Exporter health coverage**: перечисленные выше контейнеры не имеют
   `healthcheck`, но входят в список критических экспортёров. Рекомендуется
   добавить curl/wget проверки, иначе health monitor всегда WARN и Watchtower не
   сможет отследить сбои.
3. **Postgres exporter config warning**: при старте появляется
   `Error opening config file "postgres_exporter.yml"`. Сейчас используется
   только DSN, поэтому стоит передать `--config.file=/dev/null` или смонтировать
   пустой конфиг, чтобы убрать WARN.
4. **Логовый шум → Alert fatigue**: health-monitor FAIL обусловлен большим
   количеством ошибок от LiteLLM и предупреждений экспортера. Пока шум не
   устранён, проверка всегда возвращает non-zero и CI/cron воспримут это как
   инцидент.
5. **Диск 78% (346 ГБ из 468 ГБ)** — пока ниже порога 80%, но нужно
   контролировать рост `./data` и Docker volumes после обновлений моделей. План:
   автоматизировать `prune` или расширить storage alert c 75% WARN / 85% CRIT.
6. **Security best practices**:
   - `litellm` опубликован на `0.0.0.0:4000` без TLS/Ingress, только
     health-check и WebAuth. Рекомендуется ограничить доступ (localhost/nginx)
     или включить TLS из `exporter-toolkit`.
   - Watchtower-auto-update включён для Redis, LiteLLM и OpenWebUI. Для
     прод-стека best practice — автообновлять только по списку и всегда через
     staged rollout; стоит убедиться, что автообновление отключено на критичных
     компонентах (Prometheus, Nginx уже защищены).

### 3. Соответствие best practices

| Область        | Статус | Пояснения                                                                                                            |
| -------------- | ------ | -------------------------------------------------------------------------------------------------------------------- |
| Наблюдаемость  | ⚠️     | Экспортёры без healthcheck, шумящие логи, нет подавления известных WARN.                                             |
| Секреты        | ✅     | Основные сервисы читают секреты из Docker secrets/ENV wrappers.                                                      |
| Автообновления | ⚠️     | Watchtower включён для Redis/LiteLLM/OpenWebUI → риск незапланированных апгрейдов.                                   |
| Ресурсы        | ✅     | Критичные сервисы (OpenWebUI, Docling, LiteLLM) заданы mem/cpu limits; экспортеры используют дефолт (приемлемо).     |
| Сеть/TLS       | ⚠️     | LiteLLM открыт наружу plain HTTP; Cloudflare/Nginx прикрывают OpenWebUI, но сам LiteLLM остаётся доступным на хосте. |

### 4. Рекомендации

1. **Ввести healthcheck** для fluent-bit, nginx-exporter, nvidia-exporter,
   ollama-exporter, postgres-exporter-proxy, redis-exporter (простая `wget`/`nc`
   проверка). Это снимет системный WARN.
2. **Нормализовать LiteLLM cron**: либо изменить
   `/schedule/model_cost_map_reload/...` вызовы на авторизованные, либо
   отключить scheduler, если не используется. До исправления добавить log
   sampling, чтобы не перегружать Fluent Bit.
3. **Убрать postgres-exporter warning**: явный
   `--config.file=/app/config/postgres_exporter.yml` (пусть будет пустой) или
   `--config.file=/dev/null`.
4. **Настроить лог-политику health-monitor**: добавить фильтр “известных” ошибок
   (LiteLLM ProxyException) либо снизить окно анализа, чтобы FAIL означал
   реальные инциденты.
5. **Security hardening**: ограничить доступ к `4000/tcp` (Docker network only
   или через Nginx/TLS). Watchtower — оставить только monitor mode либо
   полностью отключить для прод-контейнеров.
6. **Storage план**: добавить cron `docker system prune` / очистку
   `./data/openwebui` от старых моделей, поднять алерт до 75% WARN/85% CRIT.

### 5. Следующие шаги

- Приоритизировать устранение LiteLLM auth ошибок и добавить healthcheck’и → это
  сразу сделает health-monitor зелёным.
- Оформить тикеты на ограничение доступа к LiteLLM и корректировку Watchtower
  политики.
- Повторить `scripts/health-monitor.sh` после исправлений и прикрепить свежий
  отчёт в Archon.

### 6. Выполненные правки (2025‑11‑18)

- LiteLLM порт открыт только на `127.0.0.1:4000`, а Watchtower переведён в
  monitor-only режим для OpenWebUI и LiteLLM (`compose.yml`). Это исключает
  незапланированные автоапдейты и внешний доступ к API.
- В health-monitor добавлены `HEALTH_MONITOR_LOG_WINDOW` (по умолчанию 5m) и
  `HEALTH_MONITOR_LOG_IGNORE_REGEX` с пресетом для LiteLLM cron, node-exporter
  broken pipe, cloudflared context canceled и redis-exporter Errorstats
  (`scripts/health-monitor.sh`).
- Postgres exporter получает stub-конфиг `conf/postgres-exporter/config.yml` и
  запускается с `--config.file` + `--no-collector.stat_bgwriter`, поэтому
  предупреждение о файле исчезло.
- Alertmanager шаблоны заменили `| default` на `if/else`, что устранило ошибку
  `function "default" not defined` при отправке Slack уведомлений
  (`conf/alertmanager/alertmanager.yml`).
- Свежий отчёт (после hardening): `logs/diagnostics/hardening-20251118.md`.
- Для fluent-bit, nginx-exporter, nvidia-exporter, ollama-exporter,
  postgres-exporter-proxy и redis-exporter добавлены Docker healthcheck’и;
  теперь `docker compose ps` и `scripts/health-monitor.sh` показывают 31/31
  healthy контейнеров.

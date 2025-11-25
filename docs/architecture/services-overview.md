--- language: ru translation_status: complete doc_version: '2025.11'
last_updated: '2025-11-24' --- # Детальная таблица активных сервисов системы
ERNI-KI > **Справочная документация для администрирования системы ERNI-KI**
**Дата > обновления**: 2025-10-24 **Версия системы**: Production Ready v12.1 >
**Статус**: Все 30 сервисов работают (30/30 Healthy) • 27 Prometheus alerts > •
Автоматизированное обслуживание --- ## Application Layer (AI & Core Services) |
Сервис | Статус | Порты | Конфигурация | Переменные окружения | Тип конфигурации
| Примечания | | ----------------- | ---------- | ----------------- |
----------------------------- | -------------------- | ---------------- |
------------------------------------------------------------------------------------
| | ** ollama** | Healthy | `11434:11434` | Нет | `env/ollama.env` | ENV | **
КРИТИЧЕСКИЙ** • Ollama 0.12.11 • GPU: 4GB VRAM limit • Автообновление отключено
| | ** openwebui** | Healthy | `8080` (internal) | `conf/openwebui/*.json` |
`env/openwebui.env` | JSON | ** КРИТИЧЕСКИЙ** • OpenWebUI v0.6.36 • GPU: NVIDIA
runtime • MCP интеграция | | ** litellm** | Healthy | `4000:4000` |
`conf/litellm/config.yaml` | `env/litellm.env` | YAML | LiteLLM v1.80.0.rc.1 •
Context Engineering • Memory: 12GB limit • Thinking tokens | | ** searxng** |
Healthy | `8080` (internal) | `conf/searxng/*.yml` | `env/searxng.env` |
YAML/TOML/INI | RAG поиск • 6+ источников (Brave, Startpage, Bing, Wikipedia) •
Redis кэширование | | ** mcposerver** | Healthy | `8000:8000` |
`conf/mcposerver/config.json` | `env/mcposerver.env` | JSON | Model Context
Protocol • 4 инструмента (Time, PostgreSQL, Filesystem, Memory) | ## Processing
Layer (Document & Media Processing) | Сервис | Статус | Порты | Конфигурация |
Переменные окружения | Тип конфигурации | Примечания | | -------------- |
---------- | ----------- | ------------ | -------------------- |
---------------- | -------------------------------------------------------- | |
** tika** | Healthy | `9998:9998` | Нет | `env/tika.env` | ENV | Apache Tika
latest-full • Извлечение текста и метаданных | | ** edgetts** | Healthy |
`5050:5050` | Нет | `env/edgetts.env` | ENV | EdgeTTS • Синтез речи • OpenAI
Edge TTS | ## Data Layer (Databases & Cache) | Сервис | Статус | Порты |
Конфигурация | Переменные окружения | Тип конфигурации | Примечания | |
------------ | ---------- | ----------------- | ----------------------- |
-------------------- | ---------------- |
----------------------------------------------------------------------------------------------------------
| | ** db** | Healthy | `5432` (internal) | Нет | `env/db.env` | ENV | **
КРИТИЧЕСКИЙ** • PostgreSQL 17 + pgvector • Shared DB (OpenWebUI + LiteLLM) •
Автообновление отключено | | ** redis** | Healthy | `6379` (internal) |
`conf/redis/redis.conf` | `env/redis.env` | CONF | Redis 7-alpine • WebSocket
manager • Active defragmentation • Кэш и очереди | ## Gateway Layer (Proxy &
Auth) | Сервис | Статус | Порты | Конфигурация | Переменные окружения | Тип
конфигурации | Примечания | | ------------------ | ------------------- |
--------------------------- | ---------------------------- |
--------------------- | ---------------- |
------------------------------------------------------------------------------ |
| ** nginx** | Up 2h (healthy) | `80:80, 443:443, 8080:8080` |
`conf/nginx/*.conf` | Нет | CONF | ** КРИТИЧЕСКИЙ** • Reverse Proxy • SSL
терминация • Автообновление отключено | | ** auth** | Up 24h (healthy) |
`9092:9090` | Нет | `env/auth.env` | ENV | JWT аутентификация • Go сервис | | **
cloudflared** | Up 5h | Нет портов | `conf/cloudflare/config.yml` |
`env/cloudflared.env` | YAML | ** Healthcheck отключен** • Cloudflare Tunnel
| ## Monitoring Layer (Metrics & Observability) | Сервис | Статус | Порты |
Конфигурация | Переменные окружения | Тип конфигурации | Примечания | |
----------------------- | ------------------- |
------------------------------------ | ---------------------------- |
---------------------- | ---------------- |
----------------------------------------------- | | ** prometheus** | Up 1h
(healthy) | `9091:9090` | `conf/prometheus/*.yml` | `env/prometheus.env` | YAML
| Сбор метрик • 35 targets | | ** grafana** | Up 37m (healthy) | `3000:3000` |
`conf/grafana/**/*.yml` | `env/grafana.env` | YAML/JSON | Дашборды •
Визуализация | | ** alertmanager** | Up 24h (healthy) | `9093-9094:9093-9094` |
Нет | `env/alertmanager.env` | ENV | Управление алертами | | ** loki** | Up 22h
(healthy) | `3100:3100` (`X-Scope-OrgID` header) | `conf/loki/loki-config.yaml`
| Нет | YAML | Централизованное логирование | | ** fluent-bit** | Up 4m |
`2020:2020, 24224:24224` | `conf/fluent-bit/*.conf` | `env/fluent-bit.env` |
CONF | ** Healthcheck отключен** • Сбор логов → Loki | | ** webhook-receiver** |
Up 24h (healthy) | `9095:9093` | Нет | Нет | ENV | Обработка алертов | ##
Exporters (Metrics Collection) | Сервис | Статус | Порты | Конфигурация |
Переменные окружения | Тип конфигурации | Примечания | |
------------------------------------- | ------------------- | ----------- |
------------------------------ | --------------------------- | ----------------
| ------------------------------------------- | | ** node-exporter** | Up 24h
(healthy) | `9101:9100` | Нет | `env/node-exporter.env` | ENV | Системные
метрики | | ** cadvisor** | Up 24h (healthy) | `8081:8080` | Нет |
`env/cadvisor.env` | ENV | Docker контейнеры | | ** blackbox-exporter** | Up 23h
(healthy) | `9115:9115` | Нет | `env/blackbox-exporter.env` | ENV | Проверка
доступности | | ** nvidia-exporter** | Up 24h (healthy) | `9445:9445` | Нет |
`env/nvidia-exporter.env` | ENV | ** GPU метрики** • NVIDIA runtime | | **
ollama-exporter** | Up 24h (healthy) | `9778:9778` | Нет | Нет | ENV | AI модели
метрики | | ** postgres-exporter** | Up 24h (healthy) | `9187:9187` |
`conf/postgres-exporter/*.yml` | `env/postgres-exporter.env` | YAML | PostgreSQL
метрики | | ** Redis мониторинг через Grafana** | Up 24h | `9121:9121` | Нет |
Нет | ENV | ** Healthcheck отключен** • Redis метрики | | ** nginx-exporter** |
Up 24h | `9113:9113` | Нет | Нет | ENV | Nginx метрики | ## Infrastructure Layer
(Backup & Management) | Сервис | Статус | Порты | Конфигурация | Переменные
окружения | Тип конфигурации | Примечания | | ----------------- |
------------------- | ----------- | ----------------------- |
-------------------- | ---------------- |
----------------------------------------------- | | ** backrest** | Up 24h
(healthy) | `9898:9898` | `conf/backrest/*.json` | `env/backrest.env` | JSON |
Резервное копирование • 7-дневные + 4-недельные | | ** watchtower** | Up 24h
(healthy) | `8091:8080` | `conf/watchtower/*.env` | `env/watchtower.env` | ENV |
Автообновление контейнеров • HTTP API | --- ## Сводная статистика | Категория |
Количество | Статус | | ------------------------------- | ---------- |
-------------------------------------------------------------------------- | |
**Всего сервисов** | **29** | 100% работают | | **Healthy сервисы** | **25** |
86% с healthcheck | | **Сервисы без healthcheck** | **4** | cloudflared,
fluent-bit, Redis мониторинг через Grafana, nginx-exporter | | **GPU зависимые**
| **3** | ollama, openwebui, nvidia-exporter | | **Критически важные** | **3** |
ollama, openwebui, db, nginx | | **С конфигурационными файлами** | **12** | 41%
имеют conf/ | | **Только переменные окружения** | **17** | 59% используют только
env/ | ## Типы конфигураций - **YAML/YML**: 8 сервисов (prometheus, grafana,
loki, litellm, searxng, cloudflared, postgres-exporter) - **CONF**: 2 сервиса
(nginx, fluent-bit) - **JSON**: 3 сервиса (backrest, mcposerver, openwebui) -
**ENV только**: 16 сервисов (остальные) ## Важные примечания 1. ** Критически
важные сервисы** имеют отключенное автообновление для стабильности 2. ** GPU
сервисы** требуют NVIDIA Container Toolkit 3. ** Сервисы без healthcheck**
мониторятся через внешние метрики 4. ** Конфигурации** защищены от
автоформатирования IDE 5. ** Автообновления** настроены по scope группам для
безопасности ## Быстрые команды для администрирования ### Проверка статуса всех
сервисов
`bash docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" ` ###
Проверка логов критически важных сервисов
`bash # Ollama docker-compose logs ollama --tail=50 # OpenWebUI docker-compose logs openwebui --tail=50 # PostgreSQL docker-compose logs db --tail=50 # Nginx docker-compose logs nginx --tail=50 ` ##
Мониторинг ресурсов GPU
`bash # Проверка GPU статуса nvidia-smi # Метрики GPU через Prometheus curl -s http://localhost:9445/metrics | grep nvidia ` ##
Проверка интеграций
`bash # Fluent Bit метрики curl -s http://localhost:2020/api/v1/metrics # Prometheus targets curl -s http://localhost:9091/api/v1/targets # Loki health curl -s -H "X-Scope-OrgID: erni-ki" http://localhost:3100/ready ` ##
Связанная документация - **[Архитектура системы](architecture.md)** - Диаграммы
и описание компонентов -
**[Руководство администратора](../operations/core/admin-guide.md)** - Детальные
инструкции по управлению -
**[Мониторинг и алерты](../operations/monitoring/monitoring-guide.md)** -
Настройка Prometheus/Grafana -
**[Резервное копирование](../operations/backup-guide.md)** - Конфигурация
Backrest -
**[Устранение неполадок](../operations/troubleshooting/troubleshooting-guide.md)** -
Решение типовых проблем --- **Последнее обновление**: 2025-08-22 **Система**:
Production Ready **Статус**: Все сервисы работают

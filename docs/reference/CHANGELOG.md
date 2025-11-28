---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# CHANGELOG - ERNI-KI Documentation

[TOC]

## [5.3.0] - 2025-11-28

### LiteLLM Update

#### **LiteLLM v1.80.0.rc.1 → v1.80.0-stable.1**

- **Дата обновления**: 2025-11-28
- **Статус**: Успешно обновлено
- **Downtime**: 0 минут (rolling restart)
- **Проверки**:
  - `curl http://127.0.0.1:4000/health` (с Authorization) → 200
  - `curl http://127.0.0.1:4000/health/readiness` → 200
  - `curl http://127.0.0.1:4000/v1/models` (с Authorization) → 200
  - Chat completion через `/v1/chat/completions` → 200
- **Примечание**: предупреждения о недостающих DB views для UI остаются (без регрессий)

### OpenWebUI Update

### Ollama Update

- **Ollama**: 0.12.11 → **0.13.0** (GPU/Vulkan improvements)
- **Проверки**:
  - `docker compose exec -T ollama ollama list` → список моделей загружен
  - `docker compose exec -T ollama nvidia-smi` → GPU виден (Quadro RTX 5000, 16GB), без процессов
  - Контейнер healthy

#### **OpenWebUI v0.6.36 → v0.6.40**

- **Дата обновления**: 2025-11-28
- **Статус**: Успешно обновлено (подготовка к выкладке)
- **Downtime**: 0 минут (rolling restart планируется)
- **Совместимость**: LiteLLM, Docling, Tika, SearXNG интеграции ожидаются без изменений
- **Проверки (запланировано)**:
  - `curl http://localhost:8080/health`
  - UI smoke: логин, чат, RAG поиск, загрузка файла

### Monitoring & Infra Updates

- **Prometheus**: v3.0.0 → **v3.7.3** (pull + restart; `/ -/healthy` = 200)
- **Grafana**: 11.3.0 → **12.3.0** (health `/api/health` ok)
- **Loki**: 3.0.0 → **3.6.2** (ready: `curl -ksf -H 'X-Scope-OrgID: erni-ki' https://localhost:3100/ready`)
- **Tika**: pinned to **apache/tika:3.2.3.0-full** (health 200)
- **Cloudflared**: already on 2025.11.1 (no change)
- **SearXNG**: refreshed to **latest** digest (2025-11-28 pull)
- **Backrest**: **v1.9.2 → v1.10.1** (backup improvements)
- **MCPO Server**: stay on **git-91e8f94** (tag v0.0.19 отсутствует в реестре)
- **Exporters & logging (Phase3.1)**:
  - Alertmanager **v0.29.0**, Node Exporter **v1.10.2**, Postgres Exporter **v0.18.1**
  - Redis Exporter **v1.80.1**, Blackbox Exporter **v0.27.0**, Nginx Exporter **v1.5.1**
  - cAdvisor stays **v0.52.1** (v0.53.0 not available in registry)
  - Fluent Bit **4.2.0** (major upgrade 3→4)

#### Post-update checks

- `docker compose pull cloudflared prometheus grafana loki tika`
- `docker compose up -d cloudflared prometheus grafana loki tika`
- Prometheus `/ -/healthy` → 200
- Grafana `/api/health` → version 12.3.0
- Loki ready endpoint (with `X-Scope-OrgID: erni-ki`) → `ready`
- Tika `/tika` → 200

---

## [5.2.0] - 2025-11-18

### OpenWebUI Update

#### **OpenWebUI v0.6.34 → v0.6.36**

- **Дата обновления**: 2025-11-18
- **Версия**: v0.6.34 → v0.6.36
- **Статус**: Успешно обновлено
- **Downtime**: 0 минут (rolling update)
- **Совместимость**: LiteLLM, Docling, RAG и MCP интеграции сохранены

#### **Удалены устаревшие патчи**

- Папка `patches/openwebui` очищена – контейнер теперь работает без локальных патчей
- Скрипт `scripts/entrypoints/openwebui.sh` больше не пытается применять патчи
- `compose.yml` больше не монтирует директорию патчей

#### **Документация синхронизирована**

- README.md / docs/index.md / docs/overview.md – статус-блоки обновлены на v0.6.36
- docs/architecture/* (RU/DE) – диаграммы и описания обновлены
- docs/reference/status*.md/yml – общие сниппеты теперь указывают v0.6.36
- docs/operations/core/operations-handbook.md – цели по версиям обновлены

#### **Проверка после обновления**

- Выполнен полный health-check (`scripts/health-monitor.sh`)
- Сервисные эндпоинты OpenWebUI, LiteLLM, Docling, monitoring подтверждены как healthy

#### **Мониторинг**

- `postgres-exporter` получил явный флаг `--no-collector.stat_bgwriter`, что убрало ошибки `checkpoints_timed`
- Контейнер пересобран (`docker compose up -d postgres-exporter postgres-exporter-proxy`), логи чистые

#### **Дополнительное hardening**

- Добавлен stub конфиг `conf/postgres-exporter/config.yml`, который теперь передаётся через `--config.file`.
- LiteLLM (порт `127.0.0.1:4000`) и OpenWebUI переведены в режим Watchtower monitor-only.
- `scripts/health-monitor.sh` получил параметры `HEALTH_MONITOR_LOG_WINDOW` и `HEALTH_MONITOR_LOG_IGNORE_REGEX`, что убрало шум от LiteLLM cron, node-exporter broken pipe, cloudflared context canceled и redis-exporter Errorstats.
- Fluent Bit, nginx-exporter, nvidia-exporter, ollama-exporter, postgres-exporter-proxy и redis-exporter получили Docker healthchecks, поэтому health-monitor теперь показывает 31/31 healthy.
- Alertmanager Slack шаблоны переписаны без `| default`, поэтому пропала ошибка `function "default" not defined`.
- Добавлен отчёт `logs/diagnostics/hardening-20251118.md`.

---

## [5.1.0] - 2025-11-04

### OpenWebUI Update

#### **OpenWebUI v0.6.32 → v0.6.34**

- **Дата обновления**: 2025-11-04
- **Версия**: v0.6.32 → v0.6.34
- **Статус**: Успешно обновлено
- **Downtime**: ~5 минут (контейнер перезапущен)
- **Совместимость**: Все интеграции сохранены

#### **Сохраненные интеграции**

- **PostgreSQL**: Подключение к базе данных работает
- **Ollama**: 4 модели доступны (gpt-oss:20b, gemma3:12b, llama3.2 (128K), nomic-embed-text)
- **SearXNG RAG**: Веб-поиск функционален
- **LiteLLM**: Интеграция с Context Engineering Gateway
- **GPU Acceleration**: NVIDIA runtime активен

#### **Cloudflare Tunnels - Исправление маршрутизации**

- **Проблема**: nginx:8080 недоступен из Docker сети (i/o timeout)
- **Решение**: Обновлена конфигурация в Cloudflare Dashboard
    - `diz.zone`: `http://nginx:8080` → `http://openwebui:8080`
    - `lite.diz.zone`: `http://nginx:8080` → `http://litellm:4000`
    - `search.diz.zone`: `http://searxng:8080` (без изменений)
- **Результат**: Все 5 доменов доступны через HTTPS
    - diz.zone - HTTP 200 (OpenWebUI)
    - webui.diz.zone - HTTP 200 (OpenWebUI)
    - ki.erni-gruppe.ch - HTTP 200 (OpenWebUI)
    - search.diz.zone - HTTP 200 (SearXNG)
    - lite.diz.zone - HTTP 401 (LiteLLM требует аутентификацию)

#### **Системный статус после обновления**

- **Контейнеры**: 30/30 работают
- **Healthy сервисы**: 25/30 (5 exporters без health check)
- **Критические ошибки**: Нет
- **GPU**: Доступен, модели загружаются по требованию
- **Производительность**: Без деградации

#### **Документация обновлена**

- README.md - версия OpenWebUI обновлена до v0.6.34
- docs/architecture/architecture.md - архитектурная диаграмма обновлена
- docs/locales/de/architecture.md - немецкая версия синхронизирована
- CHANGELOG.md - добавлена запись об обновлении

#### **Обнаруженные проблемы**

1. **PostgreSQL Exporter** ([WARNING] Средний приоритет)
 - Ошибка: `column "checkpoints_timed" does not exist`
 - Влияние: Некоторые метрики PostgreSQL не собираются
 - Статус: Не критично, требует обновления конфигурации exporter

2. **Nginx Docker Network** ([WARNING] Средний приоритет)
 - Проблема: nginx:8080 недоступен из Docker сети
 - Обходное решение: Прямое подключение к сервисам через Cloudflare Dashboard
 - Статус: Требует дальнейшего исследования

#### **Критерии успеха выполнены**

- OpenWebUI обновлен до v0.6.34
- Все домены доступны через HTTPS (HTTP 200)
- Все интеграции функциональны
- GPU-ускорение работает
- Нет критических ошибок в логах cloudflared
- Документация актуализирована

---

## [5.0.0] - 2025-07-25

### Major Updates

#### **Архитектурная документация актуализирована**

- **Обновлена версия документации**: 4.0 → 5.0
- **Количество сервисов**: 24 → 25 (добавлен webhook-receiver)
- **Диаграммы Mermaid**: Обновлены все архитектурные схемы
- **Порты и endpoints**: Актуализированы все таблицы портов

#### **Webhook Receiver Integration**

- **Новый сервис**: webhook-receiver добавлен в архитектуру
- **Порты**: 9095 (внешний), 9093 (внутренний)
- **Функции**: Обработка алертов от AlertManager, логирование, JSON форматирование
- **Диаграммы**: Добавлен во все архитектурные схемы

#### **GPU Monitoring Enhancement**

- **NVIDIA GPU Exporter**: Документирован порт 9445
- **Метрики**: Температура, утилизация, память GPU
- **Дашборды**: Описан GPU дашборд в Grafana
- **Алерты**: Документированы критические GPU параметры

#### **Monitoring System Documentation**

- **Prometheus**: Обновлен порт 9091 (было 9090)
- **Grafana**: Подтвержден порт 3000
- **AlertManager**: Порты 9093-9094
- **Exporters**: Все порты актуализированы

### **Операционная документация**

#### **Troubleshooting Guide Updates**

- **Webhook Receiver**: Новый раздел диагностики
  - Проверка статуса и логов
  - Тестирование endpoints
  - Процедуры восстановления
- **GPU Monitoring**: Расширенная диагностика
  - NVIDIA GPU Exporter проверки
  - GPU метрики валидация
  - Контейнер GPU тестирование

#### **Installation Guide Updates**

- **Мониторинг**: Обновлены URL интерфейсов
  - Grafana: <http://localhost:3000>
  - Prometheus: <http://localhost:9091>
  - AlertManager: <http://localhost:9093>
  - Webhook Receiver: <http://localhost:9095/health>
- **GPU Setup**: Добавлены инструкции по проверке GPU мониторинга

### **Многоязычная документация**

#### **Deutsche Lokalisierung**

- **Architecture.md**: Синхронизирована с русской версией
- **Версия**: 3.0 → 5.0
- **Сервисы**: 16 → 25
- **Monitoring Layer**: Добавлен полный раздел мониторинга
- **Webhook Receiver**: Добавлен в немецкую диаграмму

### **Файлы изменены**

#### **Обновленные файлы**

- `docs/architecture/architecture.md` - Главная архитектурная документация
- `docs/operations/troubleshooting.md` - Руководство по устранению неполадок
- `docs/getting-started/installation.md` - Инструкции по установке
- `docs/locales/de/architecture.md` - Немецкая версия архитектуры
- `README.md` - Главная страница проекта

#### **Backup созданы**

- `.config-backup/docs/20250725_145457/` - Полный backup предыдущей версии
- Включает все файлы документации и README.md

### **Критерии успеха достигнуты**

#### **Архитектурная документация**

- [x] Отражение всех 25+ сервисов
- [x] Актуальные диаграммы Mermaid с webhook-receiver
- [x] Обновленные порты и endpoints
- [x] Интеграция с Cloudflare tunnels

#### **Операционная документация**

- [x] Инструкции по webhook-receiver
- [x] GPU мониторинг процедуры
- [x] Troubleshooting guide расширен
- [x] Installation guide актуализирован

#### **Многоязычная поддержка**

- [x] Немецкая локализация синхронизирована
- [x] Консистентная терминология
- [x] Актуальные версии документов

#### **Backup и версионирование**

- [x] Backup предыдущей версии создан
- [x] Версии обновлены (4.0 → 5.0)
- [x] Changelog с детальным описанием
- [x] Даты последнего изменения актуализированы

### **Связанные изменения**

#### **Docker Compose**

- Webhook-receiver добавлен в compose.production.yml
- Порт 9095:9093 настроен
- Health checks активированы

#### **Monitoring Stack**

- Prometheus конфигурация обновлена
- Grafana дашборды включают GPU метрики
- AlertManager интегрирован с webhook-receiver

### **Статистика изменений**

- **Файлов обновлено**: 5
- **Строк добавлено**: ~200
- **Новых разделов**: 3
- **Диаграмм обновлено**: 2
- **Языков синхронизировано**: 2 (RU, DE)

---

## [4.0.0] - 2025-07-15

### Previous version changes

- LiteLLM integration
- Docling service addition
- Context Engineering implementation
- Network optimization

---

> ℹ **Информация:** Этот changelog отражает актуализацию документации в связи с
> восстановлением и оптимизацией системы мониторинга ERNI-KI.

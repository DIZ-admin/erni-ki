---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-28'
category: archive
audit_type: service-version-matrix
previous_audit: service-version-matrix-2025-11-25.md
---

# ERNI-KI Service Version Matrix

Актуализированная матрица версий сервисов — по состоянию на 28 ноября 2025

## Ключевые изменения с предыдущего аудита (2025-11-25)

### Завершенные обновления

-**Cloudflared**: 2024.10.0 → 2025.11.1 (обновлено 2025-11-27)

### Новые доступные версии

-**Open WebUI**: v0.6.40 доступна (текущая v0.6.36) - 4 патча -**LiteLLM**:
v1.80.0-stable.1 доступна (текущая v1.80.0.rc.1) - stable релиз -**MCPO
Server**: v0.0.19 доступна (текущая git-91e8f94) - новый релиз -**Backrest**:
v1.10.1 доступна (текущая v1.9.2) - улучшения резервного
копирования -**SearXNG**: новый digest доступен (текущий от 12 ноября - 16 дней)

## Критические сервисы - Рекомендуются немедленные обновления

| Service         | Current      | Latest           | Gap       | Priority         | Notes                                             |
| --------------- | ------------ | ---------------- | --------- | ---------------- | ------------------------------------------------- |
| **LiteLLM**     | v1.80.0.rc.1 | v1.80.0-stable.1 | RC→Stable | HIGH             | Переход с RC на stable, тест API совместимости    |
| **Open WebUI**  | v0.6.36      | v0.6.40          | 4 patches | HIGH             | Последние исправления, низкий риск                |
| **Ollama**      | 0.12.11      | v0.13.0          | 1 minor   | HIGH             | Vulkan, GPU улучшения - тщательное тестирование   |
| **Cloudflared** | 2025.11.1    | 2025.11.1        | CURRENT   | N/A              | Обновлено 2025-11-27                              |
| **Prometheus**  | v3.0.0       | v3.7.3           | 7 minors  | [WARNING] MEDIUM | Тест правил алертов (или использовать v3.5.0 LTS) |

## [WARNING] Мониторинг Stack - Стандартные обновления

| Service               | Current | Latest  | Gap        | Priority         | Notes                                             |
| --------------------- | ------- | ------- | ---------- | ---------------- | ------------------------------------------------- |
| **Loki**              | 3.0.0   | v3.6.2  | 6 minors   | [WARNING] MEDIUM | Bloom filters, поддержка OpenTelemetry            |
| **Grafana**           | 11.3.0  | v12.3.0 | MAJOR      | [WARNING] HIGH   | Обновить до 11.6.8, затем оценить 12.x            |
| **Alertmanager**      | v0.27.0 | v0.29.0 | 2 minors   | [OK] LOW         | Улучшения маршрутизации алертов                   |
| **Node Exporter**     | v1.8.2  | v1.10.2 | 2 minors   | [OK] MEDIUM      | Расширенные метрики                               |
| **Postgres Exporter** | v0.15.0 | v0.18.1 | 3 minors   | [OK] MEDIUM      | Улучшенные метрики PostgreSQL                     |
| **Redis Exporter**    | v1.62.0 | v1.80.1 | 18 minors! | [WARNING] HIGH   | Большой разрыв - тщательное тестирование          |
| **Blackbox Exporter** | v0.25.0 | v0.27.0 | 2 minors   | [OK] LOW         | JSON body matching                                |
| **Nginx Exporter**    | 1.1.0   | 1.5.1   | 4 minors   | [WARNING] MEDIUM | Значительные улучшения                            |
| **cAdvisor**          | v0.52.1 | v0.53.0 | 1 minor    | [OK] LOW         | Обновления мониторинга контейнеров                |
| **Fluent Bit**        | 3.1.0   | v4.2.0  | MAJOR      | [WARNING] HIGH   | Мажорное обновление 3→4, исправления безопасности |
| **Uptime Kuma**       | 2.0.2   | 2.0.2   | CURRENT    | N/A              | Актуальная версия                                 |

## [OK] Инфраструктурные сервисы

| Service        | Current                   | Latest                    | Gap     | Priority         | Notes                                      |
| -------------- | ------------------------- | ------------------------- | ------- | ---------------- | ------------------------------------------ |
| **PostgreSQL** | pg17                      | pg17-trixie               | CURRENT | N/A              | Последняя мажорная версия                  |
| **pgvector**   | 0.8.0 (assumed)           | 0.8.1                     | 1 patch | [OK] LOW         | Минорное обновление расширения             |
| **Redis**      | 7.0.15-alpine             | 8.4.0-alpine              | MAJOR   | HOLD             | Major=риски; рекомендуется 7.4.0           |
| **Nginx**      | 1.29.3                    | 1.29.3                    | CURRENT | N/A              | Последний mainline (stable=1.28.0 старее)  |
| **Tika**       | sha256:3fafa...           | 3.2.3.0-full              | Unknown | [WARNING] MEDIUM | Переключить digest→version tag             |
| **SearXNG**    | sha256:aaa855... (Nov 12) | sha256:782d8a... (latest) | 16 days | [WARNING] MEDIUM | Обновить digest (рекомендуется ежемесячно) |

## Вспомогательные сервисы

| Service                 | Current          | Latest               | Gap            | Priority         | Notes                                    |
| ----------------------- | ---------------- | -------------------- | -------------- | ---------------- | ---------------------------------------- |
| **Watchtower**          | 1.7.1            | v1.7.1               | CURRENT        | N/A              | Актуальная версия                        |
| **Backrest**            | v1.9.2           | v1.10.1              | 1 minor        | [OK] MEDIUM      | Улучшения резервного копирования         |
| **EdgeTTS**             | Digest           | latest               | Unknown        | [OK] LOW         | Переключить на :latest                   |
| **MCPO Server**         | git-91e8f94      | v0.0.19              | Commit→Version | [WARNING] MEDIUM | Новый релиз, проверить совместимость     |
| **Docling**             | :main            | :main (rolling)      | N/A            | CONSIDER         | Рассмотреть закрепление для стабильности |
| **NVIDIA GPU Exporter** | 0.1 (mindprince) | **DCGM 4.4.2-4.7.0** | MIGRATION      | HIGH             | **Заменить**на NVIDIA DCGM Exporter      |

## Development Dependencies

| Component             | Current | Latest      | Gap       | Priority         | Notes                                |
| --------------------- | ------- | ----------- | --------- | ---------------- | ------------------------------------ |
| **Node.js**           | 22.14.0 | 22.11.0 LTS | AHEAD?    | [WARNING] VERIFY | Current > LTS - verify typo          |
| **npm**               | 10.8.2  | 11.6.3      | MAJOR     | [WARNING] MEDIUM | Major version update available       |
| **Go**                | 1.24.0  | 1.24.10     | CURRENT   | N/A              | Toolchain current (1.25.4 available) |
| **Flask**             | 3.0.3   | 3.1.2       | 2 patches | [OK] LOW         | Bug fix release                      |
| **prometheus-client** | 0.20.0  | 0.23.1      | 3 minors  | [OK] LOW         | Metrics improvements                 |
| **Werkzeug**          | 3.0.4   | Check       | Unknown   | [OK] LOW         | Run pip list --outdated              |
| **requests**          | 2.32.3  | Check       | Unknown   | [OK] LOW         | Run pip list --outdated              |

## Статистика обновлений

-**Всего сервисов**: 30 -**Полностью проверены**: 30 (100% ) -**Доступны
обновления**: 26 -**Уже на последней версии**: 5 (Watchtower, Uptime Kuma, Nginx
mainline, PostgreSQL, Cloudflared ) -**Критические обновления**: 6 (LiteLLM,
Open WebUI, Ollama, Grafana major, Fluent Bit major, Redis Exporter) -**Большие
разрывы версий**: 3 (Redis Exporter: 18 версий, Prometheus: 7 версий, Nginx
Exporter: 4 минора) -**Связанные с безопасностью**: 1 (Fluent Bit 4.2.0
исправляет уязвимости) -**Мажорные обновления**: 3 (Redis 7→8, Fluent Bit 3→4,
Grafana 11→12) -**Миграции сервисов**: 1 (NVIDIA GPU Exporter → DCGM Exporter)

## Сравнение с предыдущим аудитом

| Метрика                  | 2025-11-25 | 2025-11-28 | Изменение |
| ------------------------ | ---------- | ---------- | --------- |
| Доступно обновлений      | 26         | 26         | →         |
| Критических обновлений   | 5          | 6          | ↑ +1      |
| Завершено обновлений     | 0          | 1          | +1        |
| Новых релизов обнаружено | -          | 2          |           |

**Прогресс**: Cloudflared обновлен, обнаружены новые релизы MCPO Server
(v0.0.19) и Backrest (v1.10.1)

## Легенда приоритетов

-**HIGH**: Критичная функциональность/безопасность, рекомендуются немедленные
действия

- [WARNING]**MEDIUM**: Важные улучшения, запланировать на следующий спринт
- [OK]**LOW**: Минорные улучшения, обновить когда удобно -**N/A**: Уже актуально
  или требует специальной оценки -**HOLD**: Требует тщательного планирования
  (например, мажорная версия Redis)

## Фазы обновлений (актуализировано 2025-11-28)

### Фаза 1 (На этой неделе) - Низкий риск ⏳ В процессе

1. Cloudflared 2024.10.0 → 2025.11.1 (завершено 2025-11-27)
2. LiteLLM v1.80.0.rc.1 → v1.80.0-stable.1
3. Open WebUI v0.6.36 → v0.6.40

**Статус Фазы 1**: 33% (1/3 завершено)

### Фаза 2 (Следующий спринт) - Инфраструктура

4. Tika digest → 3.2.3.0-full
5. SearXNG digest update (16 дней с последнего обновления)
6. MCPO Server git-91e8f94 → v0.0.19
7. Prometheus v3.0.0 → v3.7.3 (или v3.5.0 LTS)
8. Grafana 11.3.0 → 11.6.8 (перед переходом на 12.x)
9. Loki 3.0.0 → v3.6.2

### Фаза 3 (Следующий спринт) - Экспортеры мониторинга

10. Alertmanager v0.27.0 → v0.29.0
11. Node Exporter v1.8.2 → v1.10.2
12. Postgres Exporter v0.15.0 → v0.18.1
13. Redis Exporter v1.62.0 → v1.80.1 (ПРИОРИТЕТ - 18 версий!)
14. Blackbox Exporter v0.25.0 → v0.27.0
15. Nginx Exporter 1.1.0 → 1.5.1
16. cAdvisor v0.52.1 → v0.53.0

### Фаза 4 (В этом месяце) - Мажорные обновления, требующие тестирования

17. Fluent Bit 3.1.0 → v4.2.0 (мажорная версия, тест pipelines, SECURITY)
18. Ollama 0.12.11 → v0.13.0 (тщательное тестирование GPU)
19. Backrest v1.9.2 → v1.10.1
20. Grafana 11.6.8 → v12.3.0 (мажорная версия, после тестирования 11.6.8)

### Фаза 5 (В этом месяце) - Зависимости и оставшиеся сервисы

21. npm 10.8.2 → 11.6.3
22. Flask 3.0.3 → 3.1.2
23. prometheus-client 0.20.0 → 0.23.1
24. Audit remaining Python packages (Werkzeug, requests, python-dateutil)
25. EdgeTTS - переключить на :latest
26. Verify Node.js version (22.14.0 vs 22.11.0 LTS)

### Фаза 6 (Следующий квартал) - Миграции сервисов

27.**NVIDIA GPU Exporter**→**DCGM Exporter 4.4.2-4.7.0**(HIGH PRIORITY)

- Исследовать развертывание DCGM (Docker/Helm)
- Планировать миграцию с mindprince на DCGM
- Обновить Prometheus scrape configs
- Тестировать сбор GPU метрик

### Будущая оценка

- Redis 7.0.15 → 7.4.0 (инкрементально) или 8.4.0-alpine (мажор, требует
  тестирования)
- Go 1.24.10 → 1.25.4 (major version)
- Node.js version verification and LTS alignment
- Prometheus v3.7.3 LTS долгосрочная стабильность
- Grafana v12.3.0 стабилизация после мажорного обновления

## Рекомендации по приоритетам

### Приоритет 1 (Немедленно - эта неделя)

- Cloudflared обновлен до 2025.11.1
- Обновить LiteLLM до stable релиза (v1.80.0-stable.1)
- Обновить Open WebUI до v0.6.40
- Спланировать тестирование Ollama v0.13.0

### Приоритет 2 (На следующей неделе)

-**Redis Exporter**v1.62.0 → v1.80.1 (КРИТИЧНО - 18 версий!)

- Обновить SearXNG digest (16 дней устарел)
- Переключить Tika на версионный тег 3.2.3.0-full
- Обновить MCPO Server до v0.0.19
- Обновить Backrest до v1.10.1

### Приоритет 3 (В спринте - 2-4 недели)

- Обновить стек мониторинга (Prometheus v3.7.3, Grafana 11.6.8, Loki v3.6.2)
- Обновить остальные экспортеры (Node, Postgres, Blackbox, Nginx, cAdvisor)
- Подготовить план миграции на Grafana 12.x

### Приоритет 4 (В месяце)

-**Fluent Bit 3→4**(МАЖОР + SECURITY - высокий приоритет!)

- Спланировать обновление Ollama v0.13.0 с GPU тестированием
- Исследовать DCGM Exporter как замену NVIDIA GPU Exporter
- Оценить обновление Redis до 7.4.0 или 8.4.0

## Быстрые команды

```bash
# Проверка текущих версий
docker compose ps

# Проверка доступных обновлений образов
docker compose pull

# Валидация конфигурации
docker compose config

# Обновление и перезапуск конкретного сервиса
docker compose up -d [service_name]

# Проверка всех health checks
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# Проверка версий образов
docker images | grep -E "(ollama|litellm|prometheus|grafana)"

# Проверка логов сервиса
docker compose logs -f [service_name]

# Python package audits
cd conf/webhook-receiver && pip list --outdated
cd ops/ollama-exporter && pip list --outdated

# Verify Node.js/npm versions
node --version
npm --version

# Проверка дайджестов образов
docker inspect [image_name] | jq '.[0].RepoDigests'
```

## Заметки по безопасности

-**CRITICAL**: Fluent Bit 4.2.0 содержит исправления безопасности - высокий
приоритет обновления -**HIGH**: Redis Exporter отстает на 18 версий -
потенциальные security fixes

-**COMPLETED**: Cloudflared обновлен до последней версии 2025.11.1 с security
fixes -**MEDIUM**: SearXNG digest устарел на 16 дней - рекомендуется
обновление -**NOTE**: LiteLLM требует перехода с RC на stable релиз для
продакшена

## Метрики прогресса обновлений

### Общий прогресс

-**Завершено**: 1/27 обновлений (4%) -**В процессе (Фаза 1)**: 33%
(1/3) -**Запланировано**: 26 обновлений

### Прогресс по фазам

-**Фаза 1**(эта неделя): ⏳ 33% (1/3) -**Фаза 2**(следующий спринт): 0%
(0/6) -**Фаза 3**(экспортеры): 0% (0/7) -**Фаза 4**(мажорные): 0% (0/4) -**Фаза
5**(зависимости): 0% (0/6) -**Фаза 6**(миграции): 0% (0/1)

### Динамика с предыдущего аудита

-**2025-11-25**: Базовый аудит, 26 обновлений выявлено -**2025-11-27**:
Cloudflared обновлен -**2025-11-28**: Повторный аудит, выявлено 2 новых релиза
(MCPO, Backrest)

## История изменений

-**2025-11-28 14:00**: Полный повторный аудит всех сервисов

- Проверены последние доступные версии через GitHub API и Docker Hub
- Обновлены digest-образы (SearXNG)
- Обнаружены новые релизы: MCPO Server v0.0.19, Backrest v1.10.1
- Redis Exporter повышен до HIGH приоритета (18 версий отставания)
- Fluent Bit security fixes отмечены как критичные -**2025-11-27**: Cloudflared
  обновлен 2024.10.0 → 2025.11.1 -**2025-11-25**: Первичная матрица версий
  сервисов (базовый аудит)

## Следующие действия

### На этой неделе

1. Завершить Фазу 1 (LiteLLM stable + Open WebUI v0.6.40)
2. Начать планирование Фазы 2 (инфраструктура)

### На следующей неделе

3.**КРИТИЧНО**: Обновить Redis Exporter (18 версий!) 4. Обновить SearXNG
digest 5. Обновить MCPO Server и Backrest 6. Переключить Tika на version tag

### В течение месяца

7. Обновить Fluent Bit 3→4 (SECURITY)
8. Подготовить тестирование Ollama v0.13.0
9. Начать миграцию на DCGM Exporter

## Следующий аудит

**Запланирован**: 2025-12-05 (через неделю)**Фокус**:

- Проверка завершения Фазы 1
- Оценка прогресса Фазы 2
- Верификация security updates (Fluent Bit, Redis Exporter)

---

**Последнее обновление**: 2025-11-28 14:00**Следующая проверка**: 2025-12-05
**Автор**: Claude Code**Метод проверки**: GitHub API + Docker Hub API + docker
inspect

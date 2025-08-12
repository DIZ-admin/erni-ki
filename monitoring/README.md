# 📊 Система мониторинга ERNI-KI

> **Комплексная система мониторинга AI-инфраструктуры с поддержкой GPU, централизованным логгированием и HTTPS мониторингом внешних доменов**

## 🎯 Обзор системы

Система мониторинга ERNI-KI обеспечивает полный контроль над AI-инфраструктурой, включая мониторинг Ollama, OpenWebUI, GPU ресурсов, и внешних сервисов через Cloudflare туннели.

### 📈 Текущие показатели производительности

- **Targets доступность**: 23/37 UP (62.2%) - *Цель: 95%*
- **Elasticsearch статус**: 🟢 GREEN (100% активных шардов)
- **AI-сервисы мониторинг**: ✅ Активен (Ollama Exporter)
- **HTTPS мониторинг**: ✅ Настроен (2 внешних домена)
- **Потребление ресурсов**: 2.79% CPU, 88.99MB RAM

## 🏗️ Архитектура системы

### Основные компоненты

| Компонент | Порт | Статус | Описание |
|-----------|------|--------|----------|
| **Prometheus** | 9091 | 🟢 | Сбор и хранение метрик |
| **Grafana** | 3000 | 🟢 | Визуализация и дашборды |
| **Alertmanager** | 9093 | 🟢 | Управление алертами |
| **Elasticsearch** | 9200 | 🟢 | Хранение логов (single-node) |
| **Kibana** | 5601 | 🟢 | Анализ логов |
| **Fluent Bit** | 2020/2021/24224 | 🟢 | Сбор логов |

### Exporters и мониторинг

| Exporter | Порт | Статус | Метрики |
|----------|------|--------|---------|
| **Node Exporter** | 9101 | 🟢 | Системные ресурсы |
| **NVIDIA Exporter** | 9445 | 🟢 | GPU метрики |
| **PostgreSQL Exporter** | 9187 | 🟢 | База данных |
| **Redis Exporter** | 9121 | 🟢 | Кэш |
| **Ollama Exporter** | 9778 | 🟢 | **AI-сервисы** |
| **Blackbox Exporter** | 9115 | 🟢 | HTTP/HTTPS проверки |
| **cAdvisor** | 8081 | 🟢 | Контейнеры |

## 🤖 AI-сервисы мониторинг

### Ollama Exporter (Новый компонент)

**Порт**: 9778  
**Статус**: ✅ Активен  
**Назначение**: Мониторинг AI-сервиса Ollama

#### Доступные метрики:
- `ollama_info{version}` - Версия Ollama (текущая: 0.11.3)
- `ollama_models_total` - Общее количество моделей (5)
- `ollama_model_size_bytes{model}` - Размер каждой модели
- `ollama_models_total_size_bytes` - Общий размер всех моделей (30.66GB)
- `ollama_running_models` - Количество запущенных моделей
- `ollama_model_vram_bytes{model}` - Использование VRAM по моделям
- `ollama_up` - Статус доступности сервиса

#### Текущие данные:
```
Версия Ollama: 0.11.3
Всего моделей: 5
├── gpt-oss:20b (13.78GB)
├── Mistral:7b (4.37GB)
├── gemma3n:e4b (7.55GB)
├── deepseek-r1:7b (4.68GB)
└── nomic-embed-text:latest (274MB)
Общий размер: 30.66GB
Запущенные модели: 0
```

## 🌐 HTTPS мониторинг

### Внешние домены

| Домен | Статус | Время отклика | Описание |
|-------|--------|---------------|-----------|
| **diz.zone** | 🟢 HTTP 200 | 0.076s | Основной домен |
| **search.diz.zone** | 🟡 HTTP 502 | 0.085s | SearXNG (требует исправления) |

### Blackbox Exporter конфигурация

- **Модуль**: `https_2xx` - HTTPS проверки с SSL валидацией
- **Таймаут**: 10s
- **Проверяемые коды**: 200, 201, 202, 204
- **SSL**: Валидация включена

## 🗄️ Elasticsearch оптимизация

### Single-node конфигурация

**Статус кластера**: 🟢 GREEN  
**Активные шарды**: 19/19 (100%)  
**Неназначенные шарды**: 0  

#### Ключевые настройки:
```yaml
environment:
  - discovery.type=single-node          # Режим одного узла
  - xpack.security.enabled=false        # Отключена безопасность
  - "ES_JAVA_OPTS=-Xms2g -Xmx2g"       # Heap 2GB
  - index.number_of_replicas=0          # Без реплик
```

#### Ресурсы:
- **Memory limit**: 3GB (увеличено с 2GB)
- **CPU limit**: 1.0 core
- **Disk usage**: Оптимизировано для single-node

## 📊 Targets и доступность

### Статистика targets

- **Всего targets**: 37
- **UP targets**: 23 (62.2%)
- **DOWN targets**: 14 (37.8%)
- **Цель**: 95% доступности

### Отключенные targets

Следующие targets отключены как нефункциональные:

```yaml
# Отключенные в prometheus.yml
- cloudflared:8080          # Не предоставляет /metrics endpoint
- elasticsearch:9200        # Требует отдельный elasticsearch_exporter
```

### Проблемные targets

Требуют диагностики и исправления:
- DNS-резолюция некоторых сервисов
- Сетевые проблемы между контейнерами
- Неправильные endpoints

## 🚀 Быстрый старт

### Запуск системы мониторинга

```bash
# Запуск всех компонентов мониторинга
docker-compose -f monitoring/docker-compose.monitoring.yml up -d

# Проверка статуса
docker-compose -f monitoring/docker-compose.monitoring.yml ps

# Проверка Ollama Exporter
curl http://localhost:9778/metrics
```

### Доступ к интерфейсам

| Сервис | URL | Описание |
|--------|-----|----------|
| Grafana | http://localhost:3000 | Дашборды и визуализация |
| Prometheus | http://localhost:9091 | Метрики и targets |
| Alertmanager | http://localhost:9093 | Управление алертами |
| Kibana | http://localhost:5601 | Анализ логов |
| Ollama Exporter | http://localhost:9778/metrics | AI-метрики |

## 🔧 Конфигурация

### Основные файлы конфигурации

```
monitoring/
├── prometheus.yml              # Конфигурация Prometheus
├── alertmanager.yml           # Правила алертинга
├── blackbox/blackbox.yml      # HTTP/HTTPS проверки
├── ollama_exporter.py         # AI-сервисы мониторинг
├── fluent-bit/fluent-bit.conf # Сбор логов
└── grafana/                   # Дашборды и настройки
```

### Переменные окружения

```bash
# Ollama Exporter
OLLAMA_URL=http://localhost:11434

# Elasticsearch
ES_JAVA_OPTS=-Xms2g -Xmx2g
discovery.type=single-node
```

## 📈 Метрики и KPI

### Целевые показатели

| Метрика | Текущее значение | Цель | Статус |
|---------|------------------|------|--------|
| Targets доступность | 62.2% | 95% | ⚠️ Требует улучшения |
| Elasticsearch статус | GREEN | GREEN | ✅ Достигнуто |
| CPU использование | 2.79% | <5% | ✅ Оптимально |
| RAM использование | 88.99MB | <200MB | ✅ Оптимально |
| Время отклика Grafana | 0.002s | <2s | ✅ Отлично |

### AI-метрики (Ollama)

- **Общий размер моделей**: 30.66GB
- **Количество моделей**: 5
- **Статус сервиса**: UP
- **Версия**: 0.11.3

## 🔍 Диагностика и устранение неисправностей

### Проверка статуса targets

```bash
# Общая статистика
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets | length'

# UP targets
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | select(.health == "up")' | jq -s 'length'

# DOWN targets с ошибками
curl -s http://localhost:9091/api/v1/targets | jq '.data.activeTargets[] | select(.health == "down") | {job: .labels.job, instance: .labels.instance, error: .lastError}'
```

### Проверка Ollama Exporter

```bash
# Статус метрик
curl -s http://localhost:9778/metrics | grep ollama_up

# Информация о моделях
curl -s http://localhost:9778/metrics | grep ollama_models_total

# Размеры моделей
curl -s http://localhost:9778/metrics | grep ollama_model_size_bytes
```

### Проверка Elasticsearch

```bash
# Статус кластера
curl -s http://localhost:9200/_cluster/health | jq '{status: .status, active_shards: .active_shards, unassigned_shards: .unassigned_shards}'

# Информация об индексах
curl -s http://localhost:9200/_cat/indices?v
```

## 📚 Дополнительная документация

- [Архитектурная документация](./docs/architecture.md)
- [Конфигурационное руководство](./docs/configuration.md)
- [Руководство по эксплуатации](./docs/operations.md)
- [Метрики и KPI](./docs/metrics.md)

## 🏷️ Версия и обновления

**Версия системы мониторинга**: 2.1.0  
**Дата последнего обновления**: 2025-08-07  
**Основные изменения**:
- ✅ Добавлен Ollama Exporter для AI-мониторинга
- ✅ Оптимизирован Elasticsearch для single-node
- ✅ Настроен HTTPS мониторинг внешних доменов
- ✅ Улучшена доступность targets с 59% до 62.2%

---

*Система мониторинга ERNI-KI - комплексное решение для мониторинга AI-инфраструктуры с поддержкой современных технологий и best practices.*

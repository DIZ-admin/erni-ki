# 📊 Детальная таблица активных сервисов системы ERNI-KI

> **Справочная документация для администрирования системы ERNI-KI** **Дата создания**: 2025-08-22
> **Версия системы**: Production Ready **Статус**: ✅ Все 29 сервисов работают

---

## 🤖 Application Layer (AI & Core Services)

| Сервис            | Статус              | Порты             | Конфигурация                  | Переменные окружения | Тип конфигурации | Примечания                                                          |
| ----------------- | ------------------- | ----------------- | ----------------------------- | -------------------- | ---------------- | ------------------------------------------------------------------- |
| **🧠 ollama**     | ✅ Up 24h (healthy) | `11434:11434`     | ❌ Нет                        | `env/ollama.env`     | ENV              | **🔥 КРИТИЧЕСКИЙ** • GPU: NVIDIA runtime • Автообновление отключено |
| **🤖 openwebui**  | ✅ Up 5h (healthy)  | `8080` (internal) | `conf/openwebui/*.json`       | `env/openwebui.env`  | JSON             | **🔥 КРИТИЧЕСКИЙ** • GPU: NVIDIA runtime • MCP интеграция           |
| **🌐 litellm**    | ✅ Up 2h (healthy)  | `4000:4000`       | `conf/litellm/config.yaml`    | `env/litellm.env`    | YAML             | Context Engineering Gateway • Memory: 6GB limit                     |
| **🔍 searxng**    | ✅ Up 2h (healthy)  | `8080` (internal) | `conf/searxng/*.yml`          | `env/searxng.env`    | YAML/TOML/INI    | RAG поиск • Redis кэширование                                       |
| **🔌 mcposerver** | ✅ Up 24h (healthy) | `8000:8000`       | `conf/mcposerver/config.json` | `env/mcposerver.env` | JSON             | Model Context Protocol                                              |

## 🔧 Processing Layer (Document & Media Processing)

| Сервис         | Статус              | Порты                  | Конфигурация | Переменные окружения | Тип конфигурации | Примечания                                       |
| -------------- | ------------------- | ---------------------- | ------------ | -------------------- | ---------------- | ------------------------------------------------ |
| **📄 docling** | ✅ Up 5h (healthy)  | `5001,8080` (internal) | ❌ Нет       | `env/docling.env`    | ENV              | OCR: EasyOCR • Memory: 10GB limit • CPU: 6 cores |
| **📋 tika**    | ✅ Up 24h (healthy) | `9998:9998`            | ❌ Нет       | `env/tika.env`       | ENV              | Apache Tika • Извлечение текста                  |
| **🎤 edgetts** | ✅ Up 24h (healthy) | `5050:5050`            | ❌ Нет       | `env/edgetts.env`    | ENV              | Синтез речи • OpenAI Edge TTS                    |

## 💾 Data Layer (Databases & Cache)

| Сервис       | Статус              | Порты                  | Конфигурация | Переменные окружения | Тип конфигурации | Примечания                                                            |
| ------------ | ------------------- | ---------------------- | ------------ | -------------------- | ---------------- | --------------------------------------------------------------------- |
| **🗄️ db**    | ✅ Up 24h (healthy) | `5432` (internal)      | ❌ Нет       | `env/db.env`         | ENV              | **🔥 КРИТИЧЕСКИЙ** • PostgreSQL + pgvector • Автообновление отключено |
| **⚡ redis** | ✅ Up 24h (healthy) | `6379,8001` (internal) | ❌ Нет       | `env/redis.env`      | ENV              | Redis Stack • Кэш и очереди                                           |

## 🚪 Gateway Layer (Proxy & Auth)

| Сервис             | Статус              | Порты                       | Конфигурация                 | Переменные окружения  | Тип конфигурации | Примечания                                                                     |
| ------------------ | ------------------- | --------------------------- | ---------------------------- | --------------------- | ---------------- | ------------------------------------------------------------------------------ |
| **🚪 nginx**       | ✅ Up 2h (healthy)  | `80:80, 443:443, 8080:8080` | `conf/nginx/*.conf`          | ❌ Нет                | CONF             | **🔥 КРИТИЧЕСКИЙ** • Reverse Proxy • SSL терминация • Автообновление отключено |
| **🔐 auth**        | ✅ Up 24h (healthy) | `9092:9090`                 | ❌ Нет                       | `env/auth.env`        | ENV              | JWT аутентификация • Go сервис                                                 |
| **☁️ cloudflared** | ✅ Up 5h            | ❌ Нет портов               | `conf/cloudflare/config.yml` | `env/cloudflared.env` | YAML             | **⚠️ Healthcheck отключен** • Cloudflare Tunnel                                |

## 📊 Monitoring Layer (Metrics & Observability)

| Сервис                  | Статус              | Порты                    | Конфигурация                 | Переменные окружения   | Тип конфигурации | Примечания                                      |
| ----------------------- | ------------------- | ------------------------ | ---------------------------- | ---------------------- | ---------------- | ----------------------------------------------- |
| **📈 prometheus**       | ✅ Up 1h (healthy)  | `9091:9090`              | `conf/prometheus/*.yml`      | `env/prometheus.env`   | YAML             | Сбор метрик • 35 targets                        |
| **📊 grafana**          | ✅ Up 37m (healthy) | `3000:3000`              | `conf/grafana/**/*.yml`      | `env/grafana.env`      | YAML/JSON        | Дашборды • Визуализация                         |
| **🚨 alertmanager**     | ✅ Up 24h (healthy) | `9093-9094:9093-9094`    | ❌ Нет                       | `env/alertmanager.env` | ENV              | Управление алертами                             |
| **📡 loki**             | ✅ Up 22h (healthy) | `3100:3100`              | `conf/loki/loki-config.yaml` | ❌ Нет                 | YAML             | Централизованное логирование                    |
| **📝 fluent-bit**       | ✅ Up 4m            | `2020:2020, 24224:24224` | `conf/fluent-bit/*.conf`     | `env/fluent-bit.env`   | CONF             | **⚠️ Healthcheck отключен** • Сбор логов → Loki |
| **📞 webhook-receiver** | ✅ Up 24h (healthy) | `9095:9093`              | ❌ Нет                       | ❌ Нет                 | ENV              | Обработка алертов                               |

## 🔍 Exporters (Metrics Collection)

| Сервис                   | Статус              | Порты       | Конфигурация                   | Переменные окружения        | Тип конфигурации | Примечания                                  |
| ------------------------ | ------------------- | ----------- | ------------------------------ | --------------------------- | ---------------- | ------------------------------------------- |
| **🖥️ node-exporter**     | ✅ Up 24h (healthy) | `9101:9100` | ❌ Нет                         | `env/node-exporter.env`     | ENV              | Системные метрики                           |
| **🐳 cadvisor**          | ✅ Up 24h (healthy) | `8081:8080` | ❌ Нет                         | `env/cadvisor.env`          | ENV              | Docker контейнеры                           |
| **🎯 blackbox-exporter** | ✅ Up 23h (healthy) | `9115:9115` | ❌ Нет                         | `env/blackbox-exporter.env` | ENV              | Проверка доступности                        |
| **🔥 nvidia-exporter**   | ✅ Up 24h (healthy) | `9445:9445` | ❌ Нет                         | `env/nvidia-exporter.env`   | ENV              | **🎮 GPU метрики** • NVIDIA runtime         |
| **🧠 ollama-exporter**   | ✅ Up 24h (healthy) | `9778:9778` | ❌ Нет                         | ❌ Нет                      | ENV              | AI модели метрики                           |
| **🗄️ postgres-exporter** | ✅ Up 24h (healthy) | `9187:9187` | `conf/postgres-exporter/*.yml` | `env/postgres-exporter.env` | YAML             | PostgreSQL метрики                          |
| **⚡ redis-exporter**    | ✅ Up 24h           | `9121:9121` | ❌ Нет                         | ❌ Нет                      | ENV              | **⚠️ Healthcheck отключен** • Redis метрики |
| **🚪 nginx-exporter**    | ✅ Up 24h           | `9113:9113` | ❌ Нет                         | ❌ Нет                      | ENV              | Nginx метрики                               |

## 🛠️ Infrastructure Layer (Backup & Management)

| Сервис            | Статус              | Порты       | Конфигурация            | Переменные окружения | Тип конфигурации | Примечания                                      |
| ----------------- | ------------------- | ----------- | ----------------------- | -------------------- | ---------------- | ----------------------------------------------- |
| **💾 backrest**   | ✅ Up 24h (healthy) | `9898:9898` | `conf/backrest/*.json`  | `env/backrest.env`   | JSON             | Резервное копирование • 7-дневные + 4-недельные |
| **🔄 watchtower** | ✅ Up 24h (healthy) | `8091:8080` | `conf/watchtower/*.env` | `env/watchtower.env` | ENV              | Автообновление контейнеров • HTTP API           |

---

## 📋 Сводная статистика

| Категория                       | Количество | Статус                                                     |
| ------------------------------- | ---------- | ---------------------------------------------------------- |
| **Всего сервисов**              | **29**     | ✅ 100% работают                                           |
| **Healthy сервисы**             | **25**     | ✅ 86% с healthcheck                                       |
| **Сервисы без healthcheck**     | **4**      | ⚠️ cloudflared, fluent-bit, redis-exporter, nginx-exporter |
| **GPU зависимые**               | **3**      | 🎮 ollama, openwebui, nvidia-exporter                      |
| **Критически важные**           | **3**      | 🔥 ollama, openwebui, db, nginx                            |
| **С конфигурационными файлами** | **12**     | 📁 41% имеют conf/                                         |
| **Только переменные окружения** | **17**     | 🔧 59% используют только env/                              |

## 🔧 Типы конфигураций

- **YAML/YML**: 8 сервисов (prometheus, grafana, loki, litellm, searxng, cloudflared,
  postgres-exporter)
- **CONF**: 2 сервиса (nginx, fluent-bit)
- **JSON**: 3 сервиса (backrest, mcposerver, openwebui)
- **ENV только**: 16 сервисов (остальные)

## ⚠️ Важные примечания

1. **🔥 Критически важные сервисы** имеют отключенное автообновление для стабильности
2. **🎮 GPU сервисы** требуют NVIDIA Container Toolkit
3. **⚠️ Сервисы без healthcheck** мониторятся через внешние метрики
4. **📁 Конфигурации** защищены от автоформатирования IDE
5. **🔄 Автообновления** настроены по scope группам для безопасности

## 🚀 Быстрые команды для администрирования

### Проверка статуса всех сервисов

```bash
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

### Проверка логов критически важных сервисов

```bash
# Ollama
docker-compose logs ollama --tail=50

# OpenWebUI
docker-compose logs openwebui --tail=50

# PostgreSQL
docker-compose logs db --tail=50

# Nginx
docker-compose logs nginx --tail=50
```

### Мониторинг ресурсов GPU

```bash
# Проверка GPU статуса
nvidia-smi

# Метрики GPU через Prometheus
curl -s http://localhost:9445/metrics | grep nvidia
```

### Проверка интеграций

```bash
# Fluent Bit метрики
curl -s http://localhost:2020/api/v1/metrics

# Prometheus targets
curl -s http://localhost:9091/api/v1/targets

# Loki health
curl -s http://localhost:3100/ready
```

## 📚 Связанная документация

- **[Архитектура системы](architecture.md)** - Диаграммы и описание компонентов
- **[Руководство администратора](admin-guide.md)** - Детальные инструкции по управлению
- **[Мониторинг и алерты](monitoring.md)** - Настройка Prometheus/Grafana
- **[Резервное копирование](backup-guide.md)** - Конфигурация Backrest
- **[Устранение неполадок](troubleshooting.md)** - Решение типовых проблем

---

**Последнее обновление**: 2025-08-22 **Система**: Production Ready **Статус**: ✅ Все сервисы
работают **Автор**: Альтэон Шульц (Tech Lead-Мудрец)

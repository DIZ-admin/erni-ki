# ERNI-KI Container Updates Report

**Дата:** Fri Aug 29 09:17:15 AM CEST 2025
**Система:** ERNI-KI
**Анализ:** konstantin

## 📊 Сводка обновлений

| Сервис | Текущая версия | Доступная версия | Обновление | Приоритет | Риск |
|--------|----------------|------------------|------------|-----------|------|
| nginx/nginx-prometheus-exporter | 1.1.0 | latest | ❓ maybe | HIGH | LOW |
| prom/prometheus | v2.48.0 | latest | ❓ maybe | MEDIUM | LOW |
| travisvn/openai-edge-tts | latest | latest | ✅ no | LOW | LOW |
| ghcr.io/open-webui/open-webui | cuda | v0.6.26 | 🔄 yes | HIGH | MEDIUM |
| pgvector/pgvector | pg15 | unknown | ❌ unknown | LOW | LOW |
| prometheuscommunity/postgres-exporter | v0.15.0 | latest | ❓ maybe | HIGH | MEDIUM |
| ghcr.io/docling-project/docling-serve-cpu | main | unknown | ❌ unknown | LOW | LOW |
| nginx | latest | unknown | ❌ unknown | HIGH | LOW |
| prom/alertmanager | v0.26.0 | latest | ❓ maybe | LOW | LOW |
| ghcr.io/open-webui/mcpo | latest | v0.0.17 | ✅ no | HIGH | MEDIUM |
| ollama/ollama | 0.11.6 | latest | ❓ maybe | HIGH | MEDIUM |
| searxng/searxng | latest | latest | ✅ no | LOW | LOW |
| gcr.io/cadvisor/cadvisor | v0.47.2 | unknown | ❌ unknown | LOW | LOW |
| containrrr/watchtower | latest | latest | ✅ no | LOW | LOW |
| oliver006/redis_exporter | v1.55.0 | latest | ❓ maybe | MEDIUM | MEDIUM |
| redis/redis-stack | latest | latest | ✅ no | MEDIUM | MEDIUM |
| ghcr.io/berriai/litellm | main-latest | v1.76.0.dev2 | 🔄 yes | LOW | LOW |
| fluent/fluent-bit | 3.0 | latest | ❓ maybe | LOW | LOW |
| apache/tika | latest-full | latest | ❓ maybe | LOW | LOW |
| grafana/loki | 3.4.1 | unknown | ❌ unknown | MEDIUM | LOW |
| mindprince/nvidia_gpu_prometheus_exporter | 0.1 | unknown | ❌ unknown | MEDIUM | LOW |
| prom/node-exporter | v1.7.0 | latest | ❓ maybe | LOW | LOW |
| prom/blackbox-exporter | v0.24.0 | latest | ❓ maybe | LOW | LOW |
| grafana/grafana | 10.2.0 | unknown | ❌ unknown | MEDIUM | LOW |
| cloudflare/cloudflared | latest | latest | ✅ no | LOW | LOW |
| garethgeorge/backrest | latest | latest | ✅ no | LOW | LOW |

## 📋 Детальный анализ

### nginx/nginx-prometheus-exporter

**Текущая версия:** 1.1.0  
**Доступная версия:** latest  
**Приоритет обновления:** HIGH  
**Риск обновления:** LOW  

**Рекомендации:**
- Обычно безопасное обновление
- Проверьте конфигурацию после обновления
- Мониторьте производительность

### prom/prometheus

**Текущая версия:** v2.48.0  
**Доступная версия:** latest  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** LOW  

### travisvn/openai-edge-tts

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### ghcr.io/open-webui/open-webui

**Текущая версия:** cuda  
**Доступная версия:** v0.6.26  
**Приоритет обновления:** HIGH  
**Риск обновления:** MEDIUM  

**Рекомендации:**
- OpenWebUI часто выпускает обновления с новыми функциями
- Проверьте changelog на breaking changes
- Сделайте backup базы данных

### pgvector/pgvector

**Текущая версия:** pg15  
**Доступная версия:** unknown  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### prometheuscommunity/postgres-exporter

**Текущая версия:** v0.15.0  
**Доступная версия:** latest  
**Приоритет обновления:** HIGH  
**Риск обновления:** MEDIUM  

**Рекомендации:**
- Критически важный сервис, требует осторожного обновления
- Обязательно сделайте полный backup базы данных
- Тестируйте на staging окружении

### ghcr.io/docling-project/docling-serve-cpu

**Текущая версия:** main  
**Доступная версия:** unknown  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### nginx

**Текущая версия:** latest  
**Доступная версия:** unknown  
**Приоритет обновления:** HIGH  
**Риск обновления:** LOW  

**Рекомендации:**
- Обычно безопасное обновление
- Проверьте конфигурацию после обновления
- Мониторьте производительность

### prom/alertmanager

**Текущая версия:** v0.26.0  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### ghcr.io/open-webui/mcpo

**Текущая версия:** latest  
**Доступная версия:** v0.0.17  
**Приоритет обновления:** HIGH  
**Риск обновления:** MEDIUM  

**Рекомендации:**
- OpenWebUI часто выпускает обновления с новыми функциями
- Проверьте changelog на breaking changes
- Сделайте backup базы данных

### ollama/ollama

**Текущая версия:** 0.11.6  
**Доступная версия:** latest  
**Приоритет обновления:** HIGH  
**Риск обновления:** MEDIUM  

**Рекомендации:**
- Ollama активно развивается, рекомендуется обновление
- Проверьте совместимость с текущими моделями
- Сделайте backup моделей перед обновлением

### searxng/searxng

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### gcr.io/cadvisor/cadvisor

**Текущая версия:** v0.47.2  
**Доступная версия:** unknown  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### containrrr/watchtower

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### oliver006/redis_exporter

**Текущая версия:** v1.55.0  
**Доступная версия:** latest  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** MEDIUM  

### redis/redis-stack

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** MEDIUM  

### ghcr.io/berriai/litellm

**Текущая версия:** main-latest  
**Доступная версия:** v1.76.0.dev2  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### fluent/fluent-bit

**Текущая версия:** 3.0  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### apache/tika

**Текущая версия:** latest-full  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### grafana/loki

**Текущая версия:** 3.4.1  
**Доступная версия:** unknown  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** LOW  

### mindprince/nvidia_gpu_prometheus_exporter

**Текущая версия:** 0.1  
**Доступная версия:** unknown  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** LOW  

### prom/node-exporter

**Текущая версия:** v1.7.0  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### prom/blackbox-exporter

**Текущая версия:** v0.24.0  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### grafana/grafana

**Текущая версия:** 10.2.0  
**Доступная версия:** unknown  
**Приоритет обновления:** MEDIUM  
**Риск обновления:** LOW  

### cloudflare/cloudflared

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

### garethgeorge/backrest

**Текущая версия:** latest  
**Доступная версия:** latest  
**Приоритет обновления:** LOW  
**Риск обновления:** LOW  

## 🚀 Рекомендуемый план обновления

### Фаза 1: Подготовка (0 downtime)

1. **Создание backup всех критических данных**
   ```bash
   # Backup PostgreSQL
   docker-compose exec db pg_dump -U postgres openwebui > backup-20250829.sql
   
   # Backup Ollama моделей
   docker-compose exec ollama ollama list > models-backup-20250829.txt
   
   # Backup конфигураций
   tar -czf config-backup-20250829.tar.gz env/ conf/
   ```

2. **Проверка доступности новых образов**
   ```bash
   docker pull ghcr.io/open-webui/open-webui:v0.6.26
   docker pull ghcr.io/berriai/litellm:v1.76.0.dev2
   ```

### Фаза 2: Обновление низкорискованных сервисов (< 30 сек downtime)

**Низкорискованные сервисы:**
- ghcr.io/berriai/litellm

```bash
docker-compose stop litellm
docker-compose up -d litellm
sleep 10  # Ожидание запуска

```

### Фаза 3: Обновление критических сервисов (< 2 мин downtime)

**Критические сервисы (по одному):**
- ghcr.io/open-webui/open-webui

```bash
# Обновление по одному сервису с проверкой
echo 'Обновление ghcr.io/open-webui/open-webui...'
docker-compose stop open-webui
docker-compose up -d open-webui
sleep 30  # Ожидание полного запуска
docker-compose ps open-webui  # Проверка статуса
# Проверьте работоспособность перед продолжением

```

## ⚠️ Риски и предупреждения

### 🔴 Высокорискованные обновления

Высокорискованных обновлений не обнаружено.

### ⚠️ Общие предупреждения

- **Всегда делайте backup перед обновлением**
- **Тестируйте обновления на staging окружении**
- **Мониторьте логи после обновления**
- **Имейте план отката**
- **Обновляйте по одному сервису за раз**

### 🔄 План отката

```bash
# В случае проблем - откат к предыдущим версиям
docker-compose down
# Восстановите предыдущие образы в compose.yml
docker-compose up -d

# Восстановление базы данных (если нужно)
# docker-compose exec db psql -U postgres openwebui < backup-YYYYMMDD.sql
```

## 🔧 Команды для обновления

### 🚀 Автоматизированное обновление

```bash
#!/bin/bash
# Скрипт автоматического обновления ERNI-KI контейнеров

set -euo pipefail

# Создание backup
echo 'Создание backup...'
mkdir -p .backups/20250829_091715
docker-compose exec db pg_dump -U postgres openwebui > .backups/20250829_091715/db-backup.sql

# Обновление образов
echo 'Загрузка новых образов...'
docker pull ghcr.io/open-webui/open-webui:v0.6.26
docker pull ghcr.io/berriai/litellm:v1.76.0.dev2

# Обновление compose файла
echo 'Обновление compose.yml...'
cp compose.yml compose.yml.backup

sed -i 's|ghcr.io/open-webui/open-webui:cuda|ghcr.io/open-webui/open-webui:v0.6.26|g' compose.yml
sed -i 's|ghcr.io/berriai/litellm:main-latest|ghcr.io/berriai/litellm:v1.76.0.dev2|g' compose.yml

# Перезапуск сервисов
echo 'Перезапуск сервисов...'
docker-compose down
docker-compose up -d

# Проверка статуса
echo 'Проверка статуса сервисов...'
sleep 30
docker-compose ps

echo 'Обновление завершено!'
```

### 🎯 Выборочное обновление

```bash
# Обновление только конкретного сервиса
SERVICE_NAME=openwebui  # Замените на нужный сервис
docker-compose stop $SERVICE_NAME
docker-compose pull $SERVICE_NAME
docker-compose up -d $SERVICE_NAME
docker-compose logs -f $SERVICE_NAME
```

## 🧪 Процедуры тестирования

### ✅ Проверка работоспособности после обновления

```bash
#!/bin/bash
# Скрипт проверки работоспособности ERNI-KI после обновления

echo '=== Проверка статуса контейнеров ==='
docker-compose ps

echo '=== Проверка логов на ошибки ==='
docker-compose logs --tail=50 | grep -i error || echo 'Ошибок не найдено'

echo '=== Проверка доступности сервисов ==='
# OpenWebUI
curl -f http://localhost:8080/health || echo 'OpenWebUI недоступен'

# Ollama
curl -f http://localhost:11434/api/tags || echo 'Ollama недоступен'

# PostgreSQL
docker-compose exec db pg_isready -U postgres || echo 'PostgreSQL недоступен'

echo '=== Проверка дискового пространства ==='
df -h

echo '=== Проверка использования памяти ==='
docker stats --no-stream

echo 'Проверка завершена!'
```

### 🔍 Мониторинг после обновления

**Что мониторить в первые 24 часа:**

1. **Логи сервисов**
   ```bash
   docker-compose logs -f --tail=100
   ```

2. **Производительность**
   ```bash
   docker stats
   ```

3. **Доступность через браузер**
   - OpenWebUI: http://localhost:8080
   - Grafana: http://localhost:3000
   - Prometheus: http://localhost:9090

4. **Функциональность RAG**
   - Тестирование поиска документов
   - Проверка генерации ответов
   - Валидация интеграций (SearXNG, Ollama)

---
*Отчет сгенерирован автоматически скриптом check-container-updates.sh*

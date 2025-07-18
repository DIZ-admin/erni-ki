# ⚙️ Управление ресурсами ERNI-KI

## Обзор

Данный документ описывает настройки ресурсных ограничений для всех сервисов ERNI-KI, рекомендации по оптимизации производительности и мониторинг использования ресурсов.

## 🎯 Принципы распределения ресурсов

### Приоритизация сервисов

1. **Критические сервисы** (высокий приоритет):
   - PostgreSQL - база данных
   - Ollama - AI модели с GPU
   - Redis - кэширование

2. **Основные сервисы** (средний приоритет):
   - OpenWebUI - веб-интерфейс
   - LiteLLM - AI gateway
   - Nginx - прокси-сервер

3. **Вспомогательные сервисы** (низкий приоритет):
   - Watchtower - автообновления
   - Cloudflared - туннели
   - Monitoring - мониторинг

## 📊 Конфигурация ресурсных ограничений

### 🔴 Критические сервисы

#### PostgreSQL (db)
```yaml
deploy:
  resources:
    limits:
      memory: 4G      # Максимум памяти для БД
      cpus: "2.0"     # Максимум 2 CPU ядра
    reservations:
      memory: 1G      # Гарантированная память
      cpus: "0.5"     # Гарантированный CPU
```

**Настройки производительности PostgreSQL:**
- `shared_buffers: 256MB` - основной кэш (25% от лимита памяти)
- `effective_cache_size: 1GB` - общий кэш системы (75% от лимита)
- `work_mem: 4MB` - память для сортировки
- `maintenance_work_mem: 64MB` - память для VACUUM
- `max_connections: 200` - максимум подключений

#### Ollama (AI модели с GPU)
```yaml
deploy:
  resources:
    limits:
      memory: 8G      # Максимум памяти для AI
      cpus: "4.0"     # Максимум 4 CPU ядра
    reservations:
      memory: 2G      # Гарантированная память
      cpus: "1.0"     # Гарантированный CPU
```

**GPU настройки:**
- `NVIDIA_VISIBLE_DEVICES=all` - доступ ко всем GPU
- `runtime: nvidia` - NVIDIA Container Runtime

#### Redis (кэширование)
```yaml
deploy:
  resources:
    limits:
      memory: 2G      # Максимум памяти для кэша
      cpus: "1.0"     # Максимум 1 CPU ядро
    reservations:
      memory: 512M    # Гарантированная память
      cpus: "0.2"     # Гарантированный CPU
```

**Redis настройки:**
- `maxmemory: 1gb` - лимит памяти Redis
- `maxmemory-policy: allkeys-lru` - политика вытеснения

### 🔵 Основные сервисы

#### OpenWebUI (веб-интерфейс)
```yaml
deploy:
  resources:
    limits:
      memory: 2G      # Максимум памяти
      cpus: "1.0"     # Максимум 1 CPU ядро
    reservations:
      memory: 512M    # Гарантированная память
      cpus: "0.5"     # Гарантированный CPU
```

#### LiteLLM (AI gateway)
```yaml
deploy:
  resources:
    limits:
      memory: 2G      # Максимум памяти
      cpus: "1.0"     # Максимум 1 CPU ядро
    reservations:
      memory: 512M    # Гарантированная память
      cpus: "0.5"     # Гарантированный CPU
```

#### Nginx (прокси-сервер)
```yaml
deploy:
  resources:
    limits:
      memory: 512M    # Максимум памяти
      cpus: "0.5"     # Максимум 0.5 CPU ядра
    reservations:
      memory: 128M    # Гарантированная память
      cpus: "0.1"     # Гарантированный CPU
```

### ⚪ Вспомогательные сервисы

#### Docling (обработка документов)
```yaml
deploy:
  resources:
    limits:
      memory: 2G      # Максимум памяти для OCR
      cpus: "1.0"     # Максимум 1 CPU ядро
    reservations:
      memory: 512M    # Гарантированная память
      cpus: "0.3"     # Гарантированный CPU
```

#### SearXNG (поисковый движок)
```yaml
deploy:
  resources:
    limits:
      memory: 1G      # Максимум памяти
      cpus: "0.5"     # Максимум 0.5 CPU ядра
    reservations:
      memory: 256M    # Гарантированная память
      cpus: "0.2"     # Гарантированный CPU
```

#### Watchtower (автообновления)
```yaml
deploy:
  resources:
    limits:
      memory: 128M    # Максимум памяти
      cpus: "0.1"     # Максимум 0.1 CPU ядра
    reservations:
      memory: 64M     # Гарантированная память
      cpus: "0.05"    # Гарантированный CPU
```

## 📈 Мониторинг ресурсов

### Команды мониторинга

```bash
# Общая статистика использования ресурсов
docker stats --no-stream

# Статистика конкретного сервиса
docker stats erni-ki-db-1 --no-stream

# Использование памяти по сервисам
docker stats --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Использование CPU по сервисам
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.NetIO}}"
```

### Алерты производительности

В `monitoring/security_alerts.yml` настроены алерты:

- **HighCPUUsage**: CPU > 90% в течение 5 минут
- **HighMemoryUsage**: Память > 90% в течение 5 минут
- **DatabaseConnectionsHigh**: Подключений к БД > 150
- **RedisMemoryHigh**: Память Redis > 90%

## 🎛️ Настройка под разные конфигурации

### Минимальная конфигурация (8GB RAM)

```yaml
# Уменьшенные лимиты для слабых серверов
db:
  deploy:
    resources:
      limits:
        memory: 2G
        cpus: "1.0"

ollama:
  deploy:
    resources:
      limits:
        memory: 4G
        cpus: "2.0"
```

### Производительная конфигурация (32GB+ RAM)

```yaml
# Увеличенные лимиты для мощных серверов
db:
  deploy:
    resources:
      limits:
        memory: 8G
        cpus: "4.0"

ollama:
  deploy:
    resources:
      limits:
        memory: 16G
        cpus: "8.0"
```

## 🔧 Оптимизация производительности

### PostgreSQL оптимизация

1. **Настройки памяти**:
   - `shared_buffers` = 25% от доступной памяти
   - `effective_cache_size` = 75% от доступной памяти
   - `work_mem` = (доступная память - shared_buffers) / max_connections

2. **Настройки дисков**:
   - `checkpoint_completion_target = 0.9`
   - `wal_buffers = 16MB`
   - `random_page_cost = 1.1` (для SSD)

3. **Настройки подключений**:
   - `max_connections = 200`
   - `shared_preload_libraries = 'pg_stat_statements,vector'`

### Redis оптимизация

1. **Настройки памяти**:
   - `maxmemory` = 50% от лимита контейнера
   - `maxmemory-policy = allkeys-lru`

2. **Настройки производительности**:
   - `save ""` - отключить RDB для кэша
   - `appendonly no` - отключить AOF для кэша

### Nginx оптимизация

1. **Worker процессы**:
   - `worker_processes auto`
   - `worker_connections 1024`

2. **Буферы**:
   - `client_max_body_size 100M`
   - `proxy_buffering on`
   - `proxy_buffer_size 4k`

## 📊 Рекомендации по масштабированию

### Горизонтальное масштабирование

1. **Разделение сервисов**:
   - База данных на отдельный сервер
   - AI модели на GPU-сервер
   - Веб-интерфейс на отдельные инстансы

2. **Load balancing**:
   - Nginx upstream для OpenWebUI
   - HAProxy для PostgreSQL
   - Redis Cluster для кэширования

### Вертикальное масштабирование

1. **Увеличение ресурсов**:
   - Больше RAM для PostgreSQL и Redis
   - Больше CPU для AI обработки
   - Больше GPU памяти для больших моделей

2. **Оптимизация дисков**:
   - NVMe SSD для PostgreSQL
   - Быстрые диски для логов
   - Сетевое хранилище для backup

## 🚨 Устранение проблем производительности

### Высокое использование памяти

```bash
# Проверить топ процессов по памяти
docker stats --format "table {{.Name}}\t{{.MemUsage}}" | sort -k2 -hr

# Перезапустить проблемный сервис
docker-compose restart <service_name>

# Очистить кэши
docker system prune -f
```

### Высокое использование CPU

```bash
# Проверить топ процессов по CPU
docker stats --format "table {{.Name}}\t{{.CPUPerc}}" | sort -k2 -hr

# Проверить логи сервиса
docker-compose logs <service_name> --tail 100

# Масштабировать сервис (если поддерживается)
docker-compose up -d --scale <service_name>=2
```

### Проблемы с дисками

```bash
# Проверить использование дисков
df -h

# Очистить логи Docker
docker system prune -a -f --volumes

# Проверить размер данных сервисов
du -sh data/*
```

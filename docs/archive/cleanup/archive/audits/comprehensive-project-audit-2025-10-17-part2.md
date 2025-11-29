---
language: ru
translation_status: archived
doc_version: '2025.11'
---

# КОМПЛЕКСНЫЙ АУДИТ ПРОЕКТА ERNI-KI - ЧАСТЬ 2

**Дата:**17 октября 2025**Версия:**1.0**Продолжение:**
[Часть 1](comprehensive-project-audit-2025-10-17.md)

---

## КОМАНДЫ ДЛЯ ПРОВЕРКИ

### Проверка статуса системы

{% raw %}

{% raw %}

```bash
# Общий статус всех контейнеров
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

# Unhealthy контейнеры (должно быть 0)
docker ps --filter "health=unhealthy"

# Healthy контейнеры (должно быть 37)
docker ps --filter "health=healthy" | wc -l

# Использование ресурсов
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Disk usage (должно быть <75%)
df -h | grep nvme0n1p2

# GPU utilization
nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader
```

{% endraw %}

{% endraw %}

### Проверка критических интеграций

```bash
# OpenWebUI health
curl -s http://localhost:8080/health

# Ollama API
curl -s http://localhost:11434/api/tags | jq -r '.models[0].name'

# LiteLLM health (требует API key)
curl -s -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
 http://localhost:4000/health

# PostgreSQL connectivity
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SELECT 1;"

# Redis connectivity
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 PING

# SearXNG health
docker exec erni-ki-searxng-1 wget -q -O- http://localhost:8080/healthz
```

### Проверка производительности

```bash
# PostgreSQL cache hit ratio (должно быть >95%)
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c \
 "SELECT blks_hit::float/(blks_hit + blks_read) as cache_hit_ratio FROM pg_stat_database WHERE datname='openwebui';"

# Redis cache hit rate (должно быть >60%)
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 INFO stats | grep -E "keyspace_hits|keyspace_misses"

# Redis latency (должно быть <10ms)
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 --latency-history

# PostgreSQL database size
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c \
 "SELECT pg_database_size('openwebui')/1024/1024 as size_mb;"

# PostgreSQL slow queries (>100ms)
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c \
 "SELECT query, calls, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 10;"
```

### Проверка логов на ошибки

```bash
# OpenWebUI errors (последние 24 часа)
docker logs erni-ki-openwebui-1 --since 24h 2>&1 | grep -iE "error|fatal|critical" | wc -l

# Ollama errors
docker logs erni-ki-ollama-1 --since 24h 2>&1 | grep -iE "error|fatal|critical" | wc -l

# PostgreSQL errors
docker logs erni-ki-db-1 --since 24h 2>&1 | grep -iE "error|fatal|critical" | wc -l

# Nginx errors (исключая healthcheck)
docker logs erni-ki-nginx-1 --since 24h 2>&1 | grep -iE "error" | grep -v "HEALTHCHECK" | wc -l

# LiteLLM errors
docker logs erni-ki-litellm --since 24h 2>&1 | grep -iE "error|fatal|critical" | wc -l
```

### Проверка безопасности

```bash
# SSL сертификаты (срок действия)
openssl x509 -in conf/ssl/cert.pem -noout -dates

# Cloudflare tunnel status
docker logs erni-ki-cloudflared-1 --tail 20

# Nginx rate limiting
docker exec erni-ki-nginx-1 cat /etc/nginx/nginx.conf | grep -A 5 "limit_req"

# Redis ACL
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ACL LIST
```

---

## ДЕТАЛЬНЫЕ РЕКОМЕНДАЦИИ ПО ИСПРАВЛЕНИЮ

### 1. Исправление OpenWebUI Redis Authentication

**Проблема:**97 ошибок за 24 часа "invalid username-password pair or user is
disabled"

**Диагностика:**

```bash
# Проверить текущие Redis ACL
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ACL LIST

# Проверить Redis конфигурацию в OpenWebUI
docker exec erni-ki-openwebui-1 env | grep REDIS
```

**Решение:**

**Вариант 1: Использовать default пользователя (рекомендуется)**

```bash
# Обновить env/openwebui.env
REDIS_URL=redis://:ErniKiRedisSecurePassword2024@redis:6379/0

# Перезапустить OpenWebUI
docker restart erni-ki-openwebui-1
```

**Вариант 2: Создать отдельного пользователя**

```bash
# Создать пользователя openwebui в Redis
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 \
 ACL SETUSER openwebui on >OpenWebUIPass2024 ~* +@all

# Обновить env/openwebui.env
REDIS_URL=redis://openwebui:OpenWebUIPass2024@redis:6379/0 # pragma: allowlist secret

# Сохранить ACL
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ACL SAVE

# Перезапустить OpenWebUI
docker restart erni-ki-openwebui-1
```

**Верификация:**

```bash
# Проверить логи OpenWebUI (не должно быть Redis ошибок)
docker logs erni-ki-openwebui-1 --tail 50 | grep -i redis

# Проверить Redis connections
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 CLIENT LIST | grep openwebui
```

---

### 2. Исправление OpenWebUI → MCP Server Connectivity

**Проблема:**"Cannot connect to host mcposerver:8000 ssl:default [Name or
service not known]"

**Диагностика:**

```bash
# Проверить Docker network
docker network inspect erni-ki_default | grep -A 10 mcposerver

# Проверить DNS resolution из OpenWebUI
docker exec erni-ki-openwebui-1 nslookup mcposerver

# Проверить MCP Server доступность
docker exec erni-ki-openwebui-1 curl -s http://mcposerver:8000/health
```

**Решение:**

**Вариант 1: Проверить depends_on в compose.yml**

```yaml
# В compose.yml для openwebui добавить зависимость
openwebui:
  depends_on:
  mcposerver:
  condition: service_healthy
```

**Вариант 2: Перезапустить контейнеры**

```bash
# Перезапустить оба контейнера
docker restart erni-ki-mcposerver-1 erni-ki-openwebui-1

# Подождать 30 секунд для инициализации
sleep 30

# Проверить connectivity
docker exec erni-ki-openwebui-1 curl -s http://mcposerver:8000/health
```

**Вариант 3: Проверить MCP Server конфигурацию в OpenWebUI**

```bash
# Проверить env/openwebui.env
grep MCP env/openwebui.env

# Если нужно, добавить:
MCP_SERVER_URL=http://mcposerver:8000
```

**Верификация:**

```bash
# Проверить логи OpenWebUI (не должно быть MCP DNS ошибок)
docker logs erni-ki-openwebui-1 --tail 50 | grep -i mcposerver

# Проверить MCP инструменты в OpenWebUI
curl -s http://localhost:8080/api/tools | jq
```

---

### 3. Оптимизация Redis Cache Hit Rate

**Проблема:**Cache hit rate 46.6% (целевое значение >60%)

**Диагностика:**

```bash
# Текущая статистика
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 INFO stats

# Текущая память
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 INFO memory

# Eviction policy
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 CONFIG GET maxmemory-policy
```

**Решение:**

**Шаг 1: Увеличить maxmemory**

```bash
# Редактировать conf/redis/redis.conf
# Было:
maxmemory 1gb

# Стало:
maxmemory 2gb
```

**Шаг 2: Оптимизировать eviction policy**

```bash
# Добавить в conf/redis/redis.conf
maxmemory-policy allkeys-lru
maxmemory-samples 10
```

**Шаг 3: Перезапустить Redis**

```bash
docker restart erni-ki-redis-1

# Подождать 10 секунд
sleep 10

# Проверить новую конфигурацию
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 CONFIG GET maxmemory
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 CONFIG GET maxmemory-policy
```

**Верификация (через 24 часа):**

```bash
# Проверить новый cache hit rate (должно быть >60%)
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 INFO stats | grep -E "keyspace_hits|keyspace_misses"

# Вычислить hit rate
# hit_rate = keyspace_hits / (keyspace_hits + keyspace_misses) * 100
```

---

### 4. Добавление Health Checks для Exporters

**Проблема:**5 exporters без health checks (Fluent Bit, Redis Exporter, Nginx
Exporter, NVIDIA Exporter, Ollama Exporter)

**Решение:**

**Редактировать compose.yml:**

```yaml
# Fluent Bit
fluent-bit:
 healthcheck:
 test: ['CMD-SHELL', 'curl -f http://localhost:2020/api/v1/health || exit 1']
 interval: 30s
 timeout: 10s
 retries: 3
 start_period: 10s

# Redis Exporter
redis-exporter:
 healthcheck:
 test:
 [
 'CMD-SHELL',
 'wget --quiet --tries=1 --spider http://localhost:9121/metrics || exit 1',
 ]
 interval: 30s
 timeout: 10s
 retries: 3
 start_period: 10s

# Nginx Exporter
nginx-exporter:
 healthcheck:
 test:
 [
 'CMD-SHELL',
 'wget --quiet --tries=1 --spider http://localhost:9113/metrics || exit 1',
 ]
 interval: 30s
 timeout: 10s
 retries: 3
 start_period: 10s

# NVIDIA Exporter
nvidia-exporter:
 healthcheck:
 test:
 [
 'CMD-SHELL',
 'wget --quiet --tries=1 --spider http://localhost:9445/metrics || exit 1',
 ]
 interval: 30s
 timeout: 10s
 retries: 3
 start_period: 10s

# Ollama Exporter
ollama-exporter:
 healthcheck:
 test: ['CMD-SHELL', 'curl -f http://localhost:9778/metrics || exit 1']
 interval: 30s
 timeout: 10s
 retries: 3
 start_period: 10s
```

**Применить изменения:**

{% raw %}

```bash
# Пересоздать контейнеры с новыми health checks
docker compose up -d --force-recreate fluent-bit redis-exporter nginx-exporter nvidia-exporter ollama-exporter

# Подождать 30 секунд для инициализации
sleep 30

# Проверить health status
docker ps --filter "name=exporter" --format "table {{.Names}}\t{{.Status}}"
docker ps --filter "name=fluent-bit" --format "table {{.Names}}\t{{.Status}}"
```

{% endraw %}

---

### 5. Генерация SSL Сертификатов

**Проблема:**SSL сертификаты отсутствуют в `conf/ssl/`

**Решение:**

**Вариант 1: Self-signed сертификаты (для тестирования)**

```bash
# Использовать существующий скрипт
cd conf/ssl
./generate-ssl-certs.sh

# Проверить созданные файлы
ls -lh conf/ssl/
```

**Вариант 2: Let's Encrypt (для production)**

```bash
# Установить certbot
sudo apt-get install -y certbot

# Получить сертификат (требует остановки Nginx на 80 порту)
sudo certbot certonly --standalone -d ki.erni-gruppe.ch

# Скопировать сертификаты
sudo cp /etc/letsencrypt/live/ki.erni-gruppe.ch/fullchain.pem conf/ssl/cert.pem
sudo cp /etc/letsencrypt/live/ki.erni-gruppe.ch/privkey.pem conf/ssl/key.pem

# Установить права
sudo chown konstantin:konstantin conf/ssl/*.pem
```

**Вариант 3: Использовать Cloudflare Origin Certificates**

```bash
# 1. Зайти в Cloudflare Dashboard → SSL/TLS → Origin Server
# 2. Create Certificate
# 3. Скопировать Certificate и Private Key
# 4. Сохранить в conf/ssl/

# Создать cert.pem
cat > conf/ssl/cert.pem << 'EOF'
-----BEGIN CERTIFICATE-----
[Вставить Cloudflare Origin Certificate]
-----END CERTIFICATE-----
EOF

# Создать key.pem
cat > conf/ssl/key.pem << 'EOF'
-----BEGIN PRIVATE KEY----- # pragma: allowlist secret
[Вставить Private Key]
-----END PRIVATE KEY-----
EOF

# Установить права
chmod 600 conf/ssl/key.pem
chmod 644 conf/ssl/cert.pem
```

**Верификация:**

```bash
# Проверить сертификат
openssl x509 -in conf/ssl/cert.pem -noout -text

# Проверить срок действия
openssl x509 -in conf/ssl/cert.pem -noout -dates

# Перезапустить Nginx
docker restart erni-ki-nginx-1

# Проверить HTTPS
curl -k https://localhost/health
```

---

## BEST PRACTICES АНАЛИЗ

### Соблюдаются

1.**Docker Compose структура:**

- Использование named volumes для критических данных
- Health checks для большинства сервисов
- Resource limits для критических сервисов
- Depends_on с condition: service_healthy
- Restart policies (unless-stopped)

  2.**Логирование:**

- 4-уровневая стратегия логирования
- Централизованное логирование через Fluent Bit
- Структурированные логи (JSON format)
- Log rotation настроен

  3.**Мониторинг:**

- Полный Prometheus + Grafana стек
- Множественные exporters для метрик
- Loki для централизованных логов
- Alertmanager для уведомлений

  4.**Backup:**

- Backrest для автоматических бэкапов
- Retention policy (7 дней daily, 4 недели weekly)
- Backup критических данных (PostgreSQL, OpenWebUI, Ollama)

  5.**Автоматизация:**

- Watchtower для автообновлений
- Selective auto-updates (критические сервисы исключены)
- Webhook notifications

### Требуют улучшения

1.**Безопасность:**

- Пароли в env файлах (рекомендуется Docker Secrets)
- SSL сертификаты отсутствуют локально
- Нет автоматического обновления SSL сертификатов

  2.**CI/CD:**

- Нет автоматизированного тестирования
- Нет автоматического деплоя
- Нет pre-commit hooks для валидации

  3.**High Availability:**

- PostgreSQL single instance (нет репликации)
- Redis single instance (нет Sentinel)
- Single point of failure для критических сервисов

  4.**Мониторинг:**

- 5 exporters без health checks
- Нет автоматических алертов для Redis cache hit rate
- Нет дашборда для MCP Server метрик

---

## ПРИОРИТИЗАЦИЯ ЗАДАЧ

### Неделя 1 (Критические исправления)

**День 1-2:**

- [ ] Исправить OpenWebUI Redis authentication (30 мин)
- [ ] Исправить OpenWebUI → MCP Server connectivity (20 мин)
- [ ] Добавить health checks для exporters (1 час)

**День 3-4:**

- [ ] Оптимизировать Redis cache hit rate (1 час)
- [ ] Сгенерировать SSL сертификаты (1 час)
- [ ] Обновить README.md (15 мин)

**День 5-7:**

- [ ] Тестирование всех исправлений
- [ ] Мониторинг метрик после изменений
- [ ] Документирование изменений

### Неделя 2-4 (Оптимизация)

**Неделя 2:**

- [ ] Оптимизировать Prometheus scrape intervals
- [ ] Настроить PostgreSQL autovacuum
- [ ] Оптимизировать Nginx rate limiting

**Неделя 3:**

- [ ] Настроить алерты для Redis cache hit rate
- [ ] Добавить дашборд для MCP Server
- [ ] Настроить автоматическую очистку логов

**Неделя 4:**

- [ ] Мигрировать пароли на Docker Secrets
- [ ] Настроить Let's Encrypt автообновление
- [ ] Провести повторный аудит

### Месяц 2-3 (Масштабирование)

**Месяц 2:**

- [ ] Настроить PostgreSQL репликацию (HA)
- [ ] Настроить Redis Sentinel (HA)
- [ ] CI/CD pipeline для тестирования

**Месяц 3:**

- [ ] Kubernetes migration planning
- [ ] Автоматизированное тестирование интеграций
- [ ] Профилирование и оптимизация

---

## КОНТАКТЫ И ПОДДЕРЖКА

**Документация:**

- Основная: [Документация Home](../../overview.md)
- Архитектура:
  [docs/architecture/architecture.md](../../architecture/architecture.md)
- Руководство администратора:
  [docs/operations/core/admin-guide.md](../../operations/core/admin-guide.md)

**Runbooks:**

- Troubleshooting:
  [docs/operations/troubleshooting/troubleshooting-guide.md](../../operations/troubleshooting/troubleshooting-guide.md)
- Backup/Restore:
  [docs/operations/maintenance/backup-restore-procedures.md](../../operations/maintenance/backup-restore-procedures.md)
- Service Restart:
  [docs/operations/maintenance/service-restart-procedures.md](../../operations/maintenance/service-restart-procedures.md)

**Отчёты:**

- Предыдущий аудит:
  [comprehensive-audit-2025-10-14.md](comprehensive-audit-2025-10-14.md)
- Последний ремонт: system-repair-2025-10-16 (файл недоступен в архиве)

---

**Следующий аудит:**17 января 2026 (через 3 месяца)**Ответственный:**DevOps
Team**Статус:**СИСТЕМА ГОТОВА К ПРОДАКШЕНУ

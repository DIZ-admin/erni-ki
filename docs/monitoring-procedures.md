# 📊 Процедуры мониторинга ERNI-KI

## Обзор

Данный документ описывает процедуры мониторинга системы ERNI-KI, включая настройку алертов, анализ метрик, диагностику проблем и процедуры реагирования на инциденты.

## 🎯 Архитектура мониторинга

### Компоненты системы мониторинга

1. **Prometheus** - сбор и хранение метрик
2. **Grafana** - визуализация и дашборды
3. **Alertmanager** - управление алертами и уведомлениями
4. **Node Exporter** - метрики хост-системы
5. **cAdvisor** - метрики контейнеров
6. **Redis Exporter** - метрики Redis
7. **Postgres Exporter** - метрики PostgreSQL
8. **Blackbox Exporter** - проверка доступности сервисов

### Сетевая архитектура

- **Monitoring сеть**: `erni-ki-monitoring` (172.19.0.0/16)
- **Изоляция**: отдельная сеть для безопасности
- **Доступ**: через Grafana веб-интерфейс

## 🚨 Алерты безопасности

### Критические алерты

#### HighErrorRate
```yaml
alert: HighErrorRate
expr: rate(nginx_http_requests_total{status=~"5.."}[5m]) > 0.1
for: 2m
severity: critical
```
**Описание**: Высокий уровень серверных ошибок (5xx)
**Действия**: Проверить логи Nginx, статус backend сервисов

#### SuspiciousLoginAttempts
```yaml
alert: SuspiciousLoginAttempts
expr: rate(nginx_http_requests_total{status="401"}[5m]) > 5
for: 1m
severity: warning
```
**Описание**: Множественные неудачные попытки аутентификации
**Действия**: Проверить IP источники, применить rate limiting

#### UnauthorizedAPIAccess
```yaml
alert: UnauthorizedAPIAccess
expr: rate(nginx_http_requests_total{status="403"}[5m]) > 10
for: 2m
severity: warning
```
**Описание**: Высокий уровень запрещенных запросов к API
**Действия**: Анализ логов доступа, блокировка подозрительных IP

### Системные алерты

#### HighCPUUsage
```yaml
alert: HighCPUUsage
expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
for: 5m
severity: warning
```
**Описание**: Высокое использование CPU (>90%)
**Действия**: Проверить топ процессов, масштабировать сервисы

#### HighMemoryUsage
```yaml
alert: HighMemoryUsage
expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
for: 5m
severity: warning
```
**Описание**: Высокое использование памяти (>90%)
**Действия**: Очистить кэши, перезапустить сервисы

#### OllamaDown
```yaml
alert: OllamaDown
expr: up{job="ollama"} == 0
for: 1m
severity: critical
```
**Описание**: Ollama сервис недоступен
**Действия**: Проверить GPU, перезапустить Ollama

## 📈 Ключевые метрики

### Производительность системы

1. **CPU Utilization**:
   - Метрика: `node_cpu_seconds_total`
   - Норма: < 80%
   - Критично: > 90%

2. **Memory Usage**:
   - Метрика: `node_memory_MemAvailable_bytes`
   - Норма: < 80%
   - Критично: > 90%

3. **Disk Usage**:
   - Метрика: `node_filesystem_avail_bytes`
   - Норма: > 20% свободного места
   - Критично: < 10% свободного места

4. **Network Traffic**:
   - Метрика: `node_network_receive_bytes_total`
   - Мониторинг: необычные пики трафика

### Метрики приложений

1. **HTTP Requests**:
   - Метрика: `nginx_http_requests_total`
   - Мониторинг: RPS, коды ответов, время ответа

2. **Database Connections**:
   - Метрика: `pg_stat_database_numbackends`
   - Норма: < 150 подключений
   - Критично: > 180 подключений

3. **Redis Memory**:
   - Метрика: `redis_memory_used_bytes`
   - Норма: < 80% от лимита
   - Критично: > 90% от лимита

4. **GPU Utilization**:
   - Метрика: `nvidia_gpu_utilization_percent`
   - Мониторинг: использование GPU для AI задач

## 🔍 Процедуры диагностики

### Ежедневные проверки

```bash
#!/bin/bash
# Скрипт ежедневной проверки системы

echo "🔍 ЕЖЕДНЕВНАЯ ПРОВЕРКА ERNI-KI"
echo "Дата: $(date)"
echo ""

# Проверка статуса всех сервисов
echo "📊 Статус сервисов:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""

# Проверка использования ресурсов
echo "⚡ Использование ресурсов:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
echo ""

# Проверка дискового пространства
echo "💾 Дисковое пространство:"
df -h | grep -E "(/$|/var|/home)"
echo ""

# Проверка логов на ошибки
echo "🚨 Критические ошибки в логах:"
docker-compose logs --since 24h | grep -i "error\|critical\|fatal" | tail -10
echo ""

# Проверка алертов Prometheus
echo "⚠️ Активные алерты:"
curl -s http://localhost:9093/api/v1/alerts | jq '.data[] | select(.state=="firing") | .labels.alertname' 2>/dev/null || echo "Alertmanager недоступен"
```

### Еженедельные проверки

```bash
#!/bin/bash
# Скрипт еженедельной проверки системы

echo "📅 ЕЖЕНЕДЕЛЬНАЯ ПРОВЕРКА ERNI-KI"
echo ""

# Проверка обновлений контейнеров
echo "🔄 Доступные обновления:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}"
echo ""

# Проверка размера логов
echo "📝 Размер логов:"
du -sh /var/lib/docker/containers/*/
echo ""

# Проверка backup'ов
echo "💾 Статус резервных копий:"
curl -s http://localhost:9898/v1/operations | jq '.operations[] | select(.type=="backup") | {id, status, created_at}' 2>/dev/null || echo "Backrest недоступен"
echo ""

# Проверка SSL сертификатов
echo "🔒 Статус SSL сертификатов:"
openssl x509 -in conf/nginx/ssl/cert.pem -noout -dates 2>/dev/null || echo "SSL сертификат не найден"
```

### Ежемесячные проверки

```bash
#!/bin/bash
# Скрипт ежемесячной проверки системы

echo "📆 ЕЖЕМЕСЯЧНАЯ ПРОВЕРКА ERNI-KI"
echo ""

# Анализ трендов производительности
echo "📈 Тренды производительности (за месяц):"
# Запросы к Prometheus для получения трендов
curl -s "http://localhost:9090/api/v1/query_range?query=avg(rate(node_cpu_seconds_total[5m]))&start=$(date -d '30 days ago' +%s)&end=$(date +%s)&step=3600" | jq '.data.result[0].values[-1][1]' 2>/dev/null || echo "Prometheus недоступен"

# Проверка роста данных
echo "📊 Рост объема данных:"
du -sh data/* | sort -hr

# Аудит безопасности
echo "🔒 Аудит безопасности:"
# Проверка паролей по умолчанию
grep -r "password\|secret" env/ | grep -v ".example" | wc -l
echo "Найдено паролей в конфигурации: $(grep -r "password\|secret" env/ | grep -v ".example" | wc -l)"

# Проверка прав доступа
echo "Файлы с неправильными правами:"
find . -name "*.env" ! -perm 600 2>/dev/null | wc -l
```

## 📊 Дашборды Grafana

### Основные дашборды

1. **System Overview**:
   - CPU, Memory, Disk, Network
   - Статус всех сервисов
   - Активные алерты

2. **Application Performance**:
   - HTTP метрики Nginx
   - Database performance
   - Redis metrics
   - AI model performance

3. **Security Dashboard**:
   - Failed login attempts
   - Rate limiting events
   - Suspicious activity
   - SSL certificate status

4. **Resource Utilization**:
   - Container resource usage
   - GPU utilization
   - Storage growth trends
   - Network traffic patterns

### Настройка дашбордов

```json
{
  "dashboard": {
    "title": "ERNI-KI System Overview",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Процедуры реагирования на инциденты

### Уровень 1: Информационные алерты

**Время реакции**: 4 часа в рабочее время

**Действия**:
1. Зафиксировать алерт в системе
2. Проанализировать тренды
3. Запланировать профилактические меры

### Уровень 2: Предупреждения

**Время реакции**: 1 час

**Действия**:
1. Проверить статус затронутых сервисов
2. Проанализировать логи
3. Применить временные меры
4. Уведомить команду

### Уровень 3: Критические инциденты

**Время реакции**: 15 минут

**Действия**:
1. Немедленно проверить доступность системы
2. Применить процедуры восстановления
3. Уведомить всех заинтересованных лиц
4. Начать процедуру эскалации

### Контакты для эскалации

- **Системный администратор**: [указать контакты]
- **DevOps инженер**: [указать контакты]
- **Руководитель проекта**: [указать контакты]
- **Служба поддержки**: [указать контакты]

## 📝 Документирование инцидентов

### Шаблон отчета об инциденте

```markdown
# Отчет об инциденте

**Дата**: [дата и время]
**Уровень**: [1/2/3]
**Статус**: [Открыт/В работе/Закрыт]

## Описание
[Краткое описание проблемы]

## Временная линия
- [время] - Обнаружение проблемы
- [время] - Начало расследования
- [время] - Применение временных мер
- [время] - Полное восстановление

## Причина
[Корневая причина инцидента]

## Решение
[Описание примененного решения]

## Профилактические меры
[Меры для предотвращения повторения]

## Уроки
[Извлеченные уроки и улучшения]
```

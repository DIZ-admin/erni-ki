---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Redis Monitoring с Grafana в системе ERNI-KI

## Обзор

Система ERNI-KI теперь включает полноценный мониторинг Redis через Grafana с
использованием Redis Data Source plugin. Это решение заменяет проблемный
Redis-exporter и обеспечивает стабильный мониторинг Redis 7.4.5 Alpine.

## Быстрый старт

### Доступ к Grafana

-**URL**: <http://localhost:3000> -**Логин**: admin -**Пароль**: admin123

### Доступ к Redis дашборду

1. Откройте Grafana в браузере
2. Перейдите в раздел "Dashboards"
3. Найдите дашборд "Redis Monitoring - ERNI-KI"

## Техническая конфигурация

### Redis Data Source

-**Название**: Redis-ERNI-KI -**Тип**: redis-datasource -**URL**:
redis://redis:6379 -**Аутентификация**: requirepass
($REDIS_PASSWORD) -**Режим**: standalone

### Автоматическая настройка

Конфигурация применяется автоматически через Grafana provisioning:

- Data Source: `conf/grafana/provisioning/datasources/redis.yml`
- Dashboard: `conf/grafana/dashboards/infrastructure/redis-monitoring.json`

## Доступные метрики

### Основные метрики

-**Memory Usage**: Использование памяти Redis -**Connected Clients**: Количество
подключенных клиентов -**Commands Processed**: Обработанные команды -**Network
I/O**: Сетевой трафик -**Keyspace**: Информация о базах данных

### Дополнительные метрики

-**Server Info**: Версия, время работы, режим -**Persistence**: Статус
сохранения данных -**Replication**: Информация о репликации (если настроена)

## Расширение мониторинга

### Добавление новых панелей

1. Откройте дашборд в режиме редактирования
2. Добавьте новую панель
3. Выберите Redis-ERNI-KI как источник данных
4. Настройте команду и поля:

-**Command**: info -**Section**: memory/stats/server/clients -**Field**:
конкретное поле из Redis INFO

### Примеры команд Redis

```bash
# Основная информация
INFO server
INFO memory
INFO stats
INFO clients

# Специфические метрики
DBSIZE
LASTSAVE
CONFIG GET maxmemory
```

## Мониторинг производительности

### Ключевые показатели для отслеживания

1.**used_memory**- использование памяти 2.**connected_clients**- количество
клиентов 3.**total_commands_processed**- общее количество
команд 4.**instantaneous_ops_per_sec**- операций в
секунду 5.**keyspace_hits/misses**- эффективность кэша

### Алерты и пороговые значения

- Memory usage > 80% от available
- Connected clients > 100
- Hit ratio < 90%
- Response time > 1ms

## Устранение неполадок

### Проблемы подключения

```bash
# Проверка статуса Redis
docker-compose ps redis

# Проверка подключения
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Проверка логов Grafana
docker-compose logs grafana --tail=20
```

## Переустановка плагина

```bash
# Переустановка Redis Data Source plugin
docker-compose exec grafana grafana-cli plugins uninstall redis-datasource
docker-compose exec grafana grafana-cli plugins install redis-datasource
docker-compose restart grafana
```

## Дополнительные ресурсы

### Официальная документация

- [Redis Data Source Plugin](https://grafana.com/grafana/plugins/redis-datasource/)
- [Redis INFO Command](https://redis.io/commands/info/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Альтернативные решения

1.**Redis Insight**для детального анализа 2.**Custom scripts**с отправкой метрик
в InfluxDB 3.**Прямые Redis команды**через CLI для диагностики

**Примечание**: Redis-exporter был удален из системы ERNI-KI из-за проблем
совместимости с Redis 7.4.5 Alpine. Grafana Redis Data Source Plugin является
предпочтительным решением.

## Обновления и обслуживание

### Регулярные задачи

- Мониторинг дискового пространства для Grafana данных
- Обновление дашбордов при изменении требований
- Резервное копирование конфигураций Grafana

### Автоматические обновления

Grafana настроена на автоматические обновления через Watchtower с меткой
`monitoring-stack`.

---

**Статус**: Активно**Последнее обновление**: 2025-09-19**Версия**: 1.0**Дата**:
2025-11-18

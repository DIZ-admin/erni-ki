---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Руководство по эксплуатации Redis в ERNI-KI

[TOC]

**Версия:**1.0**Дата:**23 сентября 2025**Система:**ERNI-KI

---

## Обзор

Redis в системе ERNI-KI используется как высокопроизводительный кэш для
OpenWebUI и SearXNG. Система полностью мониторится, имеет автоматическое
резервное копирование и оптимизирована для стабильной работы.

---

## Основные команды

### Проверка статуса

```bash
# Статус контейнера
docker ps | grep redis

# Подключение к Redis CLI
docker exec -it erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024"

# Проверка доступности
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping
```

## Мониторинг

```bash
# Информация о памяти
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info memory

# Статистика операций
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats

# Количество ключей
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" dbsize
```

## Резервное копирование

```bash
# Создание снапшота
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" BGSAVE

# Проверка статуса бэкапа
./scripts/redis-backup-metrics.sh status

# Тестирование восстановления
./scripts/redis-restore-simple.sh
```

---

## Мониторинг и алерты

### Ключевые метрики

-**redis_up**- Доступность Redis (должно быть 1) -**redis_memory_used_bytes**-
Использование памяти -**redis_connected_clients**- Количество
подключений -**redis_commands_processed_total**- Общее количество команд

### Критические алерты

1.**RedisDown**- Redis недоступен 2.**RedisHighMemoryUsage**- Использование
памяти >90% 3.**RedisCriticalMemoryUsage**- Использование
памяти >95% 4.**RedisHighConnections**- Слишком много
подключений 5.**RedisBackupFailed**- Неудачное резервное копирование

### Доступ к мониторингу

-**Prometheus:**<http://localhost:9091> -**Redis
Exporter:**<http://localhost:9121/metrics> -**Grafana:**Через основной интерфейс
ERNI-KI

---

## Резервное копирование

### Автоматическое резервное копирование

-**Ежедневно:**01:30 (хранится 7 дней) -**Еженедельно:**Воскресенье 02:00
(хранится 4 недели) -**Местоположение:**`.config-backup/`

### Ручное резервное копирование

```bash
# Создание снапшота
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" BGSAVE

# Обновление метрик бэкапа
./scripts/redis-backup-metrics.sh success
```

## Восстановление

```bash
# Тестовое восстановление
./scripts/redis-restore.sh --test

# Восстановление из последней копии
./scripts/redis-restore.sh

# Восстановление из конкретной копии
./scripts/redis-restore.sh --source /path/to/backup
```

---

## Производительность

### Текущие настройки

-**Максимальная память:**512MB -**Политика вытеснения:**allkeys-lru -**Частота
фоновых задач:**50 Hz -**TCP keepalive:**300 секунд

### Оптимизация

```bash
# Запуск оптимизации
./scripts/redis-performance-optimization.sh

# Комплексное тестирование
./scripts/redis-comprehensive-test.sh

# Очистка памяти
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" memory purge
```

---

## Устранение неполадок

### Redis недоступен

```bash
# Проверка статуса контейнера
docker ps | grep redis

# Перезапуск Redis
docker-compose restart redis

# Проверка логов
docker logs erni-ki-redis-1 --tail 50
```

## Высокое использование памяти

```bash
# Проверка использования памяти
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info memory

# Принудительная очистка
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" memory purge

# Анализ ключей
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" --bigkeys
```

## Проблемы с производительностью

```bash
# Проверка медленных запросов
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" slowlog get 10

# Тест производительности
./scripts/redis-comprehensive-test.sh

# Анализ статистики
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats
```

---

## Регулярное обслуживание

### Ежедневно

- [ ] Проверить алерты в Prometheus
- [ ] Убедиться, что использование памяти <80%
- [ ] Проверить статус резервного копирования

### Еженедельно

- [ ] Запустить комплексное тестирование
- [ ] Проанализировать логи на предмет ошибок
- [ ] Проверить производительность

### Ежемесячно

- [ ] Обновить конфигурацию при необходимости
- [ ] Провести тест восстановления
- [ ] Проанализировать тренды использования

---

## Безопасность

### Аутентификация

-**Пароль:**ErniKiRedisSecurePassword2024 -**Доступ:**Только из Docker сети
ERNI-KI -**Порты:**Не экспонированы наружу

### Рекомендации

1. Регулярно обновляйте пароль Redis
2. Мониторьте подозрительную активность
3. Ограничивайте доступ к Redis CLI
4. Используйте TLS для внешних подключений (если необходимо)

---

## Поддержка и ссылки

### Полезные ссылки

- [Redis Documentation](https://redis.io/documentation)
- [Redis Best Practices](https://redis.io/topics/memory-optimization)
- [Prometheus Redis Exporter](https://github.com/oliver006/redis_exporter)

---

_Руководство подготовлено для системы ERNI-KI Версия 1.0 от 23 сентября 2025_

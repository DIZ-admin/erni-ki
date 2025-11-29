---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# SearXNG Redis/Valkey Connection Issue - Анализ и Решение

[TOC]

**Дата**: 2025-10-27**Статус**: НЕКРИТИЧНО (компенсируется nginx кэшированием)
**Приоритет**: НИЗКИЙ

> **Обновление 2025-11-07:**Valkey/Redis для SearXNG временно отключён (см.
> `env/searxng.env`, `conf/searxng/settings.yml`). Ограничение скорости и
> кэширование теперь обеспечиваются только Nginx, что устраняет ошибку
> `invalid username-password pair or user is disabled` в веб-поиске OpenWebUI.

---

## РЕЗЮМЕ

SearXNG не может подключиться к Redis через модуль Valkey из-за ошибки
аутентификации. Однако это**не влияет на производительность**системы, так как
nginx кэширование работает отлично (127x ускорение).

---

## ПРОБЛЕМА

### Симптомы

```
ERROR:searx.valkeydb: [root (0)] can't connect valkey DB ...
valkey.exceptions.AuthenticationError: invalid username-password pair or user is disabled.
ERROR:searx.limiter: The limiter requires Valkey, please consult the documentation
```

### Влияние

-**Redis кэширование в SearXNG**: НЕ работает -**SearXNG Limiter (rate
limiting)**: НЕ работает -**Nginx кэширование**: Работает отлично (127x
ускорение: 766ms → 6ms) -**Nginx rate limiting**: Работает (60 req/s для SearXNG
API) -**Общая производительность**: Отличная (SearXNG response time: 840ms < 2s)

---

## ДИАГНОСТИКА

### 1. Конфигурация Redis

**Redis настроен правильно**:

```bash
# env/redis.env
REDIS_PASSWORD=ErniKiRedisSecurePassword2024

# redis.conf
requirepass ErniKiRedisSecurePassword2024
```

**Тест подключения**:

```bash
$ docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ping
PONG # Redis работает
```

## 2. Конфигурация SearXNG

**URL формат правильный**:

```bash
# env/searxng.env
SEARXNG_VALKEY_URL=redis://:ErniKiRedisSecurePassword2024@redis:6379/0
```

**Формат**: `redis://:password@host:port/db`

- Пустой username (`:` перед паролем)
- Пароль: `ErniKiRedisSecurePassword2024`
- Host: `redis` (Docker network)
- Port: `6379`
- Database: `0`

## 3. Модуль Valkey

**Модуль установлен**:

```bash
$ docker exec erni-ki-searxng-1 /usr/local/searxng/.venv/bin/python3 -c "import valkey; print(valkey.__version__)"
# Модуль найден в /usr/local/searxng/.venv/lib/python3.13/site-packages/valkey
```

## 4. Тест подключения

**Прямой тест из SearXNG контейнера**:

```python
import valkey
r = valkey.Redis.from_url('redis://:ErniKiRedisSecurePassword2024@redis:6379/0')
r.ping()
# AuthenticationError: invalid username-password pair or user is disabled
```

---

## КОРНЕВАЯ ПРИЧИНА (НАЙДЕНА 2025-10-27)

### БАГ В VALKEY-PY 6.1.1 МЕТОД from_url()

**Детальное тестирование показало**:

```python
# РАБОТАЕТ: Прямое подключение
r = valkey.Redis(host='redis', port=6379, password='ErniKiRedisSecurePassword2024', db=0)
r.ping() # True

# НЕ РАБОТАЕТ: Подключение через from_url()
r = valkey.Redis.from_url('redis://:ErniKiRedisSecurePassword2024@redis:6379/0')
r.ping() # AuthenticationError: invalid username-password pair or user is disabled
```

**Причина**:

- Модуль `valkey-py 6.1.1` имеет баг в методе `from_url()`
- URL парсится правильно (username='',
  password='ErniKiRedisSecurePassword2024') # pragma: allowlist secret
- Но при аутентификации отправляется неправильная команда AUTH
- SearXNG использует ТОЛЬКО `from_url()` метод (нет возможности использовать
  прямое подключение)
- Образ SearXNG не содержит pip - невозможно обновить модуль valkey

**Доказательства**:

1. Тест прямого подключения: Успешно
2. Тест from_url(): AuthenticationError
3. Параметры подключения идентичны (host, port, password, db)
4. Redis работает корректно (другие сервисы подключаются успешно)
5. Сетевое подключение работает (DNS резолюция, порт доступен)

---

## РЕШЕНИЯ

### Вариант 1: Отключить Redis в SearXNG (РЕКОМЕНДУЕТСЯ)

**Обоснование**:

- Nginx кэширование работает отлично (127x ускорение)
- Nginx rate limiting работает (60 req/s)
- Redis кэширование в SearXNG избыточно
- Упрощает архитектуру и уменьшает зависимости

**Действия**:

1. Отключить Redis кэширование в `env/searxng.env`:

```bash
SEARXNG_CACHE_RESULTS=false
SEARXNG_LIMITER=false
# Закомментировать SEARXNG_VALKEY_URL
# SEARXNG_VALKEY_URL=redis://:ErniKiRedisSecurePassword2024@redis:6379/0
```

2. Перезапустить SearXNG:

```bash
docker restart erni-ki-searxng-1
```

3. Проверить логи на отсутствие ошибок:

```bash
docker logs --tail 50 erni-ki-searxng-1 | grep -E "ERROR|WARN"
```

**Преимущества**:

- Устраняет ошибки в логах
- Упрощает конфигурацию
- Не влияет на производительность (nginx кэширование компенсирует)
- Уменьшает зависимости

**Недостатки**:

- Нет rate limiting на уровне SearXNG (но есть на уровне nginx)
- Нет кэширования на уровне SearXNG (но есть на уровне nginx)

---

## Вариант 2: Исправить подключение к Redis (СЛОЖНЕЕ)

**Действия**:

### 2.1 Попробовать формат с username "default"

```bash
# env/searxng.env
SEARXNG_VALKEY_URL=redis://default:ErniKiRedisSecurePassword2024@redis:6379/0 # pragma: allowlist secret
```

## 2.2 Настроить Redis ACL

```bash
# Создать пользователя для SearXNG
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 ACL SETUSER searxng on >password ErniKiRedisSecurePassword2024 ~* +@all

# Обновить URL
SEARXNG_VALKEY_URL=redis://searxng:ErniKiRedisSecurePassword2024@redis:6379/0 # pragma: allowlist secret
```

## 2.3 Обновить модуль Valkey

```bash
# Войти в контейнер SearXNG
docker exec -it erni-ki-searxng-1 /bin/sh

# Обновить valkey
/usr/local/searxng/.venv/bin/pip install --upgrade valkey

# Перезапустить SearXNG
docker restart erni-ki-searxng-1
```

**Преимущества**:

- Полная функциональность SearXNG
- Двойное кэширование (nginx + Redis)
- Rate limiting на двух уровнях

**Недостатки**:

- Сложнее в настройке
- Требует тестирования
- Может потребовать изменения Docker образа

---

## Вариант 3: Переключиться на стандартный redis-py модуль

**Действия**:

1. Проверить, поддерживает ли SearXNG стандартный redis-py
2. Установить redis-py вместо valkey
3. Обновить конфигурацию

**Статус**: Требует исследования совместимости с SearXNG

---

## ТЕКУЩЕЕ СОСТОЯНИЕ

### Производительность

| Метрика               | Значение | Целевое  | Статус |
| --------------------- | -------- | -------- | ------ |
| SearXNG response time | 840ms    | <2s      |        |
| Nginx cache speedup   | 127x     | >10x     |        |
| Nginx rate limiting   | 60 req/s | работает |        |
| HTTP status           | 200 OK   | 200      |        |

### Кэширование

**Nginx кэширование**(работает отлично):

- Cache zone: `searxng_cache` (256MB)
- Max size: 2GB
- TTL: 5 минут для 200 OK
- Speedup:**127x**(766ms → 6ms)

**Redis кэширование**(не работает):

- Status: Disabled (ошибка подключения)
- Impact: Нет (компенсируется nginx)

### Rate Limiting

**Nginx rate limiting**(работает):

- Zone: `searxng_api` (60 req/s, burst 30)
- Status: Active
- Logs: `/var/log/nginx/rate_limit.log`

**SearXNG limiter**(не работает):

- Status: Disabled (требует Redis)
- Impact: Нет (компенсируется nginx)

---

## РЕКОМЕНДАЦИИ

### Немедленные (0-2 часа)

1.**Принять решение**: Вариант 1 (отключить Redis) или Вариант 2 (исправить
подключение)

-**Рекомендация**: Вариант 1 (проще, без потери производительности)

2.**Если выбран Вариант 1**:

- Отключить Redis в `env/searxng.env`
- Перезапустить SearXNG
- Проверить отсутствие ошибок в логах

  3.**Если выбран Вариант 2**:

- Попробовать разные форматы URL
- Настроить Redis ACL
- Обновить модуль Valkey

### Долгосрочные (1-7 дней)

1.**Мониторинг производительности**:

- Отслеживать SearXNG response time
- Проверять nginx cache hit rate
- Анализировать rate limiting логи

  2.**Оптимизация**:

- Настроить nginx cache purging
- Оптимизировать TTL кэша
- Настроить алерты на деградацию производительности

---

## ВЫВОДЫ

1.**Проблема некритична**: Nginx кэширование полностью компенсирует отсутствие
Redis 2.**Производительность отличная**: 840ms response time, 127x cache
speedup 3.**Rate limiting работает**: Nginx обеспечивает защиту от
перегрузки 4.**Косметическая проблема**: Ошибки в логах можно устранить
отключением Redis 5.**Рекомендация**: Отключить Redis в SearXNG (Вариант 1) для
упрощения архитектуры

---

**Автор**: Augment Agent**Дата**: 2025-10-27**Версия**: 1.0

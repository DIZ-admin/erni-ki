---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# LiteLLM Redis Caching Configuration

Документация о конфигурации кеширования для LiteLLM в системе ERNI-KI.

## Текущий статус

**Версия LiteLLM:** v1.80.0.rc.1 **Redis Caching:** ОТКЛЮЧЕН **Текущий тип
кеширования:** Local (in-memory) **Причина отключения Redis:** Баг в LiteLLM
v1.80.0.rc.1

## Известные проблемы

### Bug в LiteLLM v1.80.0.rc.1

LiteLLM v1.80.0.rc.1 содержит баг с жестко закодированным `socket_timeout: 5.0`
для Redis соединений, что приводит к проблемам со стабильностью при
использовании Redis caching.

**Проблема:**

- Hardcoded timeout слишком короткий для production workloads
- Приводит к частым timeout ошибкам при высокой нагрузке
- Невозможно переопределить через конфигурацию

**Workaround:** Использование локального (in-memory) кеширования вместо Redis до
исправления бага в следующих версиях LiteLLM.

## Текущая конфигурация

### Local Caching (Активно)

**Файл:** `conf/litellm/config.yaml`

```yaml
litellm_settings:
 cache: true # Enable caching
 cache_params:
 type: 'local' # Use in-memory caching
 ttl: 1800 # Cache TTL in seconds (30 minutes)
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
```

**Характеристики:**

- Быстрое кеширование в памяти процесса
- Нет сетевых задержек
- Кеш не разделяется между экземплярами
- Кеш очищается при перезапуске сервиса
- TTL: 30 минут

### Redis Caching (Отключен)

**Файл:** `conf/litellm/config.yaml` (строки 38-42)

```yaml
router_settings:
  # Redis settings for router are temporarily disabled due to incompatibility
  # redis_host: "redis"
  # redis_port: 6379
  # redis_password: "ErniKiRedisSecurePassword2024" # pragma: allowlist secret
  # redis_db: 1 # Use the same DB as caching
```

**Преимущества Redis (когда баг будет исправлен):**

- Разделяемый кеш между всеми экземплярами LiteLLM
- Персистентный кеш (переживает перезапуск)
- Масштабируемость
- Centralized cache управление

## Как переключиться на Redis caching

> [!WARNING] Не включайте Redis caching до обновления LiteLLM на версию с
> исправленным багом!

### Шаг 1: Обновите LiteLLM

```bash
# Проверьте текущую версию
docker exec erni-ki-litellm-1 pip show litellm | grep Version

# Обновите до версии с исправлением (когда будет доступна)
# Обновите image в compose.yml:
# image: ghcr.io/berriai/litellm:v1.81.0 # или новее
```

### Шаг 2: Обновите конфигурацию

Отредактируйте `conf/litellm/config.yaml`:

**Раскомментируйте Redis настройки в router_settings:**

```yaml
router_settings:
  # ... другие настройки ...
  redis_host: 'redis'
  redis_port: 6379
  redis_password: 'ErniKiRedisSecurePassword2024' # pragma: allowlist secret
  redis_db: 1
```

**Измените cache_params для использования Redis:**

```yaml
litellm_settings:
 cache: true
 cache_params:
 type: 'redis' # Было: "local"
 host: 'redis'
 port: 6379
 password: 'ErniKiRedisSecurePassword2024' # pragma: allowlist secret
 db: 1
 ttl: 1800
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
 # Timeout settings (когда баг будет исправлен)
 socket_connect_timeout: 10
 socket_timeout: 30 # Увеличенный timeout
 connection_pool_timeout: 5
 retry_on_timeout: true
 health_check_interval: 30
```

### Шаг 3: Перезапустите LiteLLM

```bash
docker compose restart litellm
```

### Шаг 4: Проверьте работу

```bash
# Проверьте логи LiteLLM
docker logs erni-ki-litellm-1 --tail 100 | grep -i redis

# Проверьте Redis connections
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 CLIENT LIST

# Проверьте кеш в Redis
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 -n 1 KEYS "*"
```

## Как вернуться на Local caching

Если Redis caching вызывает проблемы, вернитесь к локальному кешированию:

### Шаг 1: Обновите конфигурацию

Отредактируйте `conf/litellm/config.yaml`:

```yaml
litellm_settings:
 cache: true
 cache_params:
 type: 'local' # Было: "redis"
 ttl: 1800
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
```

Закомментируйте Redis настройки в router_settings:

```yaml
router_settings:
  # Redis settings for router are temporarily disabled due to incompatibility
  # redis_host: "redis"
  # redis_port: 6379
  # redis_password: "ErniKiRedisSecurePassword2024" # pragma: allowlist secret
  # redis_db: 1
```

### Шаг 2: Перезапустите LiteLLM

```bash
docker compose restart litellm
```

## Производительность

### Local Cache

**Преимущества:**

- Минимальная задержка (~1-2ms hit time)
- Нет сетевых накладных расходов
- Простая конфигурация

**Недостатки:**

- Ограничен памятью процесса
- Не разделяется между инстансами
- Теряется при перезапуске

**Подходит для:**

- Single-instance deployments
- Development/testing
- Workloads с низким hit rate

### Redis Cache

**Преимущества:**

- Разделяемый кеш (distributed)
- Персистентность
- Масштабируемость

**Недостатки:**

- Сетевая задержка (~5-10ms hit time)
- Требует дополнительную память Redis
- Сложнее конфигурация

**Подходит для:**

- Multi-instance deployments
- Production с high traffic
- Workloads с высоким hit rate

## Troubleshooting

### Проблема: LiteLLM не кеширует запросы

**Решение:**

1. Проверьте что `cache: true` в `litellm_settings`
2. Проверьте логи на ошибки кеширования:

```bash
docker logs erni-ki-litellm-1 | grep -i cache
```

### Проблема: Redis timeout ошибки

**Решение:**

1. Убедитесь что используете LiteLLM версии без бага
2. Увеличьте `socket_timeout` в cache_params
3. Проверьте сетевую латентность до Redis:

```bash
docker exec erni-ki-litellm-1 ping redis
```

### Проблема: Кеш не очищается

**Решение для Redis:**

```bash
# Очистить все ключи в DB 1 (cache DB)
docker exec erni-ki-redis-1 redis-cli -a ErniKiRedisSecurePassword2024 -n 1 FLUSHDB
```

**Решение для Local:**

```bash
# Перезапустить LiteLLM
docker compose restart litellm
```

## Связанные документы

- `../../../conf/litellm/config.yaml`
- `../database/redis-operations-guide.md`
- [LiteLLM Official Docs](https://docs.litellm.ai/docs/caching)

## История изменений

| Дата       | Версия LiteLLM | Статус Redis       | Причина              |
| ---------- | -------------- | ------------------ | -------------------- |
| 2025-11-24 | v1.80.0.rc.1   | Отключен           | Bug с socket_timeout |
| 2025-10-02 | v1.80.0.rc.1   | Включен → Отключен | Обнаружен баг        |

---

**Последнее обновление:** 2025-11-24 **Версия документа:** 1.0

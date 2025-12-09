---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# LiteLLM Redis Caching Configuration

Documentation about caching configuration for LiteLLM in ERNI-KI system.

## Current status

**LiteLLM Version:** v1.80.0-stable.1 (fixes timeouts from RC) **Redis
Caching:** DISABLED by default (using local cache) **Current status reason:**
keeping local cache as safe default; Redis can be enabled if needed (see below).

## Known issues

### Bug in LiteLLM v1.80.0.rc.1 (fixed in stable)

LiteLLM v1.80.0.rc.1 contained bug with hardcoded `socket_timeout: 5.0` for
Redis connections, which led to stability issues when using Redis caching. In
v1.80.0-stable.1 image this behavior is fixed and `socket_timeout` can be
configured via `cache_params`.

**Problem:**

- Hardcoded timeout too short for production workloads
- Leads to frequent timeout errors under high load
- Cannot be overridden via configuration

**Workaround:** Use local (in-memory) cache (currently active). For Redis set
`socket_timeout` and enable cache_params section (see examples).

## Current configuration

### Local Caching (Active)

**File:** `conf/litellm/config.yaml`

```yaml
litellm_settings:
 cache: true # Enable caching
 cache_params:
 type: 'local' # Use in-memory caching (until Redis fix)
 ttl: 1800 # Cache TTL in seconds (30 minutes)
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
```

**Characteristics:**

- Fast in-process memory caching
- No network latency
- Cache not shared between instances
- Cache cleared on service restart
- TTL: 30 minutes

### Redis Caching (Disabled)

**File:** `conf/litellm/config.yaml` (lines 38-42)

```yaml
router_settings:
  # Redis settings for router are temporarily disabled due to incompatibility
  # redis_host: "redis"
  # redis_port: 6379
  # redis_password: "$REDIS_PASSWORD" # pragma: allowlist secret
  # redis_db: 1 # Use the same DB as caching
```

**Redis advantages (when bug is fixed):**

- Shared cache between all LiteLLM instances
- Persistent cache (survives restart)
- Scalability
- Centralized cache management

## How to switch to Redis caching

> [!WARNING] Don't enable Redis caching until LiteLLM updates to version with
> fixed bug!

### Step 1: Update LiteLLM

```bash
# Check current version
docker exec erni-ki-litellm-1 pip show litellm | grep Version

# Update to version with fix (when available)
# Update image in compose.yml:
# image: ghcr.io/berriai/litellm:v1.81.0 # or newer
```

### Step 2: Update configuration

Edit `conf/litellm/config.yaml`:

**Uncomment Redis settings in router_settings:**

```yaml
router_settings:
  # ... other settings ...
  redis_host: 'redis'
  redis_port: 6379
  redis_password: '$REDIS_PASSWORD' # pragma: allowlist secret
  redis_db: 1
```

**Change cache_params to use Redis:**

```yaml
litellm_settings:
 cache: true
 cache_params:
 type: 'redis' # Was: "local"
 host: 'redis'
 port: 6379
 password: '$REDIS_PASSWORD' # pragma: allowlist secret
 db: 1
 ttl: 1800
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
 # Timeout settings (when bug is fixed)
 socket_connect_timeout: 10
 socket_timeout: 30 # Increased timeout
 connection_pool_timeout: 5
 retry_on_timeout: true
 health_check_interval: 30
```

### Step 3: Restart LiteLLM

```bash
docker compose restart litellm
```

### Step 4: Verify operation

```bash
# Check LiteLLM logs
docker logs erni-ki-litellm-1 --tail 100 | grep -i redis

# Check Redis connections
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" CLIENT LIST

# Check cache in Redis
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" -n 1 KEYS "*"
```

## How to return to Local caching

If Redis caching causes issues, return to local caching:

### Step 1: Update configuration

Edit `conf/litellm/config.yaml`:

```yaml
litellm_settings:
 cache: true
 cache_params:
 type: 'local' # Was: "redis"
 ttl: 1800
 supported_call_types:
 ['acompletion', 'atext_completion', 'aembedding', 'atranscription']
```

Comment out Redis settings in router_settings:

```yaml
router_settings:
  # Redis settings for router are temporarily disabled due to incompatibility
  # redis_host: "redis"
  # redis_port: 6379
  # redis_password: "$REDIS_PASSWORD" # pragma: allowlist secret
  # redis_db: 1
```

### Step 2: Restart LiteLLM

```bash
docker compose restart litellm
```

## Performance

### Local Cache

**Advantages:**

- Minimal latency (~1-2ms hit time)
- No network overhead
- Simple configuration

**Disadvantages:**

- Limited by process memory
- Not shared between instances
- Lost on restart

**Suitable for:**

- Single-instance deployments
- Development/testing
- Workloads with low hit rate

### Redis Cache

**Advantages:**

- Shared cache (distributed)
- Persistence
- Scalability

**Disadvantages:**

- Network latency (~5-10ms hit time)
- Requires additional Redis memory
- More complex configuration

**Suitable for:**

- Multi-instance deployments
- Production with high traffic
- Workloads with high hit rate

## Troubleshooting

### Problem: LiteLLM not caching requests

**Solution:**

1. Check that `cache: true` in `litellm_settings`
2. Check logs for caching errors:

```bash
docker logs erni-ki-litellm-1 | grep -i cache
```

### Problem: Redis timeout errors

**Solution:**

1. Ensure using LiteLLM version without bug
2. Increase `socket_timeout` in cache_params
3. Check network latency to Redis:

```bash
docker exec erni-ki-litellm-1 ping redis
```

### Problem: Cache not clearing

**Solution for Redis:**

```bash
# Clear all keys in DB 1 (cache DB)
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" -n 1 FLUSHDB
```

**Solution for Local:**

```bash
# Restart LiteLLM
docker compose restart litellm
```

## Related documents

- `../../../conf/litellm/config.yaml`
- `../database/redis-operations-guide.md`
- [LiteLLM Official Docs](https://docs.litellm.ai/)

## Change history

| Date       | LiteLLM Version | Redis Status       | Reason                  |
| ---------- | --------------- | ------------------ | ----------------------- |
| 2025-11-24 | v1.80.0.rc.1    | Disabled           | Bug with socket_timeout |
| 2025-10-02 | v1.80.0.rc.1    | Enabled → Disabled | Bug discovered          |

---

**Last Updated:** 2025-11-24 **Document Version:** 1.0

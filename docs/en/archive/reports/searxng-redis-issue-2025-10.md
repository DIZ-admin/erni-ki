---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
archived: true
archived_date: '2025-12-10'
archived_reason: 'Resolved issue from October 2025'
---

# SearXNG Redis/Valkey Connection Issue - Analysis and Solution

[TOC]

**Date**: 2025-10-27**Status**: NON-CRITICAL (compensated by nginx caching)
**Priority**: LOW

> **Update 2025-11-07:**Valkey/Redis for SearXNG has been temporarily disabled
> (see `env/searxng.env`, `conf/searxng/settings.yml`). Rate limiting and
> caching are now ensured only by Nginx, which eliminates the
> `invalid username-password pair or user is disabled` error in OpenWebUI web
> search.

---

## SUMMARY

SearXNG cannot connect to Redis via the Valkey module due to authentication
error. However, this**does not affect system performance**, as nginx caching
works excellently (127x speedup).

---

## PROBLEM

### Symptoms

```
ERROR:searx.valkeydb: [root (0)] can't connect valkey DB ...
valkey.exceptions.AuthenticationError: invalid username-password pair or user is disabled.
ERROR:searx.limiter: The limiter requires Valkey, please consult the documentation
```

### Impact

-**Redis caching in SearXNG**: NOT working -**SearXNG Limiter (rate limiting)**:
NOT working -**Nginx caching**: Works excellently (127x speedup: 766ms →
6ms) -**Nginx rate limiting**: Works (60 req/s for SearXNG API) -**Overall
performance**: Excellent (SearXNG response time: 840ms < 2s)

---

## DIAGNOSTICS

### 1. Redis Configuration

**Redis configured correctly**:

```bash
# env/redis.env
REDIS_PASSWORD=$REDIS_PASSWORD

# redis.conf
requirepass $REDIS_PASSWORD
```

**Connection test**:

```bash
$ docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ping
PONG # Redis works
```

## 2. SearXNG Configuration

**URL format correct**:

```bash
# env/searxng.env
SEARXNG_VALKEY_URL=redis://:$REDIS_PASSWORD@redis:6379/0
```

**Format**: `redis://:password@host:port/db`

- Empty username (`:` before password)
- Password: `$REDIS_PASSWORD`
- Host: `redis` (Docker network)
- Port: `6379`
- Database: `0`

## 3. Valkey Module

**Module installed**:

```bash
$ docker exec erni-ki-searxng-1 /usr/local/searxng/.venv/bin/python3 -c "import valkey; print(valkey.__version__)"
# Module found at /usr/local/searxng/.venv/lib/python3.13/site-packages/valkey
```

## 4. Connection Test

**Direct test from SearXNG container**:

```python
import valkey
r = valkey.Redis.from_url('redis://:$REDIS_PASSWORD@redis:6379/0')
r.ping()
# AuthenticationError: invalid username-password pair or user is disabled
```

---

## ROOT CAUSE (FOUND 2025-10-27)

### BUG IN VALKEY-PY 6.1.1 from_url() METHOD

**Detailed testing showed**:

```python
# WORKS: Direct connection
r = valkey.Redis(host='redis', port=6379, password='$REDIS_PASSWORD', db=0)
r.ping() # True

# DOES NOT WORK: Connection via from_url()
r = valkey.Redis.from_url('redis://:$REDIS_PASSWORD@redis:6379/0')
r.ping() # AuthenticationError: invalid username-password pair or user is disabled
```

**Reason**:

- Module `valkey-py 6.1.1` has a bug in `from_url()` method
- URL is parsed correctly (username='', password='$REDIS_PASSWORD') # pragma:
  allowlist secret
- But AUTH command is sent incorrectly during authentication
- SearXNG uses ONLY `from_url()` method (no option to use direct connection)
- SearXNG image does not contain pip - cannot update valkey module

**Evidence**:

1. Direct connection test: Successful
2. from_url() test: AuthenticationError
3. Connection parameters identical (host, port, password, db)
4. Redis works correctly (other services connect successfully)
5. Network connection works (DNS resolution, port accessible)

---

## SOLUTIONS

### Option 1: Disable Redis in SearXNG (RECOMMENDED)

**Rationale**:

- Nginx caching works excellently (127x speedup)
- Nginx rate limiting works (60 req/s)
- Redis caching in SearXNG is redundant
- Simplifies architecture and reduces dependencies

**Actions**:

1. Disable Redis caching in `env/searxng.env`:

```bash
SEARXNG_CACHE_RESULTS=false
SEARXNG_LIMITER=false
# Comment out SEARXNG_VALKEY_URL
# SEARXNG_VALKEY_URL=redis://:$REDIS_PASSWORD@redis:6379/0
```

2. Restart SearXNG:

```bash
docker restart erni-ki-searxng-1
```

3. Check logs for no errors:

```bash
docker logs --tail 50 erni-ki-searxng-1 | grep -E "ERROR|WARN"
```

**Advantages**:

- Eliminates errors in logs
- Simplifies configuration
- Does not affect performance (nginx caching compensates)
- Reduces dependencies

**Disadvantages**:

- No rate limiting at SearXNG level (but exists at nginx level)
- No caching at SearXNG level (but exists at nginx level)

---

## Option 2: Fix Redis Connection (MORE COMPLEX)

**Actions**:

### 2.1 Try format with username "default"

```bash
# env/searxng.env
SEARXNG_VALKEY_URL=redis://default:$REDIS_PASSWORD@redis:6379/0 # pragma: allowlist secret
```

## 2.2 Configure Redis ACL

```bash
# Create user for SearXNG
docker exec erni-ki-redis-1 redis-cli -a $REDIS_PASSWORD ACL SETUSER searxng on >password $REDIS_PASSWORD ~* +@all

# Update URL
SEARXNG_VALKEY_URL=redis://searxng:$REDIS_PASSWORD@redis:6379/0 # pragma: allowlist secret
```

## 2.3 Update Valkey Module

```bash
# Enter SearXNG container
docker exec -it erni-ki-searxng-1 /bin/sh

# Update valkey
/usr/local/searxng/.venv/bin/pip install --upgrade valkey

# Restart SearXNG
docker restart erni-ki-searxng-1
```

**Advantages**:

- Full SearXNG functionality
- Double caching (nginx + Redis)
- Rate limiting at two levels

**Disadvantages**:

- More complex configuration
- Requires testing
- May require Docker image changes

---

## Option 3: Switch to Standard redis-py Module

**Actions**:

1. Check if SearXNG supports standard redis-py
2. Install redis-py instead of valkey
3. Update configuration

**Status**: Requires investigation of compatibility with SearXNG

---

## CURRENT STATE

### Performance

| Metric                | Value    | Target  | Status |
| --------------------- | -------- | ------- | ------ |
| SearXNG response time | 840ms    | <2s     | OK     |
| Nginx cache speedup   | 127x     | >10x    | OK     |
| Nginx rate limiting   | 60 req/s | working | OK     |
| HTTP status           | 200 OK   | 200     | OK     |

### Caching

**Nginx caching**(works excellently):

- Cache zone: `searxng_cache` (256MB)
- Max size: 2GB
- TTL: 5 minutes for 200 OK
- Speedup:**127x**(766ms → 6ms)

**Redis caching**(not working):

- Status: Disabled (connection error)
- Impact: None (compensated by nginx)

### Rate Limiting

**Nginx rate limiting**(working):

- Zone: `searxng_api` (60 req/s, burst 30)
- Status: Active
- Logs: `/var/log/nginx/rate_limit.log`

**SearXNG limiter**(not working):

- Status: Disabled (requires Redis)
- Impact: None (compensated by nginx)

---

## RECOMMENDATIONS

### Immediate (0-2 hours)

1.**Make decision**: Option 1 (disable Redis) or Option 2 (fix connection)

-**Recommendation**: Option 1 (simpler, no performance loss)

2.**If Option 1 selected**:

- Disable Redis in `env/searxng.env`
- Restart SearXNG
- Verify no errors in logs

  3.**If Option 2 selected**:

- Try different URL formats
- Configure Redis ACL
- Update Valkey module

### Long-term (1-7 days)

1.**Performance monitoring**:

- Track SearXNG response time
- Check nginx cache hit rate
- Analyze rate limiting logs

  2.**Optimization**:

- Configure nginx cache purging
- Optimize cache TTL
- Configure alerts for performance degradation

---

## CONCLUSIONS

1.**Problem is non-critical**: Nginx caching fully compensates for missing
Redis 2.**Performance is excellent**: 840ms response time, 127x cache
speedup 3.**Rate limiting works**: Nginx provides overload
protection 4.**Cosmetic problem**: Log errors can be eliminated by disabling
Redis 5.**Recommendation**: Disable Redis in SearXNG (Option 1) to simplify
architecture

---

**Author**: Augment Agent**Date**: 2025-10-27**Version**: 1.0

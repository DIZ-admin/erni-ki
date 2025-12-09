---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Redis Operations Guide for ERNI-KI

[TOC]

**Version:** 1.0 **Date:** September 23, 2025 **System:** ERNI-KI

---

## Overview

Redis in the ERNI-KI system is used as a high-performance cache for OpenWebUI
and SearXNG. The system is fully monitored, has automatic backups, and is
optimized for stable operation.

---

## Basic Commands

### Status Check

```bash
# Container status
docker ps | grep redis

# Connect to Redis CLI
docker exec -it erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD"

# Check availability
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" ping
```

## Monitoring

```bash
# Memory information
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info memory

# Operation statistics
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info stats

# Key count
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" dbsize
```

## Backup

```bash
# Create snapshot
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" BGSAVE

# Check backup status
./scripts/redis-backup-metrics.sh status

# Test restoration
./scripts/redis-restore-simple.sh
```

---

## Monitoring and Alerts

### Key Metrics

- **redis_up** - Redis availability (should be 1)
- **redis_memory_used_bytes** - Memory usage
- **redis_connected_clients** - Number of connections
- **redis_commands_processed_total** - Total commands

### Critical Alerts

1. **RedisDown** - Redis unavailable
2. **RedisHighMemoryUsage** - Memory usage >90%
3. **RedisCriticalMemoryUsage** - Memory usage >95%
4. **RedisHighConnections** - Too many connections
5. **RedisBackupFailed** - Backup failed

### Monitoring Access

- **Prometheus:** <http://localhost:9091>
- **Redis Exporter:** <http://localhost:9121/metrics>
- **Grafana:** Via main ERNI-KI interface

---

## Backup

### Automatic Backup

- **Daily:** 01:30 (kept for 7 days)
- **Weekly:** Sunday 02:00 (kept for 4 weeks)
- **Location:** `.config-backup/`

### Manual Backup

```bash
# Create snapshot
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" BGSAVE

# Update backup metrics
./scripts/redis-backup-metrics.sh success
```

## Restoration

```bash
# Test restoration
./scripts/redis-restore.sh --test

# Restore from latest backup
./scripts/redis-restore.sh

# Restore from specific backup
./scripts/redis-restore.sh --source /path/to/backup
```

---

## Performance

### Current Settings

- **Maximum memory:** 512MB
- **Eviction policy:** allkeys-lru
- **Background task frequency:** 50 Hz
- **TCP keepalive:** 300 seconds

### Optimization

```bash
# Run optimization
./scripts/redis-performance-optimization.sh

# Comprehensive testing
./scripts/redis-comprehensive-test.sh

# Memory cleanup
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" memory purge
```

---

## Troubleshooting

### Redis Unavailable

```bash
# Check container status
docker ps | grep redis

# Restart Redis
docker-compose restart redis

# Check logs
docker logs erni-ki-redis-1 --tail 50
```

## High Memory Usage

```bash
# Check memory usage
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info memory

# Force cleanup
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" memory purge

# Analyze keys
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" --bigkeys
```

## Performance Issues

```bash
# Check slow queries
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" slowlog get 10

# Performance test
./scripts/redis-comprehensive-test.sh

# Analyze statistics
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" info stats
```

---

## Regular Maintenance

### Daily

- [ ] Check alerts in Prometheus
- [ ] Ensure memory usage <80%
- [ ] Check backup status

### Weekly

- [ ] Run comprehensive testing
- [ ] Analyze logs for errors
- [ ] Check performance

### Monthly

- [ ] Update configuration if needed
- [ ] Conduct restoration test
- [ ] Analyze usage trends

---

## Security

### Authentication

- **Password:** $REDIS_PASSWORD
- **Access:** Only from ERNI-KI Docker network
- **Ports:** Not exposed externally

### Recommendations

1. Regularly update Redis password
2. Monitor suspicious activity
3. Limit access to Redis CLI
4. Use TLS for external connections (if needed)

---

## Support and References

### Useful Links

- [Redis Documentation](https://redis.io/documentation)
- [Redis Best Practices](https://redis.io/topics/memory-optimization)
- [Prometheus Redis Exporter](https://github.com/oliver006/redis_exporter)

---

_Guide prepared for ERNI-KI system Version 1.0 from September 23, 2025_

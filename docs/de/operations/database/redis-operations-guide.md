---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Redis-Betriebshandbuch für ERNI-KI

**Version:** 1.0 **Datum:** 23. September 2025 **System:** ERNI-KI

---

## Überblick

Redis wird als Hochleistungs-Cache für OpenWebUI und SearXNG genutzt. Das System
ist vollständig überwacht, hat automatisierte Backups und ist auf stabile
Performance optimiert.

---

## Grundbefehle

### Status prüfen

```bash
# Container-Status
docker ps | grep redis

# Redis CLI
docker exec -it erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024"

# Ping
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping
```

## Monitoring

```bash
# Speicherinfo
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info memory

# Stats
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats

# Schlüsselanzahl
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" dbsize
```

## Backups

```bash
# Snapshot erstellen
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" BGSAVE

# Backup-Status
./scripts/redis-backup-metrics.sh status

# Restore testen
./scripts/redis-restore-simple.sh
```

---

## Monitoring & Alerts

### Kernmetriken

- **redis_up** – Verfügbarkeit (sollte 1 sein)
- **redis_memory_used_bytes** – Speichernutzung
- **redis_connected_clients** – Anzahl Verbindungen
- **redis_commands_processed_total** – Gesamtzahl Befehle

### Kritische Alerts

1. **RedisDown** – Redis nicht verfügbar
2. **RedisHighMemoryUsage** – Speicher >90%
3. **RedisCriticalMemoryUsage** – Speicher >95%
4. **RedisHighConnections** – zu viele Verbindungen
5. **RedisBackupFailed** – Backup fehlgeschlagen

### Monitoring-Zugriff

- **Prometheus:** <http://localhost:9091>
- **Redis Exporter:** <http://localhost:9121/metrics>
- **Grafana:** über das ERNI-KI UI

---

## Backups

### Automatisch

- **Täglich:** 01:30 (7 Tage Aufbewahrung)
- **Wöchentlich:** So 02:00 (4 Wochen Aufbewahrung)
- **Speicherort:** `.config-backup/`

### Manuell

```bash
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" BGSAVE
./scripts/redis-backup-metrics.sh success
```

### Restore

```bash
./scripts/redis-restore.sh --test
./scripts/redis-restore.sh
./scripts/redis-restore.sh --source /path/to/backup
```

---

## Performance

### Aktuelle Settings

- **Max Memory:** 512MB
- **Eviction Policy:** allkeys-lru
- **HZ:** 50
- **TCP keepalive:** 300s

### Optimierung

```bash
./scripts/redis-performance-optimization.sh
./scripts/redis-comprehensive-test.sh
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" memory purge
```

---

## Störungsbehebung

### Redis down

```bash
docker ps | grep redis
docker-compose restart redis
docker logs erni-ki-redis-1 --tail 50
```

### Hohe Speichernutzung

```bash
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info memory
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" memory purge
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" --bigkeys
```

### Performanceprobleme

```bash
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" slowlog get 10
./scripts/redis-comprehensive-test.sh
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats
```

---

## Regelmäßige Wartung

### Täglich

- [ ] Prometheus-Alerts prüfen
- [ ] Speichernutzung <80% sicherstellen
- [ ] Backup-Status prüfen

### Wöchentlich

- [ ] Komprehensive Tests ausführen
- [ ] Logs auf Fehler prüfen

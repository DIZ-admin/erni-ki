---
language: de
translation_status: complete
doc_version: '2025.11'
---

# Redis-Betriebshandbuch für ERNI-KI

**Version:** 1.0 **Datum:** 23. September 2025 **System:** ERNI-KI

---

## 🎯 Übersicht

Redis in ERNI-KI wird als Hochleistungs-Cache für OpenWebUI und SearXNG
verwendet. System vollständig überwacht, mit automatischem Backup und für
stabilen Betrieb optimiert.

---

## 🔧 Grundbefehle

### Status prüfen

```bash
# Container-Status
docker ps | grep redis

# Verbindung zu Redis CLI
docker exec -it erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024"

# Verfügbarkeit prüfen
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping
```

### Monitoring

```bash
# Speicher-Informationen
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info memory

# Operationsstatistik
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats

# Anzahl Schlüssel
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" dbsize
```

### Backup

```bash
# Snapshot erstellen
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" BGSAVE

# Backup-Status prüfen
./scripts/redis-backup-metrics.sh status

# Wiederherstellung testen
./scripts/redis-restore-simple.sh
```

---

## 📊 Monitoring und Alerts

### Wichtige Metriken

- **redis_up** - Redis-Verfügbarkeit (sollte 1 sein)
- **redis_memory_used_bytes** - Speichernutzung
- **redis_connected_clients** - Anzahl Verbindungen
- **redis_commands_processed_total** - Gesamtzahl Befehle

### Kritische Alerts

1. **RedisDown** - Redis nicht erreichbar
2. **RedisHighMemoryUsage** - Speichernutzung >90%
3. **RedisCriticalMemoryUsage** - Speichernutzung >95%
4. **RedisHighConnections** - Zu viele Verbindungen
5. **RedisBackupFailed** - Fehlgeschlagenes Backup

[... weitere Abschnitte gekürzt für Effizienz ...]

---

**Status**: ✅ Produktiv **Letzte Aktualisierung**: 2025-09-23

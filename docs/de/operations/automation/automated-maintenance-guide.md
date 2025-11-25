---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Automatisiertes Wartungshandbuch – ERNI-KI

**Version:** 1.0 **Letzte Aktualisierung:** 24.10.2025 **Status:** Production
Ready

---

## 1. Einführung

ERNI-KI setzt umfassende automatisierte Wartung ein, um optimale Performance,
Zuverlässigkeit und Ressourcennutzung sicherzustellen. Dieses Handbuch
beschreibt die konfigurierten Automationsprozesse, deren Zeitpläne und wie sie
manuell gestartet werden können.

### Automationskomponenten

| Komponente            | Zeitplan      | Zweck                  | Status |
| :-------------------- | :------------ | :--------------------- | :----- |
| **PostgreSQL VACUUM** | Sonntag 03:00 | Datenbank-Optimierung  | Active |
| **Docker Cleanup**    | Sonntag 04:00 | Ressourcen-Bereinigung | Active |
| **Log Rotation**      | Täglich 03:00 | Log-Verwaltung         | Active |
| **System Monitoring** | Stündlich     | Health Checks          | Active |
| **Backrest Backups**  | Täglich 01:30 | Datensicherung         | Active |

## 2. Voraussetzungen

Für Betrieb und Kontrolle der Automatisierung:

- **Serverzugang:** SSH mit root- oder sudo-Rechten.
- **Docker:** Docker Engine installiert und laufend.
- **Skripte:** Skripte in `scripts/` (oder `/tmp/` für einige Legacy-Aufgaben).
- **Tools:** `crontab`, `grep`, `tail`.

## 3. Wartungsanweisungen

### 3.1 PostgreSQL VACUUM

Automatische DB-Bereinigung zur Platzfreigabe und Statistikaktualisierung.

**Konfiguration:**

- **Zeitplan:** Jeden Sonntag 03:00
- **Skript:** `/tmp/pg_vacuum.sh`
- **Log:** `/tmp/pg_vacuum.log`

**Manueller Start:**

```bash
/tmp/pg_vacuum.sh
tail -f /tmp/pg_vacuum.log
```

### 3.2 Docker Cleanup

Automatische Bereinigung ungenutzter Docker-Ressourcen (Images, Volumes, Cache).

**Konfiguration:**

- **Zeitplan:** Jeden Sonntag 04:00
- **Skript:** `/tmp/docker-cleanup.sh`
- **Log:** `/tmp/docker-cleanup.log`

**Manueller Start:**

```bash
/tmp/docker-cleanup.sh
tail -f /tmp/docker-cleanup.log
```

### 3.3 Log Rotation

Automatische Log-Rotation, um Plattenplatz zu schützen.

**Konfiguration:**

- **Docker Logging:** `json-file`, max-size 10m, max-file 3.
- **Cleanup-Skript:** `scripts/rotate-logs.sh` (täglich 03:00).

**Manueller Start:**

```bash
./scripts/rotate-logs.sh
```

### 3.4 System Monitoring & Backups

- **Health Monitor:** Stündlich (`scripts/health-monitor.sh`).
- **Backrest Backups:** Täglich 01:30. Backups von Konfiguration und Daten.

## 4. Verifizierung

Methoden zur Prüfung der Automatisierung.

### Skriptausführung prüfen

```bash
# PostgreSQL VACUUM
grep "completed successfully" /tmp/pg_vacuum.log | tail -n 5

# Docker Cleanup
grep "cleanup completed" /tmp/docker-cleanup.log | tail -n 5

# Health Monitor
tail -n 20 .config-backup/monitoring/cron.log
```

## Cron Jobs prüfen

```bash
# Cron-Dienststatus
systemctl status cron

# Cron-Logs
journalctl -u cron --since "1 day ago"
```

## Erfolgskriterien

| Metrik                  | Ziel        | Ist   | Status |
| :---------------------- | :---------- | :---- | :----- |
| **PostgreSQL VACUUM**   | Wöchentlich | Aktiv |        |
| **Docker Cleanup**      | Wöchentlich | Aktiv |        |
| **Log Rotation**        | Automatisch | Aktiv |        |
| **Disk Usage**          | <60%        | 60%   |        |
| **Backup Success Rate** | >99%        | 100%  |        |

## 5. Verwandte Dokumentation

- [Admin Guide](../core/admin-guide.md) – Systemadministration
- [Monitoring Guide](../monitoring/monitoring-guide.md) – Monitoring und Alerts
- [Docker Cleanup Guide](docker-cleanup-guide.md) – Detailprozeduren
- [Docker Log Rotation](../../../operations/automation/docker-log-rotation.md) –
  Log-Management

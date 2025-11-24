---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Nginx Access Sync & Fluent Bit DB Monitoring

## 1. Automatische Synchronisierung von access.log

1. Skript: `scripts/infrastructure/monitoring/sync-nginx-access.sh` kopiert
   `/var/log/nginx/access.log` aus dem Container nach
   `data/nginx/logs/access.log`.
2. Unit-Dateien befinden sich in `ops/systemd/nginx-access-sync.service` und
   `.timer`.
3. Installation:

   ```bash
   ./scripts/maintenance/install-docling-cleanup-unit.sh  # Beispiel — für Sync analog vorgehen
   cp ops/systemd/nginx-access-sync.service ~/.config/systemd/user/
   cp ops/systemd/nginx-access-sync.timer ~/.config/systemd/user/
   mkdir -p ~/.config && cp ops/systemd/nginx-access-sync.env.example ~/.config/nginx-access-sync.env
   systemctl --user daemon-reload
   systemctl --user enable --now nginx-access-sync.timer
   ```

4. Konfigurieren Sie die Variable `NGINX_SYNC_TARGET` in der env-Datei, falls
   das Log an einem anderen Ort gespeichert werden soll.
5. Arbeitslog — `logs/nginx-access-sync.log`.

## 2. Fluent Bit DB Monitoring

1. Skript: `scripts/infrastructure/monitoring/check-fluentbit-db.sh` berechnet
   die Größe des Verzeichnisses `data/fluent-bit/db` und schreibt in
   `logs/fluentbit-db-monitor.log`.
2. Variablen:
   - `FLUENTBIT_DB_DIR` — Pfad zur Datenbank.
   - `FLUENTBIT_DB_WARN_GB`/`FLUENTBIT_DB_CRIT_GB` — Schwellenwerte (Standard
     5/8).
3. Beispiel Cron:

   ```cron
   0 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/infrastructure/monitoring/check-fluentbit-db.sh
   ```

4. Für Alertmanager kann eine Regel erstellt werden, die das Log über Fluent Bit
   → Loki liest oder eine Metrik hinzufügt. Siehe Details im
   [Monitoring Guide](monitoring-guide.md).

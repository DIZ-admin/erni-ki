---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Nginx access sync & Fluent Bit DB monitoring

## 1. Automatic access.log synchronization

1. Script: `scripts/infrastructure/monitoring/sync-nginx-access.sh` copies
   `/var/log/nginx/access.log` from container to `data/nginx/logs/access.log`.
2. Unit files located in `ops/systemd/nginx-access-sync.service` and `.timer`.
3. Installation:

   ```bash
   ./scripts/maintenance/install-docling-cleanup-unit.sh  # example — use analogy for sync
   cp ops/systemd/nginx-access-sync.service ~/.config/systemd/user/
   cp ops/systemd/nginx-access-sync.timer ~/.config/systemd/user/
   mkdir -p ~/.config && cp ops/systemd/nginx-access-sync.env.example ~/.config/nginx-access-sync.env
   systemctl --user daemon-reload
   systemctl --user enable --now nginx-access-sync.timer
   ```

4. Configure `NGINX_SYNC_TARGET` variable in env file if you need to save log to
   different location.
5. Work log — `logs/nginx-access-sync.log`.

## 2. Fluent Bit DB monitoring

1. Script: `scripts/infrastructure/monitoring/check-fluentbit-db.sh` calculates
   size of `data/fluent-bit/db` directory and writes to
   `logs/fluentbit-db-monitor.log`.
2. Variables:
   - `FLUENTBIT_DB_DIR` — path to database.
   - `FLUENTBIT_DB_WARN_GB`/`FLUENTBIT_DB_CRIT_GB` — thresholds (default 5/8).
3. Example cron:

   ```cron
   0 * * * * cd /home/konstantin/Documents/augment-projects/erni-ki && ./scripts/infrastructure/monitoring/check-fluentbit-db.sh
   ```

4. For Alertmanager you can create a rule that reads log via Fluent Bit → Loki
   or adds metric. See details in [monitoring guide](monitoring-guide.md).

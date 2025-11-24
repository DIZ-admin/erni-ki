---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# Alertmanager Noise Reduction & Redis Autoscaling

## Ziele

- Spam durch `HTTPErrors`/`HighHTTPResponseTime` vom Blackbox-Monitoring
  reduzieren
- Verfahren für Redis-Autoscaling bei Fragmentierung/Queue-Overflow des
  Alertmanagers festhalten

## Blackbox Rate Limiting

1. **Prometheus-Regeln** – siehe `ops/prometheus/blackbox-noise.rules.yml`. Die
   Gruppe `blackbox-noise.rules` erzeugt aggregierte Alerts
   (`BlackboxHTTPErrorBurst`, `BlackboxSustainedLatency`) mit Label
   `noise_group=blackbox`. Datei in Prometheus `rule_files` einbinden.
2. **Alertmanager-Route** – `ops/alertmanager/blackbox-noise-route.yml` enthält
   einen `route.routes`-Block. Er erhöht `group_interval`/`repeat_interval` auf
   15m/3h. Im Routing vor `severity: warning` platzieren.
3. **Deploy**:
   - Dateien in Prod-Konfiguration (`conf/*`) übernehmen, `prometheus` und
     `alertmanager` neu starten.
   - Im UI prüfen, dass statt dutzender `HTTPErrors` ein aggregierter Alert
     kommt.

## Redis Auto-Scaling

1. **Watchdog** – `scripts/maintenance/redis-fragmentation-watchdog.sh` nutzt
   `REDIS_AUTOSCALE_ENABLED`, `REDIS_AUTOSCALE_STEP_MB` (Default 256MB) und
   `REDIS_AUTOSCALE_MAX_GB` (Default 4GB). Nach `MAX_PURGES` bump’t das Skript
   `maxmemory` per `CONFIG SET` und schreibt die Config.
2. **Aktivieren**:
   - Variablen exportieren (z.B. in cron):
     ```bash
     export REDIS_AUTOSCALE_ENABLED=true
     export REDIS_AUTOSCALE_STEP_MB=512
     export REDIS_AUTOSCALE_MAX_GB=4
     ```
   - Watchdog per cron/systemd starten und Log prüfen:
     `logs/redis-fragmentation-watchdog.log` → `Autoscaling Redis maxmemory...`.
3. **Monitoring** – Metriken `mem_fragmentation_ratio` und `maxmemory`
   beobachten (Watchdog loggt Werte in MB). Grafana-Panel im Redis-Dashboard für
   Bumps anlegen.

## Vorgehen bei Spike

1. **Alertmanager-Queue**: `tail -f .config-backup/logs/alertmanager-queue.log`
   – wenn >500 über 10 Minuten, prüfen, ob Blackbox-Alerts spammen (Route).
   Falls nötig, temporären Silence setzen.
2. **Redis Autoscale**: Log des Watchdogs prüfen; falls kein Bump erfolgt,
   manuell: `docker compose exec redis redis-cli config set maxmemory <value>`.
3. **Dokumentation**: In diesem Runbook festhalten, wie oft Autoscaling
   ausgelöst wurde (Zeitpunkt, Ursache, Maßnahme).

## Autoscale Watchdog aktivieren

1. Environ-Datei anlegen (z.B. `ops/systemd/redis-watchdog.env.example`) und in
   cron/systemd für `redis-fragmentation-watchdog.sh` referenzieren.
2. cron/systemd anpassen: `EnvironmentFile=~/.config/redis-watchdog.env` oder
   Variablen vor Start exportieren.
3. `logs/redis-fragmentation-watchdog.log` beobachten – nach Trigger erscheint
   `Autoscaling Redis maxmemory ...`.
4. Grafana-Panel (Redis-Dashboard) mit `mem_fragmentation_ratio` und `maxmemory`
   hinzufügen, Alert auf starke Anstiege setzen.

## Grafana / Alertmanager Monitoring

- In Grafana das Redis-Dashboard importieren und Graph „Blackbox Noise Rate“
  hinzufügen (Expression aus `ops/prometheus/blackbox-noise.rules.yml`).
- In Alertmanager UI prüfen, dass Route `noise_group=blackbox` alle 15 Minuten
  gruppiert.
- Alle Auslösungen in diesem Runbook dokumentieren (Datum, Quelle, Aktionen).

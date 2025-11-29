---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Alertmanager Noise Reduction & Redis Autoscaling

## Ziele

- Reduzierung der spamartigen `HTTPErrors`/`HighHTTPResponseTime` Alarme von
  Blackbox.
- Festlegung des Verfahrens für Redis-Autoscaling bei chronischer Fragmentierung
  und Überlauf der Alertmanager-Warteschlange.

## Blackbox Rate Limiting

1.**Prometheus-Regeln**— Beispiel in `ops/prometheus/blackbox-noise.rules.yml`.
Die Gruppe `blackbox-noise.rules` fügt aggregierende Alarme hinzu
(`BlackboxHTTPErrorBurst`, `BlackboxSustainedLatency`) und markiert sie mit
`noise_group=blackbox`. Kopieren Sie die Datei in die Prometheus-Konfiguration
und fügen Sie sie zu `rule_files` hinzu. 2.**Alertmanager-Route**—
`ops/alertmanager/blackbox-noise-route.yml` enthält einen Block für
`route.routes`. Er erhöht `group_interval`/`repeat_interval` auf 15m/3h.
Platzieren Sie ihn oberhalb der Route `severity: warning`. 3.**Deployment**:

- Fügen Sie die Dateien in die Produktionskonfiguration (`conf/*`) ein, starten
  Sie die Container `prometheus` und `alertmanager` neu.
- Überprüfen Sie über die UI, dass anstelle von Dutzenden `HTTPErrors` ein
  einzelner aggregierter Alarm eingeht.

## Redis Auto-Scaling

1.**Watchdog**— `scripts/maintenance/redis-fragmentation-watchdog.sh`
unterstützt die Variablen `REDIS_AUTOSCALE_ENABLED`, `REDIS_AUTOSCALE_STEP_MB`
(Standard 256MB) und `REDIS_AUTOSCALE_MAX_GB` (Standard 4GB). Nach `MAX_PURGES`
erhöht das Skript `maxmemory` über `CONFIG SET` und überschreibt die
Konfiguration. 2.**Aktivierung**:

- Variablen exportieren (z.B. in Cron):

  ```bash
  export REDIS_AUTOSCALE_ENABLED=true
  export REDIS_AUTOSCALE_STEP_MB=512
  export REDIS_AUTOSCALE_MAX_GB=4
  ```

- Watchdog starten (Cron/Systemd) und sicherstellen, dass in
  `logs/redis-fragmentation-watchdog.log` Zeilen wie
  `Autoscaling Redis maxmemory...` erscheinen.

  3.**Monitoring**— Wir überwachen die Metriken `mem_fragmentation_ratio` und
  `maxmemory` (innerhalb des Watchdogs werden Werte in MB ausgegeben).
  Zusätzlich wird empfohlen, ein Panel in Grafana (Redis Dashboard)
  hinzuzufügen, um die Erhöhungen zu verfolgen.

## Verfahren bei Lastspitzen

1.**Alertmanager-Warteschlange**:
`tail -f .config-backup/logs/alertmanager-queue.log` — wenn >500 innerhalb von
10 Minuten, sicherstellen, dass Blackbox-Alarme nicht spammen (siehe Route).
Temporären Silence setzen, falls erforderlich. 2.**Redis Autoscale**:
Watchdog-Log prüfen; bei fehlenden Erhöhungen kann manuell ausgeführt werden:
`docker compose exec redis redis-cli config set maxmemory <value>`. 3.**Dokumentation**:
Bei der Incident-Analyse auf dieses Runbook verweisen und festhalten, wie oft
Autoscale ausgelöst wurde.

## Aktivierung des Autoscale Watchdogs

1. Erstellen Sie eine Environ-Datei (Beispiel:
   `ops/systemd/redis-watchdog.env.example`) und binden Sie sie in die
   Cron/Systemd-Unit für `redis-fragmentation-watchdog.sh` ein.
2. Aktualisieren Sie Cron/Systemd:
   `EnvironmentFile=~/.config/redis-watchdog.env` oder Export der Variablen vor
   dem Start.
3. Überwachen Sie `logs/redis-fragmentation-watchdog.log` — nach Auslösung
   erscheint `Autoscaling Redis maxmemory ...`.
4. Fügen Sie ein Grafana-Panel (Redis Dashboard) mit `mem_fragmentation_ratio`
   und `maxmemory` hinzu und aktivieren Sie einen Alarm bei starkem Anstieg.

## Grafana / Alertmanager Beobachtung

- Importieren Sie in Grafana das Redis-Panel und fügen Sie einen neuen Graphen
  "Blackbox Noise Rate" hinzu (verwendet Ausdruck aus der Datei
  `ops/prometheus/blackbox-noise.rules.yml`).
- Stellen Sie in der Alertmanager UI sicher, dass die Route
  `noise_group=blackbox` Alarme alle 15 Minuten gruppiert.
- Dokumentieren Sie alle Auslösungen in diesem Runbook (Datum, Quelle,
  ergriffene Maßnahmen).

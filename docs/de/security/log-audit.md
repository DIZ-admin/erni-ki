---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI — Log-Audit (12. November 2025)

## Umfang & Quellen

- `data/webhook-logs/` – 69 235 Alertmanager-JSONs (314 MB) vom 29.08. bis
  12.11.2025.
- `scripts/health-monitor.sh`, `.config-backup/monitoring/cron.log`,
  `.config-backup/logs/*.log` – Protokolle der regelmäßigen Health-Checks.
- Fluent-Bit-Configs (`conf/fluent-bit/*.conf`) und docker-compose
  (Fluentd-/json-file-Logtreiber).
- Ausgewählte `data/*`-Verzeichnisse (Redis, Postgres, Grafana, Loki,
  Fluent Bit) – Rechte und Struktur geprüft.

### Einschränkungen

- `data/postgres*`, `data/redis/appendonlydir`, `data/grafana/pdf`,
  `data/backrest/oplog*` erfordern Root – direkte Analyse nicht möglich.
- `data/webhook-logs` enthält auch ältere Events; Fokus dieses Audits liegt auf
  den letzten 7 Tagen (05.–12. November), um aktuelle Vorfälle zu isolieren.

## Alertmanager-Telemetrie (05.–12.11.)

- Gesamt: **18 226 Events** (13 313 Warning, 4 913 Critical)
- Tagesverteilung:

| Datum      | Alerts |
| ---------- | -----: |
| 2025-11-05 |    532 |
| 2025-11-06 |  4 189 |
| 2025-11-07 |  3 154 |
| 2025-11-08 |  1 850 |
| 2025-11-09 |  1 922 |
| 2025-11-10 |  1 848 |
| 2025-11-11 |  2 467 |
| 2025-11-12 |  2 267 |

### Häufigste Alerts (05.–12.11.)

| Alert                              | Anzahl |
| ---------------------------------- | -----: |
| `ContainerRestarting`              | 12 848 |
| `RedisDown`                        |  1 507 |
| `HighDiskUtilization`              |    678 |
| `CriticalServiceLogsMissing`       |    678 |
| `CriticalDiskSpace`                |    673 |
| `CriticalLowDiskSpace`             |    672 |
| `RedisCriticalMemoryFragmentation` |    394 |
| `FluentBitHighMemoryUsage`         |    172 |
| `AlertmanagerClusterHealthLow`     |    170 |
| `ContainerHighMemoryUsage`         |    135 |

### Top-Services nach Warnungen

| Service/Metrik                  | Alerts |
| ------------------------------- | -----: |
| `cadvisor` (Container-Restarts) | 12 933 |
| `redis`                         |  1 930 |
| `system` (`/boot/efi`, `/`)     |  1 345 |
| `node-exporter`                 |    678 |
| `logging` (Fluent-Bit-Stream)   |    678 |
| `alertmanager`                  |    200 |
| `fluent-bit`                    |    183 |
| `postgres`                      |    111 |
| `ollama`                        |     65 |
| `nginx`                         |     20 |

## Zentrale Beobachtungen

### 1. Alert-Sturm `ContainerRestarting`

- 12 848 Meldungen pro Woche; nahezu jeder Container betroffen
  (`alert_warning_20251106_110452.json`).
- Alertmanager-Queue >4 000 (`alert_critical_20251112_131718.json`) → echte
  Events gehen unter.
- Ursache: `rate(container_last_seen[5m]) > 0` meldet jede Aktivität als
  Restart; cadvisor wird zum Rauschgenerator.
- Maßnahmen: Regel abschalten oder neu schreiben (`container_start_time`, Filter
  auf `erni-ki-*`, `RestartCount` aus Docker nutzen).

### 2. Wiederholte Redis-Ausfälle

- 1 507 `RedisDown` + 394 `RedisCriticalMemoryFragmentation`
  (`alert_critical_20251112_145333.json`, `...110047.json`).
- Folgen: Ausfall des Cache für OpenWebUI/LiteLLM/SearXNG → hohe Latenz.
- Empfehlungen: reale Redis-Logs analysieren (Zugriff auf
  `data/redis/appendonlydir` nötig), `maxmemory-policy` ≠ `noeviction`,
  Watchdog, mehr Memory, Compose-Restart mit Backoff, Alert auf
  `redis_uptime_in_seconds`.

### 3. `/boot/efi` permanent voll

- 673 `CriticalDiskSpace` + 672 `CriticalLowDiskSpace`
  (`alert_critical_20251112_160557.json`) – `/dev/nvme0n1p1` (512 MB) steht bei
  100 %.
- Ursache: keine Bereinigung alter EFI-Einträge; Alert feuert dauerhaft.
- Lösung: alte EFI-Dateien löschen, Alert-Pegel anpassen (≥98 % auf 512 MB
  nutzlos) oder `fstype=vfat` ausschließen.

### 4. Instabile Logging-Kette (Fluent Bit → Loki)

- Wiederholte `ServiceDown` für `fluent-bit:2020` und `loki:3100`
  (`alert_critical_20251112_153014.json`) plus `CriticalServiceLogsMissing`
  (678×, z.B. `alert_critical_20251007_042049.json`).
- Memory-Alerts (`alert_warning_20251112_153751.json`).
- Folge: verschwundene Logs und JSON-Berge in `data/webhook-logs`.
- Empfehlungen: `storage.max_chunks_up` / `storage.backlog.mem_limit` setzen,
  Buffer auf SSD, Container mit `mem_limit`, optional Promtail als Fallback,
  Cron-Rotation für `data/webhook-logs`.

### 5. Alertmanager degradierte

- Alerts `AlertmanagerQueueCritical` / `AlertmanagerClusterHealthLow` (z.B.
  `alert_critical_20251112_131718.json`).
- Grund: siehe Punkt 1 – Queue überläuft; Webhooks stauen sich.
- Lösung: `inhibit_rules`/`group_by` für laute Alerts, `--cluster.peer-timeout`
  anpassen oder Logging-Level reduzieren, bis Filter greifen.

### 6. Cron/Monitoring-Skripte fehlerhaft

- `scripts/health-monitor.sh` ruft `python` auf, obwohl nur `python3` vorhanden
  → Dauerfehler (`python: command not found`).
- `.config-backup/logging-monitor.sh` & `logging-alerts.sh` fehlen; Cron spammt
  `not found`.
- Logs zählen 17 210 „kritische“ Einträge nur wegen Alertmanager-Texten (grep
  auf `compose logs`).
- Maßnahmen: auf `python3` umstellen, echte Health-Endpunkte nutzen,
  nicht-existierende Cronjobs löschen.

### 7. Postgres & AI-Services schwanken

- 111 Alerts für Postgres (z.B. `PostgreSQLSlowQueries`), 65 für Ollama, 20 für
  nginx.
- Empfehlung: Phasen mit LiteLLM/OpenWebUI-Last korrelieren,
  `pg_terminate_backend` für „idle in transaction“ >5 Min aktivieren.

## Empfehlungen (Priorität)

1. Regel `ContainerRestarting` reduzieren (<500 Events/Tag).
2. Redis stabilisieren (Logs, Memory-Limits, Watchdog, neue Alerts).
3. `/boot/efi` säubern und Disk-Alerts anpassen.
4. Fluent Bit → Loki absichern und `data/webhook-logs` rotieren.
5. Cron-Skripte reparieren (python3, valide Checks).
6. Alertmanager-Queue abbauen (Rauschen filtern, Ressourcen erhöhen).
7. Zugriff auf `data/postgres*`/`data/redis` beschaffen und weitere Audits
   durchführen.

## Remediation (12.11.2025)

- **Redis**: Frag-Parameter reduziert, Watchdog
  `scripts/maintenance/redis-fragmentation-watchdog.sh` + cron (alle 5 Min),
  neuer Alert `RedisHighFragmentation`.
- **/boot/efi**: alte EFI-Logs gelöscht; Nutzung <4 %.
- **Disk-Alerts**: `fstype="vfat"` & `/boot/efi` ausgeschlossen
  (`conf/prometheus/*`), danach
  `docker compose restart prometheus alertmanager`.
- **Fluent Bit → Loki**: `conf/fluent-bit/fluent-bit.conf` nutzt
  `Host erni-ki-loki`, `storage.type filesystem`, `Retry_Limit False` und 1 GB
  Backlog.
- **Webhook-Rotation**: Skript `scripts/maintenance/webhook-logs-rotate.sh` +
  Cron `30 2 * * *`, Archiv in `data/webhook-logs/archive`.
- **Cron-Skripte**: `.config-backup/logging-monitor.sh` und `logging-alerts.sh`
  erstellt; `health-monitor.sh` nutzt `python3`.

Sync mit `docs/operations/monitoring/*.md` sowie eigener Task für
`data/webhook-logs` erforderlich.

## Re-Audit (13.11.2025)

### Kennzahlen (09:05 UTC+1)

- `alertmanager_cluster_messages_queued` = **301** (Warnschwelle 100).
- Aktive Alerts: 13 (6× `HTTPErrors`, 3× `HighHTTPResponseTime`, je 1×
  `AlertmanagerClusterHealthLow`, `FluentBitHighMemoryUsage`,
  `CriticalServiceLogsMissing`, `ContainerWarningMemoryUsage`).
- Redis `mem_fragmentation_ratio` = **5.89**.
- `data/webhook-logs/`: 48 MB, 5 303 JSONs + 67 Archive (Rotation aktiv).

### Neue Beobachtungen

1. Cron `health-monitor` scheiterte regelmäßig an `docker compose ps`, da Jobs
   nicht aus dem Repo-Root liefen. `conf/cron/logging-reports.cron` setzt nun
   `PROJECT_ROOT` und ruft Skripte via `bash`.
2. Alertmanager-Queue-Watcher lief nicht; manuell 304 Meldungen geloggt und Cron
   ergänzt.
3. Regel `ContainerRestarting` neu geschrieben: Filter auf `erni-ki-*`,
   Aggregation pro Service, `>=3` Restarts/30 Min + `for: 5m`.
4. `redis-exporter` nutzte falsch `redis://localhost`; Compose enthält jetzt
   feste `REDIS_ADDR=redis://redis:6379` + Secret `redis_exporter_url` als JSON.
5. Fluent-Bit-Parser-Konflikt (`postgres`) gelöst durch Umbenennung in
   `postgres_structured`.
6. Watchdog loggte nach `scripts/`; `PROJECT_DIR` zeigt nun auf Repo-Root
   (`logs/redis-fragmentation-watchdog.log`).
7. Webhook-Rotation bestätigt: 5.3 k Dateien verbleiben, Rest archiviert.

### Remediation (13.11.2025)

- Compose: feste `REDIS_ADDR`/`REDIS_PASSWORD_FILE` für redis-exporter.
- `conf/cron/logging-reports.cron`: `PROJECT_ROOT`, Cronjobs für
  `.config-backup/*`-Skripte und Alertmanager-Queue.
- `conf/fluent-bit/parsers.conf`: `postgres_structured`.
- Redis-Watchdog schreibt nach `logs/`.
- `scripts/monitoring/alertmanager-queue-watch.sh` ausgeführt (304 = WARN).
- `conf/prometheus/alerts.yml`: verschärftes `ContainerRestarting`.
- Diverse Doku-/Secret-Updates (Monitoring-Guides, service-inventory,
  `secrets/redis_exporter_url.txt.example`).

### Nächste Schritte

- Lautstärke von `ContainerRestarting` überwachen; ggf. zusätzliche Filter oder
  Silence-Regeln.
- Neue Cron-Dateien auf dem Host aktivieren und Fehlerfreiheit verifizieren.
- `alertmanager_cluster_messages_queued` <100 stabilisieren; laute Alerts
  (`HTTPErrors`, `CriticalServiceLogsMissing`) weiter reduzieren.
- Entscheidung zu `requirepass` für Redis treffen und Secrets anpassen.
- Watchdog-Log beobachten (Schwellwert 4.0, aktuell 5.89).

## Zusatz (13.11.2025): PublicAI-Provider in LiteLLM

- Custom-Provider `conf/litellm/custom_providers/publicai.py` implementiert
  (sync/async/streaming, `convert_to_model_response_object`,
  User-Agent-Maskierung).
- Compose mountet `conf/litellm/custom_providers`, `env/litellm.env` setzt
  `PYTHONPATH=/app/custom_providers:/app`.
- Modell `publicai-apertus-70b` via `PATCH /model/704e30c3.../update` (api_base
  `https://api.publicai.co/v1`, `custom_llm_provider=publicai`, Modus `chat`)
  aktualisiert; neuer API-Key.
- `LiteLLM_VerificationToken` weist Token-Hash `52b606a1...` wieder
  `{'all-proxy-models'}` zu.
- `conf/litellm/config.yaml` mappt `apertus-70b-instruct` auf
  `publicai/apertus-70b-instruct`.
- Smoke-Tests (13.11., 08:31 UTC):

  ```bash
  curl -s -H 'Authorization: Bearer sk-7b7…38bb' http://localhost:4000/models
  curl -s -H 'Authorization: Bearer sk-7b7…38bb' \
    -H 'Content-Type: application/json' \
    -d '{"model":"publicai-apertus-70b","messages":[{"role":"user","content":"привет"}]}' \
    http://localhost:4000/v1/chat/completions
  curl -sN -H 'Authorization: Bearer sk-7b7…38bb' \
    -H 'Content-Type: application/json' \
    -d '{"model":"publicai-apertus-70b","stream":true,"messages":[{"role":"user","content":"привет"}]}' \
    http://localhost:4000/v1/chat/completions | head
  docker compose exec openwebui curl -s -H 'Authorization: Bearer sk-7b7…38bb' \
    -H 'Content-Type: application/json' \
    -d '{"model":"publicai-apertus-70b","messages":[{"role":"user","content":"ping"}]}' \
    http://litellm:4000/v1/chat/completions
  ```

  Alle Requests lieferten HTTP 200 und valide JSON/SSE („Привет! …“) – die Kette
  LiteLLM ↔ PublicAI ↔ OpenWebUI funktioniert wieder.

- API-Key liegt im Docker-Secret `publicai_api_key`
  (`secrets/publicai_api_key.txt`). `scripts/entrypoints/litellm.sh` setzt
  `PUBLICAI_API_KEY`, Modelle nutzen `os.environ`.
- Custom-Provider exportiert Prometheus-Metriken (`litellm_publicai_*`) auf
  Port 9109; Job `litellm-publicai` sammelt sie. Neue Alerts
  `LiteLLMPublicAIHighErrorRate` / `LiteLLMPublicAIRepeated404` warnen bei
  Häufung von 4xx/5xx.

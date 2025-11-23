---
language: de
translation_status: complete
doc_version: '2025.11'
---

# Operations Handbook ERNI-KI

Zusammenfassendes Nachschlagewerk für DevOps/SRE, die Observability, SLA und
Incident Response verwalten.

## 1. Ziel

- 32 Production-Services Healthy halten (siehe `README.md`).
- Versionsidentität sicherstellen (OpenWebUI v0.6.36, Prometheus v3.0.0, Grafana
  v11.3.0).
- Response Targets für 20 aktive Alert Rules und tägliche Cron-Skripte
  einhalten.

## 2. Alerts und Monitoring

- Alle Regeln sind in `conf/prometheus/alerts.yml` dokumentiert (Critical,
  Performance, Database, GPU, Nginx). Details in
  `docs/operations/monitoring/monitoring-guide.md` (Abschnitt „Prometheus Alerts
  Configuration").
- SLA: Kritische Alerts — Antwort <5 Min, Bugfixes und Triage innerhalb von 30
  Min.
- Alertmanager v0.27.0 definiert Kanäle (Slack/Teams) und Throttling; Teams
  umfassen Owner (SRE) und Backup (Platform Lead).
- Logging erfolgt über Fluent Bit → Loki und `json-file` für kritische Services
  (OpenWebUI, Ollama, PostgreSQL, Nginx).

## 3. Reaktionsprozess

1. Prüfen: `docker compose ps` → `docker compose logs <service>` → `curl` auf
   Metriken.
2. Mit Grafana Dashboards vergleichen (GPU/LLM/DB). Ticks: `monitoring-guide.md`
   beschreibt Healthcheck-Muster für Exporter (TCP, wget, Python).
3. Bei kritischem Alert: Benachrichtigung über Alertmanager senden und Ticket in
   Archon öffnen (tasks/report). Status, Tokens, Teams dokumentieren (SRE
   Primary, Platform Backup).
4. Für Sensoren (non-critical): `runbooks/service-restart-procedures.md` oder
   `troubleshooting-guide.md` ausführen.

## 4. Wartungsautomatisierung

- Alle VACUUM- und Docker-Cleanup-Skripte sind in
  `docs/operations/automation/automated-maintenance-guide.md` beschrieben. Läuft
  per Cron (VACUUM 03:00, Cleanup 04:00, Log Rotation täglich, Backrest Backups
  01:30).
- Ergebnisse per Utilities prüfen: `pg_isready`, `docker image prune`,
  `docker builder prune`, `docker volume prune`.
- Bei Skript-Fehlern: siehe `runbooks/backup-restore-procedures.md` für
  Wiederherstellung, `runbooks/configuration-change-process.md` für
  Config-Migrationen.
- **Neue November-Aufgaben:**
  - `scripts/maintenance/docling-shared-cleanup.sh` — bereinigt Docling Shared
    Volume und stellt Rechte wieder her (Cron Job **docling_shared_cleanup**).
  - `scripts/maintenance/redis-fragmentation-watchdog.sh` — überwacht
    `redis_memory_fragmentation_ratio`, aktiviert bei >4 `activedefrag` und kann
    Container neu starten.
  - `scripts/monitoring/alertmanager-queue-watch.sh` — analysiert Alertmanager
    Queue (`alertmanager_cluster_messages_queued`) und führt defensiven Neustart
    mit Logging in `logs/alertmanager-queue.log` durch.
  - `scripts/infrastructure/security/monitor-certificates.sh` — überwacht
    TLS/Cloudflare-Zertifikate und startet nginx/watchtower bei Bedarf neu.

## 5. Runbooks und Playbooks

- `runbooks/service-restart-procedures.md` — sichere Neustarts, Healthchecks
  vorher/nachher.
- `runbooks/troubleshooting-guide.md` — typische Probleme (GPU, RAG, Redis) und
  Befehle `docker logs`, `nvidia-smi`, `curl`.
- `runbooks/docling-shared-volume.md` — spezielle Aktionen zur Bereinigung von
  Docling Shared Volume und Fluent Bit.

## 6. Healthchecks & Metriken

- Metriken aller Exporter in `monitoring-guide.md`: node-exporter, Redis,
  PostgreSQL (mit IPv4/IPv6 Proxy), Nvidia, Blackbox, Ollama, Nginx, RAG.
- Empfohlen: `curl -s http://localhost:PORT/metrics | head` zur Überprüfung und
  `docker inspect ... State.Health`.
- `docker compose top` und `docker stats` für Prozessansicht verwenden.

## 7. Data & Storage Dokumentation

- **Datenbankpläne und -optimierungen:**
  `docs/operations/database/database-monitoring-plan.md`,
  `docs/operations/database/database-production-optimizations.md`,
  `docs/operations/database/database-troubleshooting.md`.
- **Redis:** `docs/operations/database/redis-monitoring-grafana.md`,
  `docs/operations/database/redis-operations-guide.md`.
- **vLLM / LiteLLM Ressourcen:**
  `docs/operations/database/vllm-resource-optimization.md` + Skripte
  `scripts/monitor-litellm-memory.sh`,
  `scripts/redis-performance-optimization.sh`.
- In Runbooks Links zu entsprechenden Data-Dokumenten festhalten bei Maintenance
  (pgvector VACUUM, Redis defrag, Backrest restore).

## 8. Referenzen und Quellen

- Architecture → `docs/architecture/architecture.md`.
- Monitoring → `docs/operations/monitoring/monitoring-guide.md`,
  `conf/prometheus`, `conf/grafana`.
- Automation → `docs/operations/automation/automated-maintenance-guide.md`,
  `scripts/maintenance`.
- Runbooks → `docs/operations/runbooks/*.md`.
- Archon — kurze Statusnotizen und Checklisten für jeden Incident aktualisieren
  (siehe Task `a0169e05…`).

## 9. LiteLLM Context & RAG Kontrolle

- LiteLLM v1.80.0.rc.1 bedient Context Engineering und Context7 (Thinking
  Tokens, `/lite/api/v1/think`). Sicherstellen, dass Gateway unter
  `http://localhost:4000/health/liveliness` erreichbar ist.
- `scripts/monitor-litellm-memory.sh` — Cron/Ad-hoc-Prüfung des
  LiteLLM-Speicherverbrauchs und Webhooks/Slack bei Überschreitung des
  Schwellenwerts (Standard 80%).
- `scripts/infrastructure/monitoring/test-network-performance.sh` — umfassende
  RTT-Prüfung zwischen nginx ↔ LiteLLM ↔ Ollama/PostgreSQL/Redis; bei
  Latenz-Degradation Ergebnis in Archon festhalten.
- Bei Context7-Incidents: `docs/reference/api-reference.md` und
  `docs/reference/mcpo-integration-guide.md` (Abschnitt „Context7 & LiteLLM
  Routing") verwenden und Status mit neuem YAML-Block
  `docs/reference/status.yml` synchronisieren.

## 10. Archive und Reporting

- Übersicht: `docs/archive/README.md` (Links zu audits/diagnostics/incidents).
- Compliance und Dokumentation: `docs/archive/audits/README.md`.
- Diagnostik: `docs/archive/diagnostics/README.md` (für RCA verwenden).
- Incidents und Remediation: `docs/archive/incidents/README.md`.
- Cron/Monitoring-Logs und Konfigurationen:
  `docs/archive/config-backup/monitoring-report-2025-10-02.md`,
  `update-analysis-2025-10-02.md`, `update-execution-report-2025-10-02.md`. Bei
  Skript-Updates Änderungen in diesen Reports festhalten oder neue Dateien in
  config-backup erstellen.

## 11. CI/CD und Sicherheit

- **Secret Scanning:** Gitleaks oder TruffleHog als separaten CI-Job für PRs
  hinzufügen. Pipeline bei Funden blockieren, Ausnahmen über Baseline.
- **Dependency Scanning:** `npm audit --omit=dev` oder Snyk OSS in CI mit Fail
  bei kritischen CVE; für Go `gosec` + Trivy Filesystem Scan beibehalten.
- **Container Scanning:** Trivy Image Scan mit explizitem Allowlist/Ignorefile
  für Fehlalarme, alle anderen kritischen — Pipeline fehlschlagen lassen.
- **Policy:** Echte Secrets nur in Secret Store/CI Secrets; in Git nur
  `.example` und Generierungsanleitung (README/Handbuch).

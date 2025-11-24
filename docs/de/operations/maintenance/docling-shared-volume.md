---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Zugriffs- und Bereinigungsrichtlinie für Docling Shared Volume

[TOC]

Das Shared Volume `./data/docling/shared` wird von den Diensten Docling und
OpenWebUI zum Austausch von Dateien verwendet, die OCR/Extraktion durchlaufen.
Das Volume kann personenbezogene Daten (PII) enthalten, daher sind eine
formalisierte Zugriffskontrolle und eine Speicherstrategie erforderlich.

## 1. Datenkategorien

| Verzeichnis   | Quelle                       | Inhalt                                         | Standard-Aufbewahrung   |
| ------------- | ---------------------------- | ---------------------------------------------- | ----------------------- |
| `uploads/`    | OpenWebUI (Benutzer-Uploads) | Quelldokumente, PDF, Bilder.                   | 2 Tage                  |
| `processed/`  | Docling Pipeline             | Normalisierte Chunks, JSON, Zwischenartefakte. | 14 Tage                 |
| `exports/`    | Docling/OpenWebUI            | Fertige Antworten, ZIP, Berichte.              | 30 Tage                 |
| `quarantine/` | Docling                      | Dateien mit Fehlern/Verdacht auf Malware/PII.  | 60 Tage, manuelle Prüf. |
| `tmp/`        | Beide Dienste                | Kurzlebige temporäre Dateien, Dumps.           | 1 Tag                   |

> Die Struktur wird automatisch durch das Skript
> `scripts/maintenance/docling-shared-cleanup.sh` erstellt. Wenn das Verzeichnis
> nicht existiert, wird es mit den korrekten Berechtigungen angelegt.

## 2. RBAC und Host-Berechtigungen

- Basis-Eigentümer: Systembenutzer, unter dem Docker Compose ausgeführt wird
  (`$USER`).
- Gruppe `docling-data` erstellen (einmalig): `sudo groupadd -f docling-data`.
- Eigentümer des Verzeichnisses zuweisen:
  `sudo chgrp -R docling-data ./data/docling/shared`.
- Berechtigungen für Root und Unterverzeichnisse:
  `chmod 770 ./data/docling/shared{,/uploads,/processed,/exports,/quarantine,/tmp}`.
- In die Gruppe `docling-data` nehmen wir Admins der AI-Plattform und
  Service-Accounts auf, die Dateien vom Host lesen/schreiben müssen.
- Für Read-Only-Auditoren erstellen wir die Gruppe `docling-readonly` und
  vergeben `chmod 750` auf `exports/`.

> Automatisierung: Führe
> `./scripts/maintenance/enforce-docling-shared-policy.sh` aus (bei Bedarf setze
> `DOC_SHARED_OWNER`, `DOC_SHARED_GROUP`, `DOC_SHARED_READONLY_GROUP`). Das
> Skript erstellt Gruppen, gleicht Eigentümer ab und setzt ACLs für `exports/`.

Die Container Docling/OpenWebUI greifen standardmäßig mit UID 1000 auf dasselbe
Verzeichnis zu. Bei Bedarf einer strengeren Trennung verwenden Sie ACL:

```bash
sudo setfacl -m g:docling-readonly:rx ./data/docling/shared/exports
sudo setfacl -m g:docling-data:rwx ./data/docling/shared
```

## 3. Bereinigung und Volumenkontrolle

Das Skript `scripts/maintenance/docling-shared-cleanup.sh` implementiert die
Aufbewahrungsrichtlinien (Retention). Das Verhalten wird über Variablen
konfiguriert:

| Variable                               | Standardwert            | Zweck                           |
| -------------------------------------- | ----------------------- | ------------------------------- |
| `DOC_SHARED_ROOT`                      | `./data/docling/shared` | Pfad zum Volume                 |
| `DOC_SHARED_INPUT_RETENTION_DAYS`      | 2                       | Aufbewahrung Raw-Uploads        |
| `DOC_SHARED_PROCESSED_RETENTION_DAYS`  | 14                      | Aufbewahrung verarbeitete Daten |
| `DOC_SHARED_EXPORT_RETENTION_DAYS`     | 30                      | Aufbewahrung Exporte            |
| `DOC_SHARED_QUARANTINE_RETENTION_DAYS` | 60                      | Quarantäne                      |
| `DOC_SHARED_TMP_RETENTION_DAYS`        | 1                       | Temporäre Dateien               |
| `DOC_SHARED_MAX_SIZE_GB`               | 20                      | Soft-Limit für Alert-Logging    |

### 3.1 Manuell / Dry-Run

```bash
./scripts/maintenance/docling-shared-cleanup.sh          # Dry-Run (Standard)
DOC_SHARED_INPUT_RETENTION_DAYS=1 ./scripts/maintenance/docling-shared-cleanup.sh
```

### 3.2 Anwendung und Cron

```bash
sudo -E ./scripts/maintenance/docling-shared-cleanup.sh --apply \
  >> logs/docling-shared-cleanup.log 2>&1
```

Empfohlener Cron (täglich um 02:10):

````cron
10 2 * * * cd /home/konstantin/Documents/augment-projects/erni-ki && \
  sudo -E ./scripts/maintenance/docling-shared-cleanup.sh --apply >> logs/docling-shared-cleanup.log 2>&1

> **Wichtig:** Verwenden Sie `sudo -E` (mit NOPASSWD in sudoers) oder führen Sie den Cron unter dem Benutzer aus,
> der Eigentümer von `data/docling` ist. Andernfalls läuft der Task in "Permission denied".

Einen fertigen sudoers-File können Sie so generieren:

```bash
./scripts/maintenance/render-docling-cleanup-sudoers.sh | sudo tee /etc/sudoers.d/docling-cleanup
````

Standardmäßig werden die benötigten `env_keep` Regeln hinzugefügt, sodass
Cron/Systemd `DOC_SHARED_*` Variablen ohne manuelles Bearbeiten von
`/etc/sudoers` übergeben können.

### 3.3 Systemd Unit

Im Repository befinden sich bereits Unit-Dateien und ein Installationsskript:

- `ops/systemd/docling-cleanup.service`
- `ops/systemd/docling-cleanup.timer`
- `ops/systemd/docling-cleanup.env.example`
- `ops/sudoers/docling-cleanup.sudoers`
- `scripts/maintenance/install-docling-cleanup-unit.sh`

**Aktivierungsreihenfolge**

1. Kopieren Sie `ops/sudoers/docling-cleanup.sudoers` nach
   `/etc/sudoers.d/docling-cleanup`, und ersetzen Sie den Benutzer und Pfad zum
   Repository (NOPASSWD).
2. Führen Sie `./scripts/maintenance/install-docling-cleanup-unit.sh` aus —
   Unit-Dateien landen in `~/.config/systemd/user`,
   `~/.config/docling-cleanup.env` wird erstellt, Timer `docling-cleanup.timer`
   wird automatisch aktiviert.
3. Bearbeiten Sie `~/.config/docling-cleanup.env` (Beispiel liegt bei), um
   Eigentümer/Gruppe und Pfad zum Shared Volume festzulegen. Standardmäßig Start
   um 02:10 CET, `RandomizedDelaySec=300`.

> Für eine System-Level-Installation verschieben Sie die Unit-Dateien nach
> `/etc/systemd/system`, fügen `User=docling-maint` in `.service` hinzu und
> aktivieren den Timer über `systemctl enable --now docling-cleanup.timer`.

Fügen Sie Log-Monitoring (Fluent Bit → Loki) und einen Alert hinzu, wenn in der
Ausgabe `WARNING: shared volume size ... exceeds` erscheint. Das Skript
`scripts/monitoring/docling-cleanup-permission-metric.sh` veröffentlicht die
Metrik `erni_docling_cleanup_permission_denied`; binden Sie es in Cron/Systemd
und Alertmanager ein, um bei wiederholten `Permission denied` auszulösen.

## 4. Vorfallverfahren

1. **Verdächtige Datei entdeckt** — Verschieben Sie sie nach `quarantine/` und
   dokumentieren Sie dies im Ticket (Datum/Autor im Dateinamen hinzufügen),
   führen Sie `chmod 640` aus.
2. **Volume voll** — Starten Sie das Skript mit reduzierten Retention-Parametern
   oder löschen Sie manuell nach Absprache mit dem Dateneigentümer.
3. **Wiederherstellungsanfrage** — Daten älter als Retention werden nicht
   garantiert; verwenden Sie Backrest/Backups, wenn eine gelöschte Datei
   wiederhergestellt werden muss.

## 5. Dokumentation

- Hauptreferenz: `docs/architecture/service-inventory.md` (Abschnitt "Docling
  Shared Volume Policy").
- Archon-Dokument `ERNI-KI Minimal Project Description` — enthält
  Zusammenfassung und Risiken.
- Bereinigungsskript: `scripts/maintenance/docling-shared-cleanup.sh`.

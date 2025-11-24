---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# Docling Shared Volume – Betrieb und Pflege

## Zweck

- Gemeinsamer Speicher für Docling (Uploads/Artefakte)
- Risiko: Ansammlung von PII/Altdateien → regelmäßig säubern

## Speicherort

- Default Volume/Path siehe Docker Compose (`docling` Service)
- Prüfen: Mount in `compose.yml` und Pfad in `env/docling.env`

## Cleanup-Richtlinien

- Retention: definieren (z.B. 7–14 Tage für temp-Dateien)
- Keine sensiblen Daten dauerhaft halten
- Regelmäßig Cron/Systemd Cleanup ausführen

## Cleanup-Skript (Beispiel)

```bash
# scripts/maintenance/docling-shared-cleanup.sh
#!/bin/bash
TARGET="/path/to/docling-shared"
find "$TARGET" -type f -mtime +14 -print -delete
```

Ausführen via cron/systemd, Log-Ausgabe in `logs/docling-cleanup.log` speichern.

## Monitoring

- Speicherverbrauch tracken (df/du oder Exporter)
- Alerts bei schnellem Wachstum

## Sicherheit

- Zugriffe auf das Volume beschränken (Permissions, nur benötigte Services)
- Keine Secrets/Keys im Volume
- Falls PII gefunden: sofort löschen, Incident-Prozess starten

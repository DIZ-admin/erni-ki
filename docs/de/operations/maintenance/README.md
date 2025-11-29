---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Technische Wartung von ERNI-KI

Alle Verfahren der erweiterten Wartung: Backups, Service-Neustarts, Bereinigung
des Docling-Volumes und Checklisten für Image-Updates. Zusammenfassung der
Vorschriften für Backup, Image-Updates und Bereinigung gemeinsamer Speicher.

## Dokumente

- [backup-restore-procedures.md](backup-restore-procedures.md) — Vorschrift zur
  Erstellung von Backups und Wiederherstellung.
- [docling-shared-volume.md](docling-shared-volume.md) — Speicherrichtlinie,
  Sicherheit und Bereinigung des gemeinsamen Docling-Volumes.
- [image-upgrade-checklist.md](image-upgrade-checklist.md) —
  Schritt-für-Schritt-Anleitung zur Aktualisierung von Containern und
  Überprüfung von Digests.
- [service-restart-procedures.md](service-restart-procedures.md) — Matrix für
  den sicheren Neustart kritischer Dienste.

## Verwendung

- Vor dem Aktualisieren von Abhängigkeiten — Checklist durchgehen.
- Planen Sie eine Bereinigung von Docling-Artefakten — konsultieren Sie die
  entsprechende Datei.
- Bevor Sie Dienste in der Produktion neu starten — befolgen Sie die Verfahren
  aus `service-restart-procedures.md`.

Dokumentieren Sie die Ergebnisse der Operationen in Jira/Archon und
aktualisieren Sie diese README beim Hinzufügen neuer Verfahren.

## Regelmäßige Aufgaben

-**Täglich:**Überprüfung der Backups (`backrest`) und des freien Speicherplatzes
auf dem Docling-Volume. -**Wöchentlich:**Aktualisierung der Images über
Checklist und Smoke-Test der Dienste. -**Monatlich:**Audit der Cron-Skripte,
Rotation von Zertifikaten, Inspektion von `./data/*` auf Müllansammlung.

## Kommunikation

1. Erstellen Sie ein Ticket in Jira/Archon mit Beschreibung und Zeitfenster.
2. Benachrichtigen Sie die betroffenen Teams 24 Stunden im Voraus.
3. Fügen Sie nach den Maßnahmen Logs hinzu, vermerken Sie die Ergebnisse im
   Ticket und auf der Statusseite.

Verwenden Sie diese README vor der Durchführung von Wartungsarbeiten und
dokumentieren Sie die Ergebnisse in Jira/Archon.

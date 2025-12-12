---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Automatisierung von ERNI-KI Betriebsaufgaben

Dieser Abschnitt beschreibt die Vorschriften und Skripte, die helfen, die
ERNI-KI Cluster ohne manuelles Eingreifen zu warten. Verwenden Sie diesen Index,
um schnell Reinigungs-, Wartungs- oder regelmäßige Überprüfungsverfahren zu
finden.

## Wichtige Dokumente

- [Automatisierte Wartung](automated-maintenance-guide.md) — Zeitplan für
  tägliche/wöchentliche Aufgaben, Überwachung von Watchdog-Skripten, Richtlinie
  für den Autostart von Cron/systemd-Timern.
- [Docker Cleanup](docker-cleanup-guide.md) — Automatische Bereinigung von
  Docker-Images/-Volumes, Rotation hängender Container, Ressourcenempfehlungen.
- [Docker Log Rotation](../../../en/operations/automation/docker-log-rotation.md)
  — Konfiguration von logrotate und Fluent Bit für Container-Logs,
  Speicherparameter und Überwachung von Überläufen.

## Wann diesen Abschnitt konsultieren

- Regelmäßige Wartungsarbeiten vor einem Release.
- Vorbereitung einer neuen Umgebung (Dev/Stage/Prod) mit denselben
  Automatisierungen.
- Einrichtung von Alerting für Cron/Wartungsaufgaben.

**Tipp:** Dokumentieren Sie das Ergebnis nach Durchführung eines automatisierten
Verfahrens in `docs/operations/maintenance/index.md` oder im Wartungsticket.

## Überwachung der Automatisierung

1. Überprüfen Sie einmal täglich `logs/maintenance/*.log` auf Fehler und Dauer.
2. Die Prometheus-Regel `CronJobFailed` sollte eine SLA ≤ 1% Nichtverfügbarkeit
   haben.
3. Alle Skripte werden über `systemd`-Units gestartet; verwenden Sie
   `systemctl status erni-maintenance@*` vor einem Release.

## Beitrag zur Automatisierungsbibliothek

- Skripte werden in `scripts/automation/` mit dem Präfix `erni-` abgelegt.
- Fügen Sie einen Dry-Run-Modus hinzu, um Änderungen vor der Anwendung zu
  prüfen.
- Aktualisieren Sie den entsprechenden Abschnitt dieser README und verknüpfen
  Sie das Skript mit dem Runbook.

Aktualisieren Sie die README beim Hinzufügen neuer Automatisierungsszenarien.

## Hinweis

Die russische Version ist die Hauptquelle. Bei Unstimmigkeiten siehe
[russische Version](../../../en/operations/automation/index.md).

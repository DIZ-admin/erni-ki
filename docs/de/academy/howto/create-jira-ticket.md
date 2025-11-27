---
language: de
translation_status: complete
doc_version: '2025.11'
title: 'create-jira-ticket'
system_version: '12.1'
last_updated: '2025-11-27'
system_status: 'Production Ready'
---

# Wie erstellt man eine Aufgabe in Jira mit Open WebUI

## Wann zu verwenden

Wenn Sie schnell einen Aufgabenentwurf erstellen müssen: Beschreibung,
erwartetes Ergebnis und Akzeptanzkriterien. Szenario für manuelle
Strukturkontrolle (ohne Autogenerierung).

## Was vorzubereiten ist

- Titel/kurze Problembeschreibung.
- Reproduktionsschritte, erwartetes vs. tatsächliches Ergebnis.
- Umgebung (prod/stage/local), Logs/Screenshots, Reproduktionsdatum.

## Schritte

1. Öffnen Sie einen neuen Dialog und beschreiben Sie den Projektkontext und das
   Problem.
2. Bitten Sie das Modell, Titel, Beschreibung und Liste der Akzeptanzkriterien
   zu formulieren.
3. Kopieren Sie den Entwurf nach Jira, überprüfen Sie Begriffe und Daten.
4. Präzisieren Sie Severity/Impact, Labels/Komponenten und SLA.

## Prompt-Beispiele

- **Gut:** "Du bist ein Projektmanager. Erstelle ein Jira-Ticket: Es muss eine
  Autorisierungsprüfung zur API X hinzugefügt werden. Wichtig: Token,
  Fehlerprotokollierung, Benachrichtigung bei 401. Gib Titel, Beschreibung und 3
  Akzeptanzkriterien als Liste".
- **Schlecht:** "Brauche ein Ticket über Autorisierung, denk dir was aus".

## Fertiger Prompt

```
Du bist ein Projektmanager. Erstelle einen Bug/Feature für Jira.
Kontext: <Fakten>. Umgebung: <prod/stage>. Reproduktionsdatum: <Datum>.
Benötigt: summary, description (steps, expected vs actual), labels, severity,
3-5 Akzeptanzkriterien als Liste. Erfinde keine neuen Fakten.
```

## Checkliste

- Schritte, expected/actual und Umgebung vorhanden.
- Akzeptanzkriterien sind messbar und überprüfbar.
- Keine vertraulichen Daten (Passwörter, Tokens, interne URLs).

---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Prompting 101

## Was ist ein Prompt

Ein Prompt ist eine Anweisung für das Modell, die Rolle, Aufgabe, Kontext und
Antwortformat definiert. Je präziser der Prompt, desto klarer das Ergebnis.

## Grundlegende Vorlage

**ROLLE → AUFGABE → KONTEXT → FORMAT**

Beispiel: "Du bist ein technischer Redakteur. Aufgabe: Bereite eine E-Mail an
den Kunden vor. Kontext: Wir senden eine Meeting-Zusammenfassung. Format: 3
Absätze, keine Aufzählungszeichen".

Ergänzen Sie bei Bedarf: Anforderungen an Sprache (RU/DE/EN), Textlänge und
Tonfall (formell/freundlich).

## Beispiele für Büroaufgaben

-**Kunden-E-Mail:**

- "Du bist ein Account Manager. Aufgabe: Schreibe eine E-Mail an den Kunden mit
  den Meeting-Ergebnissen. Kontext: Wir haben uns auf einen Testzugang geeinigt,
  Deadline ist Freitag. Format: Begrüßung, 3 Punkte mit Ergebnissen,
  CTA." -**Anruf-Zusammenfassung:**
- "Du bist ein Business-Analyst. Aufgabe: Erstelle eine Zusammenfassung eines
  30-minütigen Meetings. Kontext: Wir haben die Roadmap besprochen, 2
  Entscheidungen getroffen. Format: Aufzählungspunkte, Abschnitt
  'Risiken/Maßnahmen'." -**Textverbesserung:**
- "Du bist ein Redakteur. Aufgabe: Verbessere den E-Mail-Text. Kontext:
  Zielgruppe ist der CIO, Stil ist geschäftlich, ohne Jargon. Format: Endgültige
  Version + kurze Empfehlungen." -**Ticket-Entwurf:**
- "Du bist ein Support-Ingenieur. Aufgabe: Bereite einen JIRA-Entwurf vor.
  Kontext: Bug in der Authentifizierung nach dem Update, Reproduktionsschritte
  und Screenshots vorhanden. Format: summary, steps to reproduce,
  expected/actual." -**Optionenvergleich:**
- "Du bist ein Berater. Aufgabe: Vergleiche zwei Deployment-Ansätze. Kontext:
  k8s vs docker-compose. Format: Tabelle mit Vor-/Nachteilen + kurze
  Empfehlung."

## Checkliste vor dem Absenden des Prompts

1. Präzisieren Sie Rolle und Aufgabe: Warum das Modell eine Antwort benötigt.
2. Fügen Sie Eingabedaten hinzu: Links, Auszüge, Schlüsselzahlen.
3. Begrenzen Sie das Format: Länge, Antwortsprache, Vorhandensein von
   Tabellen/Listen.
4. Überprüfen Sie die Vertraulichkeit: Entfernen Sie personenbezogene Daten und
   interne Links, falls keine Genehmigung vorliegt.
5. Legen Sie Erwartungen fest: Was als fertiges Ergebnis gilt (z.B. "Entwurf für
   Kunden ohne technischen Jargon").

## Anti-Patterns (was zu vermeiden ist)

- Vage Aufgaben ohne Fakten: "schreibe einen Text" → präzisieren Sie
  Zielgruppe/Format.
- Überladung mit übermäßigen Anforderungen in einem Prompt: Teilen Sie in
  Schritte auf.
- Offene Fragen ohne Ziel: "was denkst du?" → definieren Sie ein
  Bewertungskriterium.
- Aufforderungen, Fakten zu erfinden: Geben Sie immer an "verwende nur die
  bereitgestellten Daten".

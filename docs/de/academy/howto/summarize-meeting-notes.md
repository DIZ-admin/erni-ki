---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Meeting-Notizen zusammenfassen

## Wann zu verwenden

- Sie müssen schnell ein Protokoll nach einem Meeting oder Anruf erstellen.
- Sie müssen Entscheidungen, Risiken und nächste Schritte hervorheben.

## Was vorzubereiten ist

- Rohe Notizen (Aufzählungspunkte oder Transkript).
- Teilnehmer, Datum, Zweck des Meetings.
- Entscheidungen/nächste Schritte, Deadlines, Verantwortliche.

## Schritte

1. Sammeln Sie Notizen (Text, Aufzählungspunkte oder Transkript) und fügen Sie
   sie in den Prompt ein.
2. Geben Sie die Dauer des Meetings, Teilnehmer und Hauptthemen an.
3. Bitten Sie darum, Abschnitte hervorzuheben: Zusammenfassung, Entscheidungen,
   Risiken, Nächste Schritte (mit Verantwortlichen und Daten).
4. Überprüfen Sie, dass die Empfehlungen konkret und realistisch sind; entfernen
   Sie interne Links, die nicht extern geteilt werden dürfen.
5. Stimmen Sie Sprache (RU/DE/EN) und Format (markdown/email) vor dem Versand
   ab.
6. Speichern Sie das Protokoll im Unternehmens-Repository.

### Fertiger Prompt

```
Du bist ein Business-Analyst. Fasse das Meeting zusammen.
Eingabe: <Notizen einfügen>. Zielgruppe: <Team/Kunde>. Sprache: <RU/DE/EN>.
Erstelle Abschnitte: Zusammenfassung (bis zu 5 Punkte), Entscheidungen, Risiken, Nächste Schritte (wer/Deadline).
Format: Aufzählungspunkte + kurze Einleitung mit Datum. Füge keine neuen Fakten hinzu.
```

## Prompt-Beispiele

-**Gut:**

- "Du bist ein Business-Analyst. Aufgabe: Erstelle ein Protokoll eines
  30-minütigen Meetings. Kontext: Wir haben den Pilot-Start besprochen,
  Entscheidungen über Daten und Verantwortliche getroffen. Format:
  Zusammenfassung (3 Punkte), Entscheidungen, Risiken, Nächste Schritte (mit
  Daten). Hier sind die Notizen: <Text einfügen>." -**Schlecht:**
- "Mach es kurz" (nicht angegeben, was hervorgehoben werden soll und welches
  Format benötigt wird)

## Checkliste vor dem Versand

- Im Abschnitt "Nächste Schritte" sind Verantwortliche und Fristen angegeben.
- Risiken sind separat aufgeführt.
- Keine internen Daten, die nicht in den ursprünglichen Notizen enthalten sind.

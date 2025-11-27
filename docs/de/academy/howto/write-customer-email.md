---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Kunden-E-Mail schreiben

## Wann zu verwenden

- Sie müssen Meeting-Ergebnisse oder Projekt-Updates senden.
- Sie benötigen einen höflichen und klaren Ton ohne unnötige Füllwörter.
- Sie müssen schnell eine E-Mail aus Fakten zusammenstellen und den CTA nicht
  vergessen.

## Was vorzubereiten ist (Eingabedaten)

- Thema des Meetings/Anlasses, Hauptentscheidungen, Deadlines, Verantwortliche.
- E-Mail-Sprache (RU/DE/EN) und gewünschter Ton (offiziell/freundlich).
- Versandkanal (email/Teams) und ob ein CTA erforderlich ist (bestätigen,
  Zeitfenster wählen).

## Schritte

1. Öffnen Sie Open WebUI und wählen Sie ein universelles Modell (z.B. GPT-4o).
2. Bereiten Sie Fakten vor: Meeting-Thema, Entscheidungen, Deadlines,
   Kontaktpersonen.
3. Formulieren Sie den Prompt nach dem Schema Rolle → Aufgabe → Kontext →
   Format.
4. Geben Sie die E-Mail-Sprache (RU/DE/EN) und den gewünschten Ton
   (offiziell/freundlich) an.
5. Überprüfen Sie den Text auf Faktengenauigkeit und passen Sie die Begrüßung an
   den Kunden an.
6. Speichern Sie das Ergebnis oder senden Sie es über Ihren E-Mail-Client.

### Fertiger Prompt

```
Du bist ein Account Manager. Aufgabe: Schreibe eine E-Mail an den Kunden mit den Meeting-Ergebnissen.
Kontext: <Vereinbarungen>, Deadline <Datum>, Verantwortliche: <Namen>.
Ton: <offiziell/freundlich>, Sprache: <RU/DE/EN>.
Format: Begrüßung, 3–5 Punkte mit Ergebnissen, klarer CTA mit Datum/nächstem Schritt.
Füge einen E-Mail-Betreff hinzu.
```

## Prompt-Beispiele

- **Gut:**
  - "Du bist ein Account Manager. Aufgabe: Schreibe eine E-Mail an den Kunden
    mit den Ergebnissen des heutigen Meetings. Kontext: Wir haben vereinbart,
    bis Freitag einen Testzugang zu gewähren, Verantwortliche ist Anna Ivanova,
    nächster Schritt ist eine Demo am 25. Format: Begrüßung, 3 Punkte mit
    Ergebnissen, CTA — Demo bestätigen."
- **Schlecht:**
  - "Schreibe eine E-Mail an den Kunden über das Meeting." (kein Kontext, unklar
    welche Ergebnisse und was zu tun ist)

## Checkliste vor dem Versand

- Gibt es einen E-Mail-Betreff und einen klaren CTA (Datum, Bestätigung, Link)?
- Fakten überprüft: Daten, Namen, Verantwortliche.
- Ton und Sprache entsprechen dem Empfänger.
- Keine internen Links/Daten, die nicht offengelegt werden dürfen.

---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
title: 'Style Guide'
---

# Style Guide für ERNI-KI Docs

## 1. Emoji

Siehe `docs/reference/emoji-style-guide.md` für Kategorien und Beispiele.

## 2. Admonition Boxes

Erlaubte Vorlagen:

- **Wichtig**

  > **Wichtig:** Kritische Info, darf nicht übersehen werden.

- **Warnung**

  > ⚠️ **WARNUNG:** Potenzielle Risiken/Probleme.

- **Tipp**

  > 💡 **Tipp:** Empfehlung oder Best Practice.

- **Info**
  > ℹ️ **Info:** Zusatzdetails oder Kontext.

## 3. Code-Blöcke

- Immer Language-Tag setzen (`bash`, `yaml`, ```json).
- Keine `$`-Prefixe in Beispielen.
- Kommentar oder erwartetes Ergebnis ergänzen, wenn hilfreich.

## 4. Listen

- Bullet `-`, Einrückung 2 Leerzeichen.
- Abschnittsüberschriften in sentence case.

## 5. Tabellen

- Kopf fett + Trenner `|---|`.
- Ausrichtung passend zum Inhalt (z. B. `:---:` für Zahlen).

## 6. Links

- Interne Links relativ.
- Linktext muss aussagekräftig sein (nicht „hier klicken“).

## 7. Terminologie

- „Service“ für Microservices; „Dienst“ nur für Systemdienste.
- „Container“ als Standardbegriff.
- Abkürzungen beim ersten Auftreten ausschreiben.

## 8. Datum & Zeit

- Datum: YYYY-MM-DD (ISO 8601).
- Zeit: 24h-Format.
- Bei Bedarf „Letzte Aktualisierung:“ angeben.

## 9. Anführungszeichen

- `«»` für Fließtext; `""` für technische Kontexte/CLI.

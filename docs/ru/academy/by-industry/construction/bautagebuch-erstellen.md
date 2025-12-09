---
title: 'Bautagebuch mit KI erstellen'
category: construction
difficulty: easy
duration: '10 min'
roles: ['bauleiter', 'polier', 'projektmanager']
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-04'
industry: construction
company: erni-gruppe
---

# Bautagebuch mit KI erstellen

## Ziel

KI nutzen um täglich professionelle, rechtssichere Bautagebuch-Einträge zu
erstellen, die alle wichtigen Details enthalten und den SIA-Normen entsprechen.

## Für wen

- **Bauleiter** — tägliche Dokumentation
- **Poliere** — Baustellenberichte
- **Projektmanager** — Übersicht behalten

## ⏱ Zeitaufwand

5-10 Minuten pro Eintrag (statt 20-30 Minuten manuell)

## Was Sie brauchen

- Zugang zu Open WebUI
- Informationen vom Bautag
- **Empfohlenes Modell:** GPT-4o oder Claude 3.5

---

## Basis-Prompt-Vorlage

```markdown
Erstelle einen professionellen Bautagebuch-Eintrag:

**Projekt:** [Projektname und Nummer] **Datum:** [TT.MM.YYYY] **Wochentag:**
[Montag/Dienstag/...] **Wetter:** [Sonnig/Bewölkt/Regen/Schnee] **Temperatur:**
[°C morgens/mittags/abends]

**Anwesende:** **Erni-Mitarbeiter:**

- Holzbau: [Anzahl] Personen
- Spenglerei: [Anzahl] Personen
- Ausbau: [Anzahl] Personen
- Bauleitung: [Namen]

**Subunternehmer:**

- [Firma]: [Anzahl] Personen
- [Firma]: [Anzahl] Personen

**Durchgeführte Arbeiten:**

- [Detaillierte Beschreibung Arbeit 1]
- [Detaillierte Beschreibung Arbeit 2]
- [Detaillierte Beschreibung Arbeit 3]

**Material-Lieferungen:**

- [Uhrzeit]: [Material, Menge, Lieferant]
- [Uhrzeit]: [Material, Menge, Lieferant]

**Maschinen/Geräte im Einsatz:**

- [Autokran, Hubarbeitsbühne, etc.]

**Besonderheiten/Probleme:**

- [Falls vorhanden: genaue Beschreibung]
- [Massnahmen die ergriffen wurden]

**Besprechungen:**

- [Teilnehmer, Thema, Ergebnis]

**Nächste Schritte (Morgen):**

- [Geplante Arbeiten]
- [Erwartete Lieferungen]

Ton: Sachlich, präzise, rechtssicher Format: Gemäss SIA-Normen Sprache:
Schweizer Hochdeutsch
```

---

## Beispiel-Szenarien

### Szenario 1: Standard-Arbeitstag (Rohbau)

**Prompt:**

```markdown
Erstelle Bautagebuch-Eintrag für Holzbau-Projekt:

**Projekt:** Mehrfamilienhaus Seestrasse 45, Luzern (Projekt-Nr. 2024-087)
**Datum:** 04.12.2024 **Wochentag:** Mittwoch **Wetter:** Bewölkt, trocken
**Temperatur:** -2°C morgens, 4°C mittags

**Anwesende:** **Erni-Mitarbeiter:**

- Holzbau: 6 Personen (Montage-Team)
- Bauleitung: Stefan Müller

**Subunternehmer:**

- Kranfirma Meier AG: 1 Kranführer + Autokran

**Durchgeführte Arbeiten:**

- Montage Wand-Elemente 2. OG, Achse A-D (12 Elemente montiert)
- Verschrauben und Ausrichten der Wandelemente
- Beginn Montage Deckenelemente 2. OG (5 von 18 Elementen)
- Kontrolle Lotrechte und Flucht mit Nivelliergerät

**Material-Lieferungen:**

- 07:30 Uhr: Wandelemente 2. OG, Erni Holzbau AG Produktion
- 13:15 Uhr: Schrauben und Befestigungsmaterial, Fischer AG

**Maschinen/Geräte:**

- Autokran 35t (ganztägig)
- Hubarbeitsbühne 12m

**Besonderheiten:**

- Element W-07 hatte Abweichung von 5mm, wurde vor Ort angepasst
- Mittagspause 12:00-13:00 wegen Kranpause

**Nächste Schritte:**

- Weiter Montage Deckenelemente 2. OG
- Lieferung Dachkonstruktion erwartet 06:30 Uhr

Ton: Technisch präzise, dokumentarisch Format: SIA-konform
```

**Erwartetes Resultat:** Professioneller, detaillierter Bautagebuch-Eintrag mit
allen relevanten Informationen für Bauherrn und Archiv.

---

### Szenario 2: Problemtag mit Mängeln

**Prompt:**

```markdown
Erstelle Bautagebuch-Eintrag mit Problemdokumentation:

**Projekt:** Einfamilienhaus Bergstrasse 12, Emmen (Projekt-Nr. 2024-103)
**Datum:** 04.12.2024 **Wochentag:** Mittwoch **Wetter:** Starker Regen ab 10:00
Uhr **Temperatur:** 6°C, Windböen bis 40 km/h

**Anwesende:** **Erni-Mitarbeiter:**

- Spenglerei: 3 Personen
- Bauleitung: Thomas Weber

**Subunternehmer:**

- Gerüstbau Keller AG: 2 Personen (Gerüst-Rückbau)

**Durchgeführte Arbeiten:**

- Dachrinnen-Montage Südseite bis 10:00 Uhr (vor Regen)
- Nur 40% der geplanten Arbeit erledigt
- Gerüst teilweise abgebaut (windgeschützte Bereiche)

**Material-Lieferungen:**

- 08:15 Uhr: Kupfer-Dachrinnen, Rheinzink Schweiz AG

**Probleme/Massnahmen:**

- 10:00 Uhr: Arbeiten wegen Starkregen eingestellt
- Gesundheit und Sicherheit prioritär
- Dachrinnen provisorisch gesichert
- Lieferung Fallrohre verschoben auf morgen (zu gefährlich heute)

**Besprechung:**

- 10:30 Uhr: Telefon mit Bauherr Hr. Kuster
- Information über Verzögerung
- Neuer Termin: Fortsetzung morgen 07:00 Uhr (bei gutem Wetter)
- Bauherr informiert und einverstanden

**Zeitauswirkung:**

- Verzögerung: 1 Tag
- Keine Kostenauswirkung (höhere Gewalt)

**Nächste Schritte:**

- Wetterprognose prüfen
- Falls trocken: Fortsetzung Dachrinnen-Montage
- Falls Regen: Innenarbeiten vorbereiten

Wichtig: Dokumentiere wetter-bedingte Verzögerung für Versicherung! Ton:
Objektiv, detailliert
```

---

### Szenario 3: Abnahmetag

**Prompt:**

```markdown
Erstelle Bautagebuch für wichtigen Abnahme-Tag:

**Projekt:** Landwirtschafts-Gebäude Hof Sonnenberg, Wolhusen (Projekt-Nr.
2024-056) **Datum:** 04.12.2024 **Wochentag:** Mittwoch **Wetter:** Sonnig, klar
**Temperatur:** 0°C morgens, 6°C mittags

**Anwesende:** **Erni-Mitarbeiter:**

- Bauleitung: Martin Kunz
- Geschäftsführer: Urs Erni

**Bauherr:**

- Familie Bucher (Landwirt + Ehefrau)

**Architekt:**

- Architekturbüro Schmid, Sursee: Frau Schmid

**Gemeinde:**

- Bauinspektor Herr Vogel, Gemeinde Wolhusen

**Tagesablauf:** 09:00-10:30 Uhr: Gemeinsame Begehung

- Rohbau Stallgebäude
- Wohnbereich
- Technische Räume
- Aussenanlagen

10:30-11:00 Uhr: Besprechung Feststellungen

**Feststellungen:** **Keine Beanstandungen:**

- Holzkonstruktion einwandfrei
- Dach dicht und fachgerecht
- Türen und Fenster funktionsfähig

**Kleinere Nachbesserungen (Restarbeiten):**

1. Stall, Nordseite: Fuge zwischen Boden und Wand nachfüllen (5m)
2. Wohnbereich, Zimmer 3: Türgriff nachziehen (locker)
3. Aussenbereich: Drainage-Schacht-Deckel ersetzen (defekt)

**Behebung bis:** 15.12.2024

**Abnahme-Protokoll:**

- Unterschrieben von allen Parteien
- Bauherr sehr zufrieden
- Gemeinde gibt Nutzungsbewilligung ab 01.01.2025

**Übergabe:**

- Schlüssel übergeben an Bauherr
- Bedienungsanleitungen übergeben
- Garantie-Dokumente übergeben

**Nächste Schritte:**

- Mängel beheben bis 15.12.
- Abschlussrechnung bis 20.12.
- Garantie beginnt 01.01.2025

Ton: Positiv aber präzise Wichtig: Alle Unterschriften dokumentieren!
```

---

## Erweiterte Techniken

### Technik 1: Wochen-Zusammenfassung

**Prompt:**

```markdown
Erstelle Wochen-Zusammenfassung aus täglichen Einträgen:

**Projekt:** [Name] **Woche:** KW 49 (04.12. - 08.12.2024)

**Tägliche Einträge:** [Montag Eintrag] [Dienstag Eintrag] [Mittwoch Eintrag]
[Donnerstag Eintrag] [Freitag Eintrag]

**Erstelle:**

1. Zusammenfassung Hauptarbeiten
2. Gesamt-Arbeitsstunden (Erni + Subunternehmer)
3. Material-Verbrauch diese Woche
4. Probleme und Lösungen
5. Fortschritt in % (geplant vs. erreicht)
6. Ausblick nächste Woche

Format: Für Bauherren-Report Sprache: Verständlich, nicht zu technisch
```

---

### Technik 2: Foto-Dokumentation einbinden

**Prompt:**

```markdown
Erweitere Bautagebuch um Foto-Referenzen:

[Bautagebuch-Eintrag von oben]

**Fotodokumentation:**

- Foto 001: Übersicht Baustelle 07:30 Uhr (Beginn Tag)
- Foto 002: Montage Element W-07 (Anpassung 5mm)
- Foto 003-010: Montage-Sequenz 2. OG Wandelemente
- Foto 011: Übersicht Baustelle 16:30 Uhr (Tagesende)

**Für jedes Foto beschreibe:**

- Was ist zu sehen
- Warum ist das dokumentiert
- Besonderheiten

Zweck: Lückenlose Dokumentation für Archiv
```

---

### Technik 3: Rechtssichere Formulierung

**Prompt:**

```markdown
Überprüfe Bautagebuch auf rechtliche Aspekte:

[Dein Bautagebuch-Entwurf]

**Prüfkriterien:**

1. Sind alle Vertragsparteien korrekt benannt?
2. Sind Zeiten präzise dokumentiert?
3. Sind Probleme objektiv beschrieben (keine Schuldzuweisungen)?
4. Sind mündliche Absprachen schriftlich festgehalten?
5. Sind Bedenken dokumentiert (z.B. Sicherheit, Qualität)?
6. Ist die Sprache neutral und sachlich?

**Falls nötig, formuliere um für:**

- Rechtssicherheit
- Neutralität
- Vollständigkeit

Kontext: Bautagebuch kann vor Gericht als Beweis dienen!
```

---

## Wichtige Regeln

### Was MUSS ins Bautagebuch:

**Wetter und Temperatur** (kann Verzögerungen erklären) **Alle Anwesenden**
(Name, Firma, Funktion) **Arbeitszeiten** (Beginn, Ende, Pausen)
**Material-Lieferungen** (Zeit, Menge, Zustand) **Probleme/Mängel** (objektiv
beschrieben) **Mündliche Absprachen** (schriftlich festhalten!) **Bedenken**
(Sicherheit, Qualität, Termine)

### Was NICHT ins Bautagebuch:

Persönliche Meinungen Schuldzuweisungen Vertrauliche Geschäftsinformationen
Spekulation Gerüchte

---

## Checkliste Tages-Eintrag

Vor Abschluss des Eintrags prüfen:

- [ ] Datum und Wetter erfasst
- [ ] Alle Personen/Firmen aufgelistet
- [ ] Arbeiten detailliert beschrieben
- [ ] Lieferungen dokumentiert
- [ ] Probleme objektiv festgehalten
- [ ] Lösungen/Massnahmen beschrieben
- [ ] Fotos referenziert
- [ ] Nächste Schritte klar
- [ ] Rechtschreibung korrekt
- [ ] Ton sachlich und neutral

---

## Profi-Tipps

### Tipp 1: Direkt am Abend schreiben

```markdown
"Erstelle Bautagebuch DIREKT am Ende des Arbeitstags. Memory ist frisch, Details
genauer. Nicht am nächsten Morgen - da vergisst man Details!"
```

### Tipp 2: Smartphone-Notizen nutzen

```markdown
"Während des Tages: Notizen im Smartphone

- Zeiten fotografieren
- Material-Lieferscheine fotografieren
- Besonderheiten sofort notieren

Abends: Alles in strukturiertes Bautagebuch mit KI überführen"
```

### Tipp 3: Vorlagen für Projekt-Typen

```markdown
"Erstelle Vorlagen für wiederkehrende Projekt-Typen:

- Holzbau-Montage (Standard-Tage)
- Dacharbeiten (Spenglerei)
- Innenausbau (Türen, Fenster)
- Landwirtschaftsbau (spezifische Anforderungen)

Spart Zeit und sichert Konsistenz!"
```

---

## Weiterführende Informationen

### SIA-Normen:

- **SIA 118** — Allgemeine Bedingungen für Bauarbeiten
- **SIA 118/380** — Allgemeine Bedingungen für Holzbau-Arbeiten
- **SIA 181** — Schallschutz im Hochbau
- **SIA 380/1** — Heizwärmebedarf

### Erni-Interne Richtlinien:

- Bautagebuch-Vorlage Excel (Intranet)
- Foto-Namenskonvention
- Archivierung (7 Jahre Aufbewahrungspflicht)

---

## Mobile Nutzung

**Tipp für Baustelle:**

1. Smartphone mit Open WebUI App
2. Sprachnotiz während des Tages (mit Zeitstempel)
3. Abends: Sprachnotizen transkribieren lassen (KI)
4. In strukturiertes Bautagebuch umwandeln (KI)
5. Nochmals prüfen und freigeben

**Zeitersparnis:** 15-20 Minuten pro Tag!

---

## Zusammenfassung

**Sie haben gelernt:**

- Strukturierte Bautagebücher erstellen
- SIA-konforme Dokumentation
- Rechtssichere Formulierungen
- Problemdokumentation
- Abnahme-Protokolle

**Zeitersparnis:** 50-60% (von 30 Min → 10-15 Min)

**Qualität:** Höher durch Vollständigkeit und Struktur

---

**Nächstes Szenario:** [Angebot erstellen →](../holzbau/angebot-erstellen.md)

**Fragen?** Kontakt: bauleitung@erni-gruppe.ch

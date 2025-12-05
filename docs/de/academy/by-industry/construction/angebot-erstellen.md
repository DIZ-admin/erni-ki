---
title: 'Professionelle Angebote mit KI erstellen'
category: construction
difficulty: medium
duration: '15 min'
roles: ['kalkulation', 'planer', 'verkauf']
language: de
translation_status: original
doc_version: '2025.11'
last_updated: '2025-12-04'
industry: construction
company: erni-gruppe
---

# Professionelle Angebote mit KI erstellen

## Ziel

KI nutzen um präzise, professionelle Angebote für Holzbau-, Spenglerei- und
Ausbau-Projekte zu erstellen, die alle technischen Details enthalten und den
Schweizer Standards entsprechen.

## Für wen

- **Kalkulation** — Angebotsabteilung
- **Planer** — Erni Planung AG
- **Verkauf** — Kundenberatung
- **Projektleiter** — Nachtragsangebote

## ⏱ Zeitaufwand

15-30 Minuten pro Angebot (statt 1-2 Stunden manuell)

## Was Sie brauchen

- Zugang zu Open WebUI
- Projektdetails und Berechnungen
- Preisliste Erni Gruppe
- **Empfohlenes Modell:** GPT-4o oder Claude 3.5

---

## Basis-Angebotsvorlage

```markdown
Erstelle professionelles Angebot für Holzbau-Projekt:

**ANGEBOT**

**Projekt:** [Projektbezeichnung] **Bauherr:** [Name, Firma] **Adresse:**
[Strasse, PLZ Ort] **Standort Bauprojekt:** [Falls abweichend]

**Angebotsnummer:** [z.B. 2024-087] **Datum:** [TT.MM.YYYY] **Gültig bis:**
[TT.MM.YYYY - üblicherweise 3 Monate]

---

**LEISTUNGSBESCHREIBUNG**

**1. Holzbau-Konstruktion**

**1.1 Wandelemente**

- Fläche: [X] m²
- Aufbau: [Beschreibung Schichtaufbau]
- Aussenschalung: [Material, Stärke]
- Lattung/Hinterlüftung: [Details]
- Windschutz: [Produkt, Hersteller]
- Holzständer: [Dimension, Achsmass, Holzart]
- Dämmung: [Material, λ-Wert, Stärke]
- Dampfbremse: [Produkt, sd-Wert]
- Installationsebene: [falls vorhanden]
- Innenbekleidung: [Material, Stärke]
- U-Wert: [W/m²K] gemäss SIA 380/1

**1.2 Deckenelemente**

- Fläche: [X] m²
- Aufbau: [Beschreibung]
- Tragfähigkeit: [kN/m²]
- U-Wert: [W/m²K]

**1.3 Dachkonstruktion**

- Fläche: [X] m²
- Konstruktionsart: [Sparren/Pfetten/Träger]
- Dachneigung: [Grad/Prozent]
- Aufbau: [Details]

**2. Enthaltene Leistungen**

Engineering und Statik Produktion in unserer Fertigungshalle Transport zur
Baustelle Montage inkl. Kran Einmessung und Ausrichtung Dokumentation

**3. Nicht enthaltene Leistungen**

- Baugrube/Fundament
- Gerüst (separate Offerte möglich)
- Fassadenverkleidung (falls gewünscht: Zusatzposition siehe unten)
- Elektro-/Sanitärinstallationen

**KONDITIONEN**

**Preis:** Netto-Pauschalpreis: CHF [Betrag] zzgl. MwSt. 8.1%: CHF [Betrag]
**Total inkl. MwSt.: CHF [Betrag]**

**Zahlungsbedingungen:**

- 30% Anzahlung bei Auftragsvergabe
- 40% bei Beginn Montage
- 25% bei Fertigstellung
- 5% 30 Tage nach Abnahme

**Liefertermin:**

- Produktionsbeginn: [Datum]
- Montagebeginn: [Datum]
- Fertigstellung: [Datum]
- Gesamtdauer: ca. [X] Wochen ab Auftragserteilung

**Gültigkeit:** Dieses Angebot ist gültig bis [Datum]. Preise basieren auf
aktuellen Materialpreisen (Stand [Datum]). Bei Auftragserteilung nach [Datum]
behalten wir uns Preisanpassungen vor.

**Garantie:**

- 5 Jahre Garantie auf Konstruktion
- 2 Jahre Garantie auf Material gemäss SIA 118

**Normen und Vorschriften:**

- SIA 118 — Allgemeine Bedingungen für Bauarbeiten
- SIA 118/380 — Holzbau-Arbeiten
- SIA 380/1 — Heizwärmebedarf
- Brandschutz gemäss kantonalen Vorschriften

**Ihre Ansprechperson:** [Name] [Funktion] Tel: [Nummer] E-Mail: [E-Mail]

---

**Mit freundlichen Grüssen**

**ERNI HOLZBAU AG** Guggibadstrasse 8 6288 Schongau

Format: Professionell, übersichtlich Sprache: Schweizer Hochdeutsch Ton:
Kompetent, verbindlich
```

---

## Spezifische Angebots-Typen

### Typ 1: Einfamilienhaus-Holzbau

**Prompt:**

```markdown
Erstelle Angebot für Einfamilienhaus:

**Projekt:** Neubau Einfamilienhaus **Bauherr:** Familie Meier **Standort:**
Emmen LU

**Projektdetails:**

- Wohnfläche: 150 m²
- 2 Geschosse + Dachgeschoss
- Holzständerbauweise
- Moderne Dämmung (Minergie-tauglich)
- Flachdach

**Leistungsumfang:**

1. Wandelemente:

- Aussenwände: 220 m²
- Innenwände tragend: 85 m²
- Aufbau: 240mm inkl. 200mm Dämmung
- U-Wert: 0.15 W/m²K

2. Deckenelemente:

- EG-Decke: 160 m²
- OG-Decke: 155 m²
- Aufbau: Holz-Beton-Verbund

3. Dachkonstruktion:

- Flachdach: 165 m² (inkl. Überstände)
- Dämmung: 300mm

**Preis (Kalkulation bereits erstellt):**

- Material: CHF 125,000
- Montage: CHF 35,000
- Transport/Kran: CHF 12,000
- Engineering: CHF 8,000
- **Total Netto: CHF 180,000**

**Lieferzeit:** 8 Wochen ab Auftrag

**Besonderheiten:**

- Minergie-Zertifizierung möglich (Aufpreis CHF 5,000)
- Fassadenoptionen vorhanden
- Bauherr plant Eigenleistungen (Innenausbau)

Erstelle vollständiges, professionelles Angebot. Include: Zahlungsplan,
Garantien, Ansprechpartner. Ton: Familienfreundlich aber professionell
```

---

### Typ 2: Aufstockung/Erweiterung

**Prompt:**

```markdown
Angebot für Gebäudeerweiterung:

**Projekt:** Aufstockung Mehrfamilienhaus **Bauherr:** ImmoVest AG **Standort:**
Luzern, Bahnhofstrasse 35

**Projektdetails:**

- Bestehend: 3-geschossiges MFH (Massivbau)
- Neu: 4. Geschoss in Holzbau (2 Wohnungen)
- Wohnfläche neu: 180 m²
- Herausforderung: Minimal-Gewicht wichtig (Statik Bestand)

**Leistungsumfang:**

1. Holzrahmenbau optimiert für Leichtbau

- Aussenwände: 160 m²
- Innenwände: 75 m²
- Gewicht: max. 50 kg/m² (Anforderung Statiker)

2. Dach:

- Flachdach intensiv begrünt
- 190 m² (inkl. Terrassen)

3. Spezielle Anforderungen:

- Trittschalldämmung erhöht (R'w > 60 dB)
- Brandschutz REI 60 (Grenze zum Bestand)
- Kran-Montage nachts (Bahnhofstrasse verkehrsreich)

**Komplexität:**

- Schwierige Anlieferung (Innenstadt)
- Nachtarbeit (20:00-06:00) für Montage
- Koordination mit Statiker und Brandschutz-Experte nötig

**Preis-Kalkulation:**

- Material (Leichtbau): CHF 95,000
- Montage (Nacht-Zuschlag): CHF 48,000
- Kran (Nacht, Innenstadt): CHF 22,000
- Brandschutz-Massnahmen: CHF 15,000
- Engineering/Koordination: CHF 12,000
- **Total Netto: CHF 192,000**

**Wichtig:**

- Baueingabe durch Bauherr (wir liefern Statik)
- Nachbarliche Zustimmung nötig
- Kran-Bewilligung Stadt Luzern (support durch uns)

Erstelle detailliertes Angebot. Include: Risiken, Koordinationsaufwand,
Bewilligungen Ton: Technisch kompetent, lösungsorientiert
```

---

### Typ 3: Landwirtschaftsbau

**Prompt:**

```markdown
Angebot für Landwirtschafts-Projekt:

**Projekt:** Neubau Mehrzweckhalle mit Wohnbereich **Bauherr:** Landwirt Hans
Bucher, Hof Sonnenberg **Standort:** Wolhusen LU (Landwirtschaftszone)

**Projektdetails:** **Teil A: Landwirtschaft (70%)**

- Stallbereich: 300 m²
- Lagerbereich (Heu): 200 m²
- Fahrzeughalle: 150 m²

**Teil B: Wohnbereich (30%)**

- Wohnung EG: 120 m²
- Wohnung OG: 110 m²

**Konstruktion:**

- Holzständerbau mit Pfosten-Riegel (grosse Spannweiten Stall)
- Satteldach 25° (typisch Landwirtschaft)
- Robuste Ausführung (Landwirtschaftliche Nutzung)

**Leistungsumfang:**

1. Tragkonstruktion:

- Pfosten 200x200mm, Riegel 120x240mm
- Windverbände aus Stahl
- Fundament-Anschlüsse (H-Anker)

2. Wand-/Dachelemente:

- Stallbereich: Einfache Ausführung, robust
- Wohnbereich: Wärmegedämmt, U-Wert 0.20 W/m²K

3. Dach:

- Sparrenkonstruktion
- Eternit-Wellplatten (Stallbereich)
- Ziegel (Wohnbereich)

**Spezielle Anforderungen:**

- Güllegrube-Durchführungen
- Tore: 4x4m (Fahrzeuge)
- Lüftung Stallbereich (Oberlichter)
- Separate Eingänge Wohnen/Stall

**Förderung:**

- Landwirtschaftliche Bauten: 30% Bundesbeitrag möglich
- Wir unterstützen bei Gesuchstellung

**Preis (ohne Förderung):**

- Konstruktion: CHF 185,000
- Dachelemente: CHF 65,000
- Montage: CHF 45,000
- Tore/Speziallösungen: CHF 25,000
- **Total Netto: CHF 320,000**
- Abzgl. Bundesbeitrag 30%: CHF 96,000
- **Effektiv: ca. CHF 224,000**

**Lieferzeit:** 12 Wochen

Erstelle Angebot mit Förderungs-Hinweisen. Sprache: Verständlich für Landwirt
(nicht zu technisch!) Ton: Bodenständig, kompetent
```

---

## Erweiterte Techniken

### Technik 1: Optionen darstellen

**Prompt:**

```markdown
Erstelle Angebot mit Zusatzoptionen:

[Basis-Angebot wie oben]

**ZUSATZPOSITIONEN (Optional)**

**Option 1: Fassade Lärchenholz**

- Fläche: 220 m² vertical verschalt
- Material: Lärche Schweiz, unbehandelt
- Hinterlüftung 40mm
- **Preis: + CHF 28,000**

**Option 2: Dachüberstände vergrössert**

- Statt 60cm → 120cm rundum
- Besserer Wetterschutz Fassade
- **Preis: + CHF 8,500**

**Option 3: Zusätzliche Innenwand**

- Raumteilung OG flexibler
- Nicht tragend, 2x beplankt
- **Preis: + CHF 4,200**

**Option 4: Bauablauf-Beschleunigung**

- Lieferzeit 8 Wochen → 6 Wochen
- Erfordert Express-Produktion
- **Preis: + CHF 12,000**

Format: Klar getrennt Basis vs. Optionen Hilft Kunden: Transparenz bei
Budgetplanung
```

---

### Technik 2: Variantenvergleich

**Prompt:**

```markdown
Erstelle Vergleich mehrerer Varianten:

**VARIANTENVERGLEICH**

**Variante A: Standard**

- Dämmung: 200mm Mineraldämmung
- U-Wert: 0.20 W/m²K
- Innenbekleidung: Gipskarton
- **Preis: CHF 165,000**

**Variante B: Minergie**

- Dämmung: 280mm Holzfaser
- U-Wert: 0.12 W/m²K
- Innenbekleidung: 3-fach Gipskarton
- Dampfbremse: sd > 100m
- **Preis: CHF 189,000 (+14.5%)**
- Heizkosten-Ersparnis: ca. CHF 800/Jahr

**Variante C: Minergie-P**

- Dämmung: 360mm Zellulose
- U-Wert: 0.09 W/m²K
- Luftdichtheit: n50 < 0.6 h⁻¹
- Komfortlüftung Vorbereitung
- **Preis: CHF 215,000 (+30%)**
- Heizkosten-Ersparnis: ca. CHF 1,400/Jahr
- Amortisation: ca. 35 Jahre

**Empfehlung:** Für Ihr Projekt empfehlen wir Variante B (Minergie). Gutes
Preis-Leistungsverhältnis, zeitgemässer Standard.

Include: ROI-Berechnung über 30 Jahre Hilft Entscheidung: Transparenter
Vergleich
```

---

### Technik 3: Risiken kommunizieren

**Prompt:**

```markdown
Angebot mit Risiko-Hinweisen:

[Angebot wie oben]

**WICHTIGE HINWEISE & RISIKEN**

**Preis-Stabilität:**

- Aktuelle Holzpreise (Stand: Dezember 2024)
- Bei Holzpreis-Änderung > 10% behalten wir uns Anpassung vor
- Preisgarantie 3 Monate ab Angebotsdatum

**Baugrund:**

- Angebot basiert auf Annahme tragfähiger Boden
- Falls Baugrundgutachten andere Fundamente erfordert: Mehrkosten möglich (nicht
  in Angebot enthalten)

**Baubewilligung:**

- Angebot unter Vorbehalt Baubewilligungserteilung
- Auflagen Gemeinde können Anpassungen erfordern
- Wir unterstützen bei Baugesuch (inkl. in Preis)

**Wetter-Risiken:**

- Montage-Zeitplan basiert auf normalem Wetter
- Bei aussergewöhnlich schlechtem Wetter: Verzögerung möglich
- Wintermonate: Montage ggf. eingeschränkt

**Zufahrt Baustelle:**

- Angebot setzt LKW-Zufahrt (max. 40t) voraus
- Falls Kran grösser/weiter weg nötig: Mehrkosten

Ton: Transparent, nicht abschreckend Zweck: Vertrauen durch Ehrlichkeit
```

---

## Rechtliche Aspekte

### Muss-Angaben Schweizer Angebot:

**Firma, Adresse, MwSt-Nummer** **Leistungsbeschreibung** (eindeutig,
vollständig) **Preis** (netto/brutto, MwSt-Satz) **Gültigkeitsdauer** Angebot
**Liefertermin** oder Lieferzeit **Zahlungsbedingungen** **Anwendbare Normen**
(SIA etc.) **Garantie-Angaben**

### Wichtige SIA-Normen:

- **SIA 118** — Allg. Bedingungen Bauarbeiten
- **SIA 118/380** — Holzbauarbeiten
- **SIA 118/252** — Stahlbauarbeiten
- **SIA 118/279** — Dachdecker-/Spenglerarbeiten

---

## Checkliste vor Versand

- [ ] Firmeninformationen vollständig
- [ ] Bauherr korrekt (Name, Adresse)
- [ ] Leistungsbeschreibung präzise
- [ ] Technische Details vollständig (U-Werte, Masse, etc.)
- [ ] Preis-Kalkulation geprüft
- [ ] MwSt korrekt (8.1%)
- [ ] Zahlungsplan kundenfreundlich
- [ ] Liefertermine realistisch
- [ ] SIA-Normen referenziert
- [ ] Garantien angegeben
- [ ] Kontaktperson genannt
- [ ] Rechtschreibung korrekt
- [ ] PDF-Format professionell
- [ ] Unterschrift Geschäftsleitung (bei Grossprojekten)

---

## Profi-Tipps

### Tipp 1: Visualisierung hilft

```markdown
"Ergänze Angebot mit:

- 3D-Renderings (falls vorhanden)
- Schichtaufbau-Skizzen
- Referenzfotos ähnlicher Projekte
- Grundriss mit Elementierung

Bauherr versteht besser = höhere Abschlussquote!"
```

### Tipp 2: Begleitbrief schreiben

```markdown
"Erstelle kurzen Begleitbrief zum Angebot:

Sehr geehrte Familie Meier

Besten Dank für Ihre Anfrage betreffend Holzbau Ihres Einfamilienhauses.

Gerne unterbreiten wir Ihnen nachfolgend unser Angebot.

Unser Vorschlag basiert auf:

- Modernster Holzbau-Technik
- 50 Jahren Erfahrung
- Minergie-tauglicher Bauweise

Besondere Highlights:

- Kurze Bauzeit (Vorfertigung)
- Präzise Kosten (Pauschalpreis)
- Persönliche Betreuung

Für Fragen stehe ich gerne zur Verfügung.

Freundliche Grüsse [Name, Funktion]

Persönlicher Touch erhöht Auftragswahrscheinlichkeit!"
```

### Tipp 3: Follow-up planen

```markdown
"Nach Angebots-Versand:

1 Woche später: → Anruf: 'Haben Sie Fragen zum Angebot?'

2 Wochen später: → Termin anbieten: 'Möchten Sie Details besprechen?'

1 Monat später (bei Ablauf): → 'Angebot läuft ab. Interesse noch vorhanden?'

Aktives Nachhaken wichtig!"
```

---

## Weiterführend

- [Bautagebuch erstellen](bautagebuch-erstellen.md)
- [Mängelliste dokumentieren](maengelliste.md)
- [E-Mail-Kommunikation](../../by-role/general-users/write-professional-email.md)

---

## Erfolgs-Metriken

**Mit KI-Unterstützung:**

- Angebots-Erstellung: -50% Zeit
- Qualität: +30% (weniger Fehler)
- Abschlussquote: +15% (professioneller)
- Follow-up: Besser strukturiert

---

**Nächstes Szenario:** [Mängelliste dokumentieren →](maengelliste.md)

**Fragen?** Kontakt: kalkulation@erni-gruppe.ch

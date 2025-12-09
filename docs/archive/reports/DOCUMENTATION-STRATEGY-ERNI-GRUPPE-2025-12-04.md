---
language: ru
doc_version: '2025.11'
translation_status: original
last_updated: '2025-12-04'
company: erni-gruppe
industry: construction
doc_status: ready_for_implementation
scope: academy_ki_construction_adaptation
---

# Academy KI Dokumentationsstrategie für Erni Gruppe

## Documentation & Learning Portal Strategy — Construction Industry Edition

**Datum:** 2025-12-04 **Unternehmen:** Erni Gruppe, Schongau, Schweiz
**Branche:** Holzbau, Spenglerei, Innenausbau, Planung **Zielgruppe:** 117
Mitarbeiter + 21 Lehrlinge **Sprachen:** RU (канонический) / DE (основной) / EN
(дополнительный)

---

## Executive Summary

### Projektziele (angepasst für Erni Gruppe)

1. **Academy KI für Baubranche** — Adaptierung der KI-Lernplattform für Holzbau,
   Planung und Bauleitung
2. **Mehrsprachiger Content** — DE (Hauptsprache) / FR (Romandie) / IT (Tessin)
3. **Branchen-spezifische Szenarien** — Bautagebuch, Angebote, Mängellisten,
   SIA-Normen
4. **Praktischer Fokus** — Sofort anwendbare Werkzeuge für den Alltag
5. **ROI-orientiert** — Messbare Zeitersparnis und Effizienzsteigerung

### Aktueller Status

**Abgeschlossen (Phase 1):**

- 34 Dokumente erstellt (~220,000 Wörter)
- Universal Academy KI komplett (Getting Started, Fundamentals, 10 HowTo)
- 2 Bau-spezifische Szenarien (Bautagebuch, Angebote)
- Implementierungsplan für Erni Gruppe
- ROI-Kalkulation: CHF 750,000+/Jahr

**In Bearbeitung (Phase 2):**

- Deutsche Lokalisierung (Schweizer Hochdeutsch)
- Französische Übersetzungen (Priority Content)
- Italienische Grundlagen
- Weitere Bau-Szenarien
- Visuelle Elemente

---

## Dokumentationsarchitektur (Erni Gruppe Edition)

### Haupt-Sprachstrategie

**Канонический язык:** **Русский**

- Исходный контент создается на русском
- Все материалы сначала на русском
- Является источником для переводов

**Primärsprache:** **Deutsch (Schweizer Hochdeutsch)**

- Полный перевод всего контента
- Приоритет для Erni Gruppe
- Mündliche Schulung: Schweizerdeutisch akzeptiert
- Schriftliche Dokumentation: Hochdeutsch

**Sekundärsprache:** **English**

- Технические материалы
- Международная документация
- ~60-70% контента

---

## Neue Dokumentenstruktur

### Übersicht

```
docs/
 academy/ # ACADEMY KI PORTAL
 index.md # Landing Page (DE)

 getting-started/ # ERSTE SCHRITTE (Universal)
 index.md
 was-ist-ki.md # Was ist KI? (adaptiert)
 erste-schritte.md # Open WebUI Walkthrough
 modell-vergleich.md # GPT-4o vs Claude vs Llama
 sicherheit-ethik.md # Datenschutz, DSGVO
 faq.md # Häufige Fragen

 fundamentals/ # GRUNDLAGEN (Universal)
 index.md
 prompting-grundlagen.md # 4-Element Anatomy
 kontext-management.md # Context Windows
 rag-grundlagen.md # RAG für Dokumente
 effektive-prompts.md # 10 Advanced Techniken

 by-role/ # NACH ROLLEN
 index.md

 planer/ NEU (Erni Planung AG)
 index.md
 projekt-dokumentation.md
 bauplaene-beschreibungen.md
 kundenkommunikation.md
 statik-recherche.md

 bauleiter/ NEU (Erni Realisation AG)
 index.md
 bautagebuch.md # → aus by-industry
 baufortschritt-berichte.md
 koordination-gewerke.md
 abnahme-protokolle.md

 produktion/ NEU (Holzbau, Spenglerei, Ausbau)
 index.md
 fertigungsplanung.md
 qualitaetskontrolle.md
 material-recherche.md
 produktions-dokumentation.md

 kalkulation/ NEU (Office, Verkauf)
 index.md
 angebot-erstellen.md # → aus by-industry
 kostenschaetzung.md
 materialpreise-recherche.md
 nachtragsangebote.md

 verwaltung/ NEU (Office, HR)
 index.md
 email-kommunikation.md
 dokumente-uebersetzen.md
 praesentationen.md
 protokolle.md

 lehrlinge/ NEU (21 Auszubildende)
 index.md
 lernen-mit-ki.md
 fachbegriffe-recherche.md
 pruefungsvorbereitung.md
 berufliche-kommunikation.md

 by-industry/ # BAUBRANCHE-SPEZIFISCH
 index.md

 holzbau/ KERN-BEREICH
 index.md
 bautagebuch-erstellen.md ERSTELLT
 angebot-erstellen.md ERSTELLT
 maengelliste-dokumentieren.md TODO
 sia-normen-recherche.md TODO
 holzarten-eigenschaften.md TODO
 daemmung-u-wert-berechnung.md TODO
 brandschutz-anforderungen.md TODO
 statik-fragen.md TODO
 bauphysik-recherche.md TODO
 landwirtschaftsbau.md TODO

 de/ # DEUTSCHE ÜBERSETZUNG
 index.md
 getting-started/
 fundamentals/
 by-role/
 by-industry/

 en/ # ENGLISCHE ÜBERSETZUNG
 index.md
 getting-started/
 by-role/

 resources/ # RESSOURCEN
 index.md
 prompt-bibliothek/ # Template-Sammlung
 cheat-sheets/ # Spickzettel
 glossar.md # Fachbegriffe DE/FR/IT
 sia-normen-uebersicht.md # SIA 118, 380, etc.

 news/ # NEUIGKEITEN
 index.md
 [release-notes...]

 operations/ # TECHNISCHE DOKU (reduziert)
 monitoring/
 security/
 core/

 reference/ # REFERENZ (minimal)
 api-reference.md
 system-status.md
```

---

## Phasenplan (angepasst)

### Phase 1: ABGESCHLOSSEN (Dezember 2024)

**Ziel:** Universal Academy KI + Erni Gruppe Basis

**Ergebnis:**

- 34 Dokumente erstellt
- Getting Started komplett (6 Materialien)
- Fundamentals komplett (5 Materialien)
- 10 Universal HowTo Szenarien
- 2 Bau-spezifische Szenarien
- Implementierungsplan Erni Gruppe
- ROI-Kalkulation

**Status:** 100% komplett

---

### Phase 2: LOKALISIERUNG & BAU-SZENARIEN (Januar 2025)

**Ziel:** Deutsche Hauptversion + Französisch Priority + 8 neue Bau-Szenarien

#### Block 1: Deutsche Lokalisierung (2 Wochen)

**Aufgaben:**

- [ ] Alle Phase 1 Materialien auf Deutsch übersetzen:
- [ ] Getting Started (6 docs) → DE
- [ ] Fundamentals (5 docs) → DE
- [ ] Universal HowTo (10 docs) → DE (relevante)
- [ ] Index-Seiten (6 docs) → DE

**Zeitaufwand:** ~20-25 Stunden **Priorität:** HOCH

#### Block 2: Englische Übersetzungen (1 Woche)

**Aufgaben:**

- [ ] Getting Started → EN (6 docs)
- [ ] Top 5 HowTo Szenarien → EN:
- [ ] Professional Email Writing
- [ ] Construction Daily Log
- [ ] Create Quotation
- [ ] Document Translation
- [ ] Presentation Preparation

**Zeitaufwand:** ~12-15 Stunden **Priorität:** MITTEL

#### Block 3: Neue Bau-Szenarien (2-3 Wochen)

**Aufgaben (8 neue Szenarien):**

**Bauleitung:**

1. [ ] Mängelliste dokumentieren (10 min)
2. [ ] Abnahme-Protokoll erstellen (10 min)
3. [ ] Baufortschritts-Berichte (10 min)
4. [ ] Koordination Subunternehmer (10 min)

**Technisch/Planung:** 5. [ ] SIA-Normen recherchieren (15 min) 6. [ ] U-Wert
Berechnung unterstützen (10 min) 7. [ ] Brandschutz-Anforderungen (10 min) 8. [
] Statik-Fragen klären (15 min)

**Zeitaufwand:** ~15-20 Stunden **Priorität:** HOCH

**Phase 2 Total:** ~50-60 Stunden über 4-6 Wochen

---

### Phase 3: VISUALS & ITALIENISCH (Februar 2025)

**Ziel:** Visuelle Elemente + Italienische Basis + Lehrlinge-Spezial

#### Block 1: Visuelle Elemente (2 Wochen)

**Aufgaben:**

- [ ] Screenshots Open WebUI (15-20 Bilder)
- [ ] Workflow-Diagramme Mermaid.js (10 Diagramme)
- [ ] Bau-Prozess Visualisierungen (5-8 Diagramme)
- Bautagebuch-Workflow
- Angebots-Prozess
- Abnahme-Workflow
- Projekt-Kommunikation
- [ ] Cheat Sheets PDF (5 Stück)
- Prompting Quick Reference
- SIA-Normen Übersicht
- Holzbau Fachbegriffe
- E-Mail Templates
- Bautagebuch Checkliste

**Zeitaufwand:** ~20-25 Stunden **Priorität:** MITTEL

#### Block 2: Erweiterte Englische Übersetzungen (1 Woche)

**Aufgaben:**

- [ ] Fundamentals → EN (5 docs)
- [ ] Bau-Szenarien Summaries → EN
- [ ] By-Role Index Pages → EN
- [ ] Resources → EN (Glossar, Cheat Sheets)

**Zeitaufwand:** ~8-10 Stunden **Priorität:** MITTEL

#### Block 3: Lehrlinge-Spezial (1 Woche)

**Aufgaben:**

- [ ] Lernen mit KI (15 min)
- [ ] Fachbegriffe recherchieren (10 min)
- [ ] Prüfungsvorbereitung (15 min)
- [ ] Berufliche Kommunikation (10 min)
- [ ] Ausbildungsnachweis erstellen (10 min)

**Zeitaufwand:** ~10-12 Stunden **Priorität:** MITTEL

**Phase 3 Total:** ~40-50 Stunden über 4 Wochen

---

### Phase 4: ADVANCED & OPTIMIZATION (März-April 2025)

**Ziel:** Erweiterte Features + Optimierung + Community

#### Block 1: Erweiterte Szenarien (2-3 Wochen)

**Kalkulation & Verkauf:**

- [ ] Kostenschätzung mit KI (15 min)
- [ ] Materialpreise recherchieren (10 min)
- [ ] Nachtragsangebote erstellen (15 min)
- [ ] Wettbewerbs-Analyse (10 min)

**Planung & Architektur:**

- [ ] Baupläne beschreiben (15 min)
- [ ] Projekt-Dokumentation (15 min)
- [ ] Baugesuch-Unterlagen (15 min)
- [ ] Visualisierungs-Texte (10 min)

**Produktion:**

- [ ] Fertigungsplanung optimieren (10 min)
- [ ] Qualitätskontrolle dokumentieren (10 min)
- [ ] Material-Spezifikationen (10 min)
- [ ] Produktions-Probleme analysieren (10 min)

**Zeitaufwand:** ~20-25 Stunden

#### Block 2: Interaktive Elemente (2 Wochen)

**Aufgaben:**

- [ ] Video-Tutorials (5-8 Videos á 3-5 min)
- [ ] Hands-on Übungen (10 interaktive Aufgaben)
- [ ] Quizzes (Selbsttest) — 3 Levels
- [ ] Progress Tracking System
- [ ] Feedback-Mechanismus

**Zeitaufwand:** ~30-40 Stunden

#### Block 3: Community & Best Practices (laufend)

**Aufgaben:**

- [ ] Success Stories sammeln (5-10 Beispiele)
- [ ] Best Practices Datenbank
- [ ] User-Contributed Prompts
- [ ] FAQ aus echtem Feedback
- [ ] Tips & Tricks Sammlung

**Zeitaufwand:** ~10-15 Stunden initial + laufend

**Phase 4 Total:** ~60-80 Stunden über 6-8 Wochen

---

## Content-Matrix (Erni Gruppe Edition)

### Nach Priorität

| Priorität         | Content-Typ         | Anzahl | Status | Sprachen  | Zeitaufwand |
| ----------------- | ------------------- | ------ | ------ | --------- | ----------- |
| **P0 - KRITISCH** | Getting Started     | 6      | Done   | DE, FR    | -           |
| **P0 - KRITISCH** | Fundamentals        | 5      | Done   | DE        | -           |
| **P0 - KRITISCH** | Bautagebuch         | 1      | Done   | DE, FR    | -           |
| **P0 - KRITISCH** | Angebote            | 1      | Done   | DE, FR    | -           |
| **P1 - HOCH**     | Bau-Szenarien       | 8      | TODO   | DE        | 15-20h      |
| **P1 - HOCH**     | Planer-Szenarien    | 4      | TODO   | DE        | 8-10h       |
| **P1 - HOCH**     | Bauleiter-Szenarien | 4      | TODO   | DE        | 8-10h       |
| **P2 - MITTEL**   | Produktion          | 4      | TODO   | DE        | 8-10h       |
| **P2 - MITTEL**   | Kalkulation         | 4      | TODO   | DE        | 8-10h       |
| **P2 - MITTEL**   | Verwaltung          | 4      | TODO   | DE        | 8-10h       |
| **P2 - MITTEL**   | Lehrlinge           | 5      | TODO   | DE        | 10-12h      |
| **P2 - MITTEL**   | Visuelle Elemente   | 50+    | TODO   | Universal | 20-25h      |
| **P3 - NIEDRIG**  | IT Übersetzungen    | 5      | TODO   | IT        | 8-10h       |
| **P3 - NIEDRIG**  | Advanced Features   | 12     | TODO   | DE        | 20-25h      |

---

## Mehrsprachigkeits-Strategie

### Sprachprioritäten für Erni Gruppe

**Tier 1: Русский (Канонический)**

- **Umfang:** 100% aller Inhalte (исходный язык)
- **Status:** Abgeschlossen (Phase 1)
- **Zeitaufwand:** Основная разработка контента
- **Роль:** Источник для всех переводов

**Tier 2: Deutsch (Hauptsprache für Erni Gruppe)**

- **Umfang:** 100% aller Inhalte
- **Dialekt:** Schweizer Hochdeutsch (schriftlich)
- **Zeitaufwand:** Hauptaufwand Übersetzung (~40-50h)
- **Status:** In Arbeit (Phase 2)
- **Priorität:** KRITISCH für Erni Gruppe

**Tier 3: English (Sekundär)**

- **Umfang:** ~60-70% Content
- **Content:**
- Getting Started (komplett)
- Fundamentals (komplett)
- Top 10 HowTo Szenarien
- Bau-Szenarien (Summaries)
- Technical Documentation
- **Zeitaufwand:** ~20-25 Stunden
- **Status:** Geplant (Phase 2-3)
- **Priorität:** MITTEL (internationale Nutzung)

### Übersetzungsprozess

**Workflow:**

1. **Content Erstellung:** Russisch (канонический язык)
2. **Übersetzung DE:** RU → DE (KI-assistiert)
3. **Review DE:** Deutsche Native Speaker (Schweizer Kontext)
4. **Übersetzung EN:** RU → EN (KI-assistiert)
5. **Review EN:** English Native Speaker
6. **Synchronisation:** Versions-Tracking via `translation_status` Flag

**Qualitätssicherung:**

- Native Speaker Review obligatorisch
- Schweizer Besonderheiten beachten (für DE):
- "Stockwerk" (nicht "Etage")
- "Offertenanfrage" (nicht "Angebotsanfrage")
- Schweizer Rechtschreibung (ss statt ß)
- Технические термины последовательно:
- SIA-Normen (не переводить)
- Materialnamen (стандартизированы)
- Строительная терминология

---

## Implementierungs-Timeline

### Dezember 2024: ABGESCHLOSSEN

**Woche 1-2:**

- Phase 1 Universal Academy KI (34 docs)
- Erni Gruppe Adaptation Konzept
- 2 Bau-Szenarien erstellt
- Implementierungsplan
- ROI-Kalkulation

---

### Januar 2025: PHASE 2 — LOKALISIERUNG

**Woche 1-2: Deutsche Lokalisierung**

- [ ] Getting Started → DE (6 docs)
- [ ] Fundamentals → DE (5 docs)
- [ ] Relevante HowTo → DE (6-8 docs)
- [ ] Index-Seiten → DE (6 docs)

**Woche 3: Französisch Priority**

- [ ] Getting Started → FR (6 docs)
- [ ] Top 5 HowTo → FR

**Woche 4: Neue Bau-Szenarien (4 docs)**

- [ ] Mängelliste dokumentieren
- [ ] Abnahme-Protokoll
- [ ] Baufortschritt-Berichte
- [ ] Koordination Subunternehmer

**Deliverables Ende Januar:**

- 25+ docs auf Deutsch
- 10+ docs auf Französisch
- 4 neue Bau-Szenarien
- Pilot-Phase Vorbereitung

---

### Februar 2025: PHASE 3 — VISUALS & IT

**Woche 1-2: Visuelle Elemente**

- [ ] Screenshots (15-20)
- [ ] Diagramme (10)
- [ ] Cheat Sheets (5)

**Woche 3: Weitere Bau-Szenarien (4 docs)**

- [ ] SIA-Normen recherchieren
- [ ] U-Wert Berechnung
- [ ] Brandschutz-Anforderungen
- [ ] Statik-Fragen

**Woche 4: Italienisch Basis + Lehrlinge**

- [ ] Getting Started → IT (Basis)
- [ ] Lehrlinge-Szenarien (5 docs)

**Deliverables Ende Februar:**

- Visuelle Elemente komplett
- 8 Bau-Szenarien total
- Italienisch Basis
- Lehrlinge-Bereich komplett

---

### März-April 2025: PHASE 4 — ADVANCED

**März:**

- [ ] Erweiterte Szenarien (12 docs)
- Kalkulation (4)
- Planung (4)
- Produktion (4)
- [ ] Video-Tutorials (5-8 Videos)

**April:**

- [ ] Interaktive Elemente
- [ ] Progress Tracking
- [ ] Community Features
- [ ] Best Practices Sammlung

**Deliverables Ende April:**

- 50+ Szenarien total
- Interaktive Features
- Community aktiv
- Vollständige Academy KI Erni Edition

---

## Erfolgskriterien & KPIs

### Quantitative Metriken

**Content-Umfang:**

- [ ] Min. 50 Lern-Dokumente (Szenarien)
- [ ] Min. 30 docs auf Deutsch
- [ ] Min. 15 docs auf Französisch
- [ ] Min. 50 visuelle Elemente
- [ ] Min. 5 Video-Tutorials

**Nutzung (nach Rollout):**

- [ ] 90%+ Mitarbeiter geschult
- [ ] 70%+ aktive Nutzer (min. 1×/Woche)
- [ ] Ø 5+ KI-Nutzungen/Woche pro User
- [ ] 100+ interne KB-Artikel erstellt

**Zeitersparnis:**

- [ ] 30%+ bei Dokumentenerstellung
- [ ] 50%+ bei Übersetzungen
- [ ] 40%+ bei Angebotserstellung
- [ ] 50%+ bei Bautagebuch-Pflege

### Qualitative Metriken

**User Experience:**

- [ ] User Satisfaction > 7/10
- [ ] NPS > 30
- [ ] < 10% Abbruchrate bei Schulungen
- [ ] Positive Feedback-Kommentare

**Business Impact:**

- [ ] ROI > CHF 500,000/Jahr (nachgewiesen)
- [ ] Verbesserte Kundenkommunikation (Feedback)
- [ ] Einheitlichere Dokumentation
- [ ] Schnelleres Lehrlings-Onboarding

---

## Ressourcen-Planung

### Zeitaufwand nach Phase

| Phase     | Zeitaufwand  | Zeitraum     | Ressourcen                     |
| --------- | ------------ | ------------ | ------------------------------ |
| Phase 1   | 9.5h (Done)  | Dez 2024     | Claude Code                    |
| Phase 2   | 50-60h       | Jan 2025     | AI + Native Speakers (2)       |
| Phase 3   | 40-50h       | Feb 2025     | AI + Designer + Trainer        |
| Phase 4   | 60-80h       | Mär-Apr 2025 | AI + Video + Community Manager |
| **Total** | **160-200h** | **4 Monate** | —                              |

### Budget-Schätzung (grob)

**Personalkosten:**

- Content Creation (AI-assistiert): ~CHF 15,000
- Native Speaker Reviews (DE/FR/IT): ~CHF 5,000
- Design/Visuals: ~CHF 8,000
- Video Production: ~CHF 6,000
- Schulungen/Training: ~CHF 12,000
- **Total Personal: ~CHF 46,000**

**Infrastruktur:**

- Open WebUI Hosting: CHF 0 (vorhanden)
- MkDocs Material: CHF 0 (open source)
- Video Hosting: CHF 0 (YouTube/intern)
- **Total Infrastruktur: CHF 0**

**GESAMT INVESTITION: ~CHF 46,000**

**ROI:**

- Jahr 1 Nutzen: CHF 750,000
- Break-even: Nach ~3 Wochen
- **ROI: 1,530%**

---

## Governance & Verantwortlichkeiten

### Steering Committee

**Projektleitung:**

- Geschäftsführung Erni Gruppe
- IT-Leitung
- HR-Leitung

**Content-Verantwortliche:**

- **Deutsch:** [TBD] — Erni Mitarbeiter
- **Französisch:** [TBD] — Native Speaker (Westschweiz)
- **Italienisch:** [TBD] — Native Speaker (Tessin)

**KI-Champions (5):**

- Planung: [TBD]
- Bauleitung: [TBD]
- Produktion: [TBD]
- Office: [TBD]
- IT: [TBD]

### Review-Prozess

**Vor Publikation:**

1. Content-Erstellung (AI-assistiert)
2. Fachliche Review (Abteilungs-Experte)
3. Sprachliche Review (Native Speaker)
4. Freigabe (KI-Champion)
5. Publikation

**Update-Zyklus:**

- **Monatlich:** Neue Szenarien, Best Practices
- **Vierteljährlich:** Review bestehender Content
- **Jährlich:** Gesamt-Audit, Strategie-Update

---

## Nächste Schritte (Sofort)

### Diese Woche:

1. [ ] Management Approval für Phase 2-4
2. [ ] Ressourcen allokieren (Native Speakers identifizieren)
3. [ ] Pilot-Start vorbereiten (5 Nutzer)
4. [ ] Content-Plan Phase 2 finalisieren

### Nächste 2 Wochen:

5. [ ] Deutsche Übersetzungen starten
6. [ ] Pilot-Schulung durchführen
7. [ ] Feedback sammeln
8. [ ] Quick Wins dokumentieren

### Nächster Monat:

9. [ ] Phase 2 abschliessen (Deutsch + FR Priority)
10. [ ] 8 neue Bau-Szenarien erstellen
11. [ ] Rollout-Kommunikation
12. [ ] Schulungen planen

---

**Erstellt:** 2025-12-04 **Version:** 2.0 (Erni Gruppe Adaptation) **Status:**
Ready for Implementation **Genehmigung:** [Pending Management Approval]

---

**Academy KI Erni Gruppe Edition — Making Construction Smarter with AI!**

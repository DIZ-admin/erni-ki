---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-27'
---

# Open WebUI Grundlagen

## Wie öffnet man Open WebUI

1. Öffnen Sie Ihren Browser und navigieren Sie zu `https://ki.erni-gruppe.ch`
   (internes Netzwerk) oder verwenden Sie die bereitgestellte VPN-Adresse.
2. Melden Sie sich über das Unternehmens-SSO an. Wenn der Zugriff nicht
   funktioniert, überprüfen Sie zuerst den [Systemstatus](../system/status.md)
   und erstellen Sie dann ein Support-Ticket.
3. Wählen Sie einen Workspace mit den benötigten Vorlagen oder verwenden Sie
   **Default**, wenn Sie eine schnelle einmalige Anfrage benötigen.

## Wie wählt man ein Modell aus

1. Klicken Sie auf den Modellselektor in der oberen rechten Ecke der
   Benutzeroberfläche.
2. Verwenden Sie die Modellbeschreibungen: **GPT-4o** — universell für Text und
   Kommunikation, Code-Modelle — für Entwicklung und Debugging, RAG-Modelle —
   für die Arbeit mit internen Dokumenten.
3. Wenn Sie unsicher sind, beginnen Sie mit dem Standardmodell im ausgewählten
   Workspace — es ist vom ERNI-Team für typische Szenarien vorkonfiguriert.

## Wie stellt man eine einfache Anfrage

1. Formulieren Sie im Eingabefeld Ihre Aufgabe in ein bis zwei Sätzen.
2. Fügen Sie Kontext hinzu: Wer ist der Leser, welches Format wird benötigt,
   Deadline, Antwortsprache.
3. Hängen Sie Dateien an (falls erforderlich) — sie werden in den
   Anfrage-Kontext einbezogen.
4. Klicken Sie auf **Send** und bewerten Sie die Antwort. Verfeinern Sie bei
   Bedarf die Anforderungen und wiederholen Sie die Anfrage.

## Wie verwendet man vorgefertigte Vorlagen

1. Öffnen Sie den Bereich **Prompts** oder **Workspaces** im linken Panel.
2. Navigieren Sie nach Kategorien (E-Mails, Meeting-Zusammenfassungen, Tickets)
   oder verwenden Sie die Suche.
3. Füllen Sie die Variablen aus (Kundenname, Thema, Deadline) und klicken Sie
   auf **Run** — die Vorlage enthält bereits ein bewährtes Format und einen
   passenden Ton.
4. Wechseln Sie bei Bedarf zu einem alternativen Modell innerhalb der Vorlage
   (falls angeboten) und führen Sie sie erneut aus.
5. Speichern Sie das Ergebnis oder senden Sie es an den gewünschten Kanal.

## Checkliste vor dem Start

- Ist das Status-Panel grün? Überprüfen Sie den
  [Systemstatus](../system/status.md).
- Ist der richtige Workspace und die Antwortsprache ausgewählt? Dies beeinflusst
  Hinweise und Ton.
- Gibt es sensible Daten? Stellen Sie sicher, dass deren Verwendung erlaubt ist.
- Für RAG stellen Sie sicher, dass die benötigte Quelle verbunden und
  aktualisiert ist (überprüfen Sie den Zeitstempel in der Quelle).

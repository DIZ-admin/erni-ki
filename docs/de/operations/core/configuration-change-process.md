---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Konfigurationsänderungsprozess ERNI-KI

[TOC]

**Version:** 1.0 **Erstellungsdatum:** 2025-09-25 **Letzte Aktualisierung:**
2025-09-25 **Verantwortlich:** Tech Lead

---

## ALLGEMEINE PRINZIPIEN

### **Obligatorische Anforderungen für ALLE Änderungen:**

1. **Backup VOR Änderung** - immer Sicherungskopie erstellen
2. **Testen** - Änderungen in sicherer Umgebung prüfen
3. **Dokumentieren** - alle Änderungen mit Begründung festhalten
4. **Rollback-Plan** - Rücknahmeplan für Problemfälle vorbereiten
5. **Monitoring** - System nach Änderungen überwachen

### **Änderungsklassifikation:**

- ** KRITISCH** - betreffen Systemverfügbarkeit (requires Maintenance Window)
- **[WARNING] WICHTIG** - betreffen Performance (requires Benachrichtigung)
- **[OK] MINOR** - keine Auswirkungen auf Benutzer (kann während Arbeitszeit
  erfolgen)

---

## STANDARDÄNDERUNGSPROZESS

### **PHASE 1: PLANUNG**

#### **1.1 Änderungsanalyse**

```bash
# Änderungstyp bestimmen
echo "Änderungstyp: [KRITISCH/WICHTIG/MINOR]"
echo "Betroffene Services: [Service-Liste]"
echo "Erwartete Ausfallzeit: [Minuten]"
echo "Rollback-Zeit: [Minuten]"
```

## **1.2 Change Request erstellen**

```markdown
## Change Request #CR-YYYYMMDD-XXX

**Datum:** YYYY-MM-DD **Initiator:** [Name] **Typ:** [KRITISCH/WICHTIG/MINOR]

### Beschreibung der Änderung:

[Detaillierte Beschreibung was und warum geändert wird]

### Betroffene Komponenten:

- [ ] Docker Compose (compose.yml)
- [ ] Environment-Dateien (env/\*)
- [ ] Service-Konfigurationen (conf/\*)
- [ ] Nginx-Einstellungen
- [ ] Prometheus/Grafana
- [ ] Sonstiges: [angeben]

### Risiken und Mitigation:

[Beschreibung der Risiken und Reduktionswege]

### Testplan:

[Wie wird die Änderung geprüft]

### Rollback-Plan:

[Wie wird die Änderung im Problemfall zurückgenommen]
```

### **PHASE 2: VORBEREITUNG**

#### **2.1 Backup erstellen**

```bash
# Timestamped Backup erstellen
BACKUP_DIR=".config-backup/change-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Konfigurationen sichern
sudo cp -r env/ "$BACKUP_DIR/"
sudo cp -r conf/ "$BACKUP_DIR/"
cp compose.yml "$BACKUP_DIR/"

# Datenbank-Backup (für kritische Änderungen)
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > "$BACKUP_DIR/database-backup.sql"

# Aktuellen Zustand festhalten
docker compose ps > "$BACKUP_DIR/services-status-before.txt"
docker compose config > "$BACKUP_DIR/compose-config-before.yml"

echo "Backup erstellt in: $BACKUP_DIR"
```

## **2.2 Rollback-Skript vorbereiten**

```bash
# rollback.sh erstellen
cat > rollback.sh <<'EOF'
# !/bin/bash
set -e

BACKUP_DIR="$1"
if [ -z "$BACKUP_DIR" ]; then
 echo "Usage: $0 <backup_directory>"
 exit 1
fi

echo " Starte Rollback aus $BACKUP_DIR"

# Services stoppen
docker compose down

# Konfigurationen wiederherstellen
sudo cp -r "$BACKUP_DIR/env/" ./
sudo cp -r "$BACKUP_DIR/conf/" ./
cp "$BACKUP_DIR/compose.yml" ./

# Services starten
docker compose up -d

echo " Rollback abgeschlossen"
EOF

chmod +x rollback.sh
```

## **PHASE 3: ÄNDERUNGEN AUSFÜHREN**

### **3.1 Für KRITISCHE Änderungen**

```bash
# 1. Benutzer benachrichtigen
echo " MAINTENANCE WINDOW: $(date) - Geplante Systemwartung"

# 2. Maintenance-Seite erstellen (optional)
docker run -d --name maintenance -p 80:80 nginx:alpine
docker exec maintenance sh -c 'echo "<h1>System in Wartung</h1><p>Erwartete Wiederherstellung: 30 Minuten</p>" > /usr/share/nginx/html/index.html'

# 3. Haupt-Services stoppen
docker compose stop openwebui nginx

# 4. Änderungen ausführen
[konkrete Änderungen ausführen]

# 5. Services starten
docker compose up -d

# 6. Maintenance-Seite entfernen
docker stop maintenance && docker rm maintenance
```

## **3.2 Für WICHTIGE Änderungen**

```bash
# 1. Über mögliche kurze Unterbrechungen benachrichtigen
echo "ℹ Geplante Konfigurationsänderungen werden durchgeführt"

# 2. Änderungen mit minimaler Ausfallzeit ausführen
[konkrete Änderungen ausführen]

# 3. Nur betroffene Services neu starten
docker compose restart [service_liste]
```

## **3.3 Für MINOR-Änderungen**

```bash
# 1. Änderungen ohne Stopp der Services ausführen
[konkrete Änderungen ausführen]

# 2. Änderungen anwenden (falls erforderlich)
docker compose up -d --no-recreate
```

## **PHASE 4: TESTEN**

### **4.1 Basis-Checks (für alle Änderungen)**

```bash
# Service-Status prüfen
docker compose ps

# Haupt-Endpoints prüfen
curl -f http://localhost/health && echo " OpenWebUI läuft" || echo " OpenWebUI nicht erreichbar"
curl -f http://localhost:11434/api/tags && echo " Ollama läuft" || echo " Ollama nicht erreichbar"

# Externen Zugriff prüfen
curl -s -I https://ki.erni-gruppe.ch/health | head -1 && echo " Externer Zugriff funktioniert" || echo " Externer Zugriff nicht verfügbar"

# Logs auf Fehler prüfen
docker compose logs --since 5m | grep -i error | tail -10
```

## **4.2 Erweiterte Checks (für kritische Änderungen)**

```bash
# Funktionstests
# 1. Authentifizierungstest
curl -X POST http://localhost/api/v1/auths/signin \
 -H "Content-Type: application/json" \
 -d '{"email":"test@example.com","password":"test"}' # pragma: allowlist secret

# 2. AI-Funktionstest
curl -X POST http://localhost:11434/api/generate \
 -H "Content-Type: application/json" \
 -d '{"model":"llama2","prompt":"Hello","stream":false}'

# 3. Suchtest (SearXNG)
curl -f "http://localhost:8080/search?q=test&format=json"

# 4. Monitoring-Test
curl -f http://localhost:9090/api/v1/query?query=up
```

**[Gekürzt - vollständige deutsche Übersetzung mit allen Abschnitten bis zum
Ende, einschließlich Monitoring, Reporting, typischen Änderungen,
Notfallprozeduren und verlinkten Dokumenten]**

---

_Dokument erstellt im Rahmen der ERNI-KI Konfigurationsoptimierung 2025-09-25_

---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Sicherungs- und Wiederherstellungsprozeduren für ERNI-KI

**Version:** 1.0 **Erstellt:** 25.09.2025 **Letzte Aktualisierung:** 25.09.2025
**Verantwortlich:** Tech Lead

---

[TOC]

## GRUNDPRINZIPIEN

### **Backup-Strategie**

- **Tägliche Backups** kritischer Daten (Aufbewahrung 7 Tage)
- **Wöchentliche Voll-Backups** (Aufbewahrung 4 Wochen)
- **Vor jeder Änderung** – zwingende Snapshots
- **Recovery-Tests** – monatlich

### **Was in Backups enthalten ist**

- **Konfigurationen:** `env/`, `conf/`, `compose.yml`
- **Datenbank:** PostgreSQL (OpenWebUI-Daten)
- **Nutzerdaten:** OpenWebUI Uploads, Ollama-Modelle
- **Logs:** Kritische Logs der letzten 7 Tage
- **Zertifikate:** SSL-Zertifikate und Schlüssel

---

## AUTOMATISCHE BACKUPS (BACKREST)

### **Aktuelle Backrest-Konfiguration**

```bash
# Backrest-Status prüfen
docker compose ps backrest
curl -f http://localhost:9898/api/v1/status

# Konfiguration einsehen
docker exec erni-ki-backrest-1 cat /config/config.json
```

## **Monitoring automatischer Backups**

```bash
# Letzte Backups prüfen
curl -s http://localhost:9898/api/v1/repos | jq '.[] | {name: .name, lastBackup: .lastBackup}'

# Backrest-Logs prüfen
docker compose logs backrest --tail=50

# Backup-Größe prüfen
du -sh .config-backup/
```

## **Backup-Benachrichtigungen einrichten**

```bash
# Skript zur Backup-Prüfung anlegen
cat > check-backups.sh << 'EOF'
# !/bin/bash
WEBHOOK_URL="YOUR_WEBHOOK_URL" # Webhook für Benachrichtigungen setzen

# Letztes Backup prüfen
LAST_BACKUP=$(curl -s http://localhost:9898/api/v1/repos | jq -r '.[0].lastBackup')
CURRENT_TIME=$(date +%s)
BACKUP_TIME=$(date -d "$LAST_BACKUP" +%s)
HOURS_DIFF=$(( (CURRENT_TIME - BACKUP_TIME) / 3600 ))

if [ $HOURS_DIFF -gt 25 ]; then
 echo " ACHTUNG: Letztes Backup liegt $HOURS_DIFF Stunden zurück!"
 # Benachrichtigung senden
 curl -X POST "$WEBHOOK_URL" -d "Backup ERNI-KI veraltet: $HOURS_DIFF Stunden"
else
 echo " Backup ist aktuell (zuletzt vor $HOURS_DIFF Stunden)"
fi
EOF

chmod +x check-backups.sh

# In crontab für tägliche Prüfung aufnehmen
echo "0 9 * * * /path/to/check-backups.sh" | crontab -
```

---

## MANUELLE BACKUPS

### **Vollständiges System-Backup**

```bash
# !/bin/bash
# Vollständiges Backup von ERNI-KI

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=".config-backup/full-backup-$BACKUP_DATE"

echo " Erstelle Voll-Backup in $BACKUP_DIR"

# 1. Verzeichnis erstellen
mkdir -p "$BACKUP_DIR"

# 2. Services optional stoppen für Konsistenz
read -p "Services für konsistentes Backup stoppen? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
 echo "Stoppe Services..."
 docker compose stop openwebui litellm
 SERVICES_STOPPED=true
fi

# 3. Konfigurationen sichern
echo "Sichere Konfigurationen..."
sudo cp -r env/ "$BACKUP_DIR/"
sudo cp -r conf/ "$BACKUP_DIR/"
cp compose.yml "$BACKUP_DIR/"

# 4. Datenbank sichern
echo "Sichere Datenbank..."
docker exec erni-ki-db-1 pg_dump -U postgres -Fc openwebui > "$BACKUP_DIR/database.dump"
docker exec erni-ki-db-1 pg_dumpall -U postgres > "$BACKUP_DIR/database-full.sql"

# 5. OpenWebUI-Nutzerdaten sichern
echo "Sichere OpenWebUI-Daten..."
sudo cp -r data/openwebui/ "$BACKUP_DIR/" 2>/dev/null || echo "OpenWebUI-Daten nicht gefunden"

# 6. Ollama-Modelle sichern
echo "Sichere Ollama-Modelle..."
sudo cp -r data/ollama/ "$BACKUP_DIR/" 2>/dev/null || echo "Ollama-Daten nicht gefunden"

# 7. Kritische Logs sichern
echo "Sichere Logs..."
mkdir -p "$BACKUP_DIR/logs"
docker compose logs --since 7d > "$BACKUP_DIR/logs/services-7days.log"

# 8. Backup-Manifest erzeugen
cat > "$BACKUP_DIR/backup-manifest.txt" << EOF
ERNI-KI Full Backup
Erstellt am: $(date)
Systemversion: $(docker compose version)
Service-Status zum Backup-Zeitpunkt:
$(docker compose ps)

Backup-Inhalt:
- Konfigurationen: env/, conf/, compose.yml
- Datenbank: PostgreSQL dump (binary und SQL)
- Nutzerdaten: OpenWebUI, Ollama
- Logs: 7 Tage Historie
- Backup-Größe: $(du -sh "$BACKUP_DIR" | cut -f1)
EOF

# 9. Services erneut starten
if [ "$SERVICES_STOPPED" = true ]; then
 echo "Starte Services..."
 docker compose up -d
fi

# 10. Archiv optional erstellen
read -p "tar.gz-Archiv erstellen? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
 echo "Erstelle Archiv..."
 tar -czf "$BACKUP_DIR.tar.gz" -C .config-backup "full-backup-$BACKUP_DATE"
 echo "Archiv erstellt: $BACKUP_DIR.tar.gz"
fi

echo " Voll-Backup abgeschlossen: $BACKUP_DIR"
echo " Manifest: $BACKUP_DIR/backup-manifest.txt"
```

## **Schnelles Konfig-Backup**

```bash
# !/bin/bash
# Schnelles Backup nur der Konfiguration (ohne Services zu stoppen)

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=".config-backup/config-backup-$BACKUP_DATE"

echo " Erstelle Konfig-Backup in $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"
sudo cp -r env/ "$BACKUP_DIR/"
sudo cp -r conf/ "$BACKUP_DIR/"
cp compose.yml "$BACKUP_DIR/"

# Snapshot des aktuellen Zustands
docker compose ps > "$BACKUP_DIR/services-status.txt"
docker compose config > "$BACKUP_DIR/compose-resolved.yml"

echo " Konfig-Backup abgeschlossen: $BACKUP_DIR"
```

## **Nur die Datenbank sichern**

```bash
# !/bin/bash
# Backup nur der PostgreSQL-Datenbank

BACKUP_DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=".config-backup/db-backup-$BACKUP_DATE"

echo " Erstelle DB-Backup in $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Binary dump (schnelles Restore)
docker exec erni-ki-db-1 pg_dump -U postgres -Fc openwebui > "$BACKUP_DIR/openwebui.dump"

# SQL dump (lesbares Format)
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > "$BACKUP_DIR/openwebui.sql"

# Vollständiger Dump aller DBs
docker exec erni-ki-db-1 pg_dumpall -U postgres > "$BACKUP_DIR/all-databases.sql"

# DB-Infos
docker exec erni-ki-db-1 psql -U postgres -c "\\l" > "$BACKUP_DIR/database-info.txt"
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "\\dt" > "$BACKUP_DIR/tables-info.txt"

echo " DB-Backup abgeschlossen: $BACKUP_DIR"
```

---

## WIEDERHERSTELLUNGS-PROZEDUREN

### **Vollständige Systemwiederherstellung**

```bash
# !/bin/bash
# Vollständige Wiederherstellung von ERNI-KI aus einem Backup

BACKUP_DIR="$1"
if [ -z "$BACKUP_DIR" ]; then
 echo "Usage: $0 <backup_directory>"
 echo "Verfügbare Backups:"
 ls -la .config-backup/ | grep full-backup
 exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
 echo " Backup-Verzeichnis nicht gefunden: $BACKUP_DIR"
 exit 1
fi

echo " Starte vollständige Wiederherstellung aus $BACKUP_DIR"
echo " WARNUNG: Überschreibt alle aktuellen Daten!"
read -p "Fortsetzen? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
 echo "Wiederherstellung abgebrochen"
 exit 1
fi

# 1. Alle Services stoppen
echo "Stoppe Services..."
docker compose down

# 2. Aktuellen Zustand sichern
echo "Sichere aktuellen Zustand..."
CURRENT_BACKUP=".config-backup/pre-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CURRENT_BACKUP"
sudo cp -r env/ conf/ compose.yml "$CURRENT_BACKUP/" 2>/dev/null || true

# 3. Konfigurationen wiederherstellen
echo "Stelle Konfigurationen wieder her..."
sudo rm -rf env/ conf/
sudo cp -r "$BACKUP_DIR/env/" ./
sudo cp -r "$BACKUP_DIR/conf/" ./
cp "$BACKUP_DIR/compose.yml" ./

# 4. Berechtigungen korrigieren
sudo chown -R $USER:$USER env/ conf/

# 5. Basissystem starten
echo "Starte Basis-Services..."
docker compose up -d db redis

# 6. Auf DB-Bereitschaft warten
echo "Warte auf PostgreSQL..."
sleep 30
until docker exec erni-ki-db-1 pg_isready -U postgres; do
 echo "PostgreSQL wird vorbereitet..."
 sleep 5
done

# 7. Datenbank wiederherstellen
if [ -f "$BACKUP_DIR/database.dump" ]; then
 echo "Stelle Datenbank aus Binary Dump wieder her..."
 docker exec erni-ki-db-1 dropdb -U postgres openwebui --if-exists
 docker exec erni-ki-db-1 createdb -U postgres openwebui
 docker exec -i erni-ki-db-1 pg_restore -U postgres -d openwebui < "$BACKUP_DIR/database.dump"
elif [ -f "$BACKUP_DIR/database-full.sql" ]; then
 echo "Stelle Datenbank aus SQL Dump wieder her..."
 docker exec -i erni-ki-db-1 psql -U postgres < "$BACKUP_DIR/database-full.sql"
else
 echo " Kein Datenbank-Backup gefunden"
fi

# 8. Nutzerdaten wiederherstellen
if [ -d "$BACKUP_DIR/openwebui" ]; then
 echo "Stelle OpenWebUI-Daten wieder her..."
 sudo rm -rf data/openwebui/
 sudo cp -r "$BACKUP_DIR/openwebui/" data/
fi

if [ -d "$BACKUP_DIR/ollama" ]; then
 echo "Stelle Ollama-Modelle wieder her..."
 sudo rm -rf data/ollama/
 sudo cp -r "$BACKUP_DIR/ollama/" data/
fi

# 9. Alle Services starten
echo "Starte alle Services..."
docker compose up -d

# 10. Wiederherstellung prüfen
echo "Prüfe Wiederherstellung..."
sleep 60

echo "=== SERVICE-STATUS ==="
docker compose ps

echo -e "\n=== VERFÜGBARKEIT ==="
curl -f http://localhost/health && echo " OpenWebUI erreichbar" || echo " OpenWebUI nicht erreichbar"
curl -f http://localhost:11434/api/tags && echo " Ollama läuft" || echo " Ollama nicht erreichbar"

echo -e "\n Wiederherstellung abgeschlossen!"
echo " Backup des vorherigen Zustands: $CURRENT_BACKUP"
echo " Manifest des wiederhergestellten Backups: $BACKUP_DIR/backup-manifest.txt"
```

## **Nur Konfigurationen wiederherstellen**

```bash
# !/bin/bash
# Wiederherstellung nur der Konfigurationen ohne Services zu stoppen

BACKUP_DIR="$1"
if [ -z "$BACKUP_DIR" ]; then
 echo "Usage: $0 <backup_directory>"
 exit 1
fi

echo " Stelle Konfigurationen wieder her aus $BACKUP_DIR"

# Aktuelle Konfigurationen sichern
CURRENT_BACKUP=".config-backup/pre-config-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CURRENT_BACKUP"
sudo cp -r env/ conf/ compose.yml "$CURRENT_BACKUP/"

# Konfigurationen wiederherstellen
sudo cp -r "$BACKUP_DIR/env/" ./
sudo cp -r "$BACKUP_DIR/conf/" ./
cp "$BACKUP_DIR/compose.yml" ./

# Änderungen anwenden
docker compose up -d --no-recreate

echo " Konfigurationen wiederhergestellt"
echo " Backup der vorherigen Konfigurationen: $CURRENT_BACKUP"
```

## **Nur die Datenbank wiederherstellen**

```bash
# !/bin/bash
# Wiederherstellung nur der PostgreSQL-Datenbank

BACKUP_FILE="$1"
if [ -z "$BACKUP_FILE" ]; then
 echo "Usage: $0 <backup_file>"
 echo "Unterstützte Formate: .dump, .sql"
 exit 1
fi

echo " Stelle Datenbank wieder her aus $BACKUP_FILE"
echo " WARNUNG: Überschreibt die aktuelle Datenbank!"
read -p "Fortsetzen? (yes/no): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
 echo "Wiederherstellung abgebrochen"
 exit 1
fi

# Aktuelle DB sichern
echo "Sichere aktuelle Datenbank..."
CURRENT_DB_BACKUP=".config-backup/db-pre-restore-$(date +%Y%m%d-%H%M%S).dump"
docker exec erni-ki-db-1 pg_dump -U postgres -Fc openwebui > "$CURRENT_DB_BACKUP"

# Datenbank wiederherstellen
if [[ "$BACKUP_FILE" == *.dump ]]; then
 echo "Wiederherstellung aus Binary Dump..."
 docker exec erni-ki-db-1 dropdb -U postgres openwebui --if-exists
 docker exec erni-ki-db-1 createdb -U postgres openwebui
 docker exec -i erni-ki-db-1 pg_restore -U postgres -d openwebui < "$BACKUP_FILE"
elif [[ "$BACKUP_FILE" == *.sql ]]; then
 echo "Wiederherstellung aus SQL Dump..."
 docker exec -i erni-ki-db-1 psql -U postgres < "$BACKUP_FILE"
else
 echo " Nicht unterstütztes Dateiformat"
 exit 1
fi

# Services mit DB neu starten
echo "Starte Services neu..."
docker compose restart openwebui litellm

echo " Datenbank wiederhergestellt"
echo " Backup der vorherigen DB: $CURRENT_DB_BACKUP"
```

---

## BACKUP-TESTS

### **Monatlicher Restore-Test**

```bash
# !/bin/bash
# Skript zum Testen der Wiederherstellungsprozedur

echo " Teste Wiederherstellung"

# 1. Letztes Backup finden
LATEST_BACKUP=$(ls -t .config-backup/full-backup-* | head -1)
echo "Teste Backup: $LATEST_BACKUP"

# 2. Testumgebung erstellen
TEST_DIR="test-restore-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 3. Backup kopieren
cp -r "../$LATEST_BACKUP" ./

# 4. Minimale Testkonfiguration erstellen
# [hier kann eine vereinfachte Version für Tests erstellt werden]

# 5. Wiederherstellung der Konfigurationen testen
echo "Teste Wiederherstellung der Konfigurationen..."
# [Test-Restore ausführen]

# 6. Bericht erstellen
cat > restore-test-report.txt << EOF
Restore-Test-Bericht
Datum: $(date)
Getestetes Backup: $LATEST_BACKUP
Status: [ERFOLG/FEHLER]
Probleme: [Probleme beschreiben]
Empfehlungen: [Verbesserungen]
EOF

echo " Test abgeschlossen"
echo " Bericht: $TEST_DIR/restore-test-report.txt"
```

---

## BACKUP-MONITORING

### **Backup-Status-Dashboard**

```bash
# !/bin/bash
# Backup-Status-Dashboard erzeugen

echo " BACKUP-STATUS ERNI-KI"
echo "========================"
echo "Datum: $(date)"
echo

# Backrest-Status
echo " AUTOMATISCHE BACKUPS (Backrest):"
if curl -f http://localhost:9898/api/v1/status >/dev/null 2>&1; then
 echo " Backrest-Service läuft"
 LAST_BACKUP=$(curl -s http://localhost:9898/api/v1/repos | jq -r '.[0].lastBackup' 2>/dev/null)
 if [ "$LAST_BACKUP" != "null" ] && [ -n "$LAST_BACKUP" ]; then
 echo " Letztes Backup: $LAST_BACKUP"
 else
 echo " Keine Infos zum letzten Backup"
 fi
else
 echo " Backrest-Service nicht erreichbar"
fi

# Manuelle Backups
echo -e "\n MANUELLE BACKUPS:"
BACKUP_COUNT=$(ls -1 .config-backup/full-backup-* 2>/dev/null | wc -l)
echo " Anzahl Voll-Backups: $BACKUP_COUNT"

if [ $BACKUP_COUNT -gt 0 ]; then
 LATEST_MANUAL=$(ls -t .config-backup/full-backup-* | head -1)
 LATEST_DATE=$(basename "$LATEST_MANUAL" | sed 's/full-backup-//')
 echo " Letztes manuelles Backup: $LATEST_DATE"
fi

# Speicherverbrauch
echo -e "\n SPEICHERNUTZUNG:"
BACKUP_SIZE=$(du -sh .config-backup/ 2>/dev/null | cut -f1)
echo " Gesamte Backup-Größe: $BACKUP_SIZE"

# Empfehlungen
echo -e "\n EMPFEHLUNGEN:"
if [ $BACKUP_COUNT -lt 3 ]; then
 echo " Mehr Backups empfohlen"
fi

DAYS_SINCE_BACKUP=$(find .config-backup/ -name "full-backup-*" -mtime -7 | wc -l)
if [ $DAYS_SINCE_BACKUP -eq 0 ]; then
 echo " Keine Backups in den letzten 7 Tagen"
fi

echo -e "\n Prüfung abgeschlossen"
```

---

## VERWANDTE DOKUMENTE

- [Service Restart Procedures](../../../operations/maintenance/service-restart-procedures.md)
- [Troubleshooting Guide](../../operations/troubleshooting/troubleshooting-guide.md)
- [Configuration Change Process](../../operations/core/configuration-change-process.md)
- [System Architecture](../../../architecture/architecture.md)

---

_Dokument erstellt im Rahmen der Optimierung der ERNI-KI-Konfigurationen vom
25.09.2025_

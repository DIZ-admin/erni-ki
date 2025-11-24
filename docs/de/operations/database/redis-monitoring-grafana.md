---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Redis Monitoring mit Grafana in ERNI-KI

## 📊 Übersicht

Das ERNI-KI-System umfasst nun vollständiges Redis-Monitoring über Grafana mit
dem Redis Data Source Plugin. Diese Lösung ersetzt den problematischen
Redis-Exporter und bietet stabiles Monitoring für Redis 7.4.5 Alpine.

## 🚀 Schnellstart

### Grafana-Zugriff

- **URL**: http://localhost:3000
- **Login**: admin
- **Passwort**: admin123

### Zugriff auf Redis-Dashboard

1. Grafana im Browser öffnen
2. Zum Bereich "Dashboards" navigieren
3. Dashboard "Redis Monitoring - ERNI-KI" suchen

## 🔧 Technische Konfiguration

### Redis Data Source

- **Name**: Redis-ERNI-KI
- **Typ**: redis-datasource
- **URL**: redis://redis:6379
- **Authentifizierung**: requirepass (ErniKiRedisSecurePassword2024)
- **Modus**: standalone

### Automatische Konfiguration

Konfiguration wird automatisch über Grafana Provisioning angewendet:

- Data Source: `conf/grafana/provisioning/datasources/redis.yml`
- Dashboard: `conf/grafana/dashboards/infrastructure/redis-monitoring.json`

## 📈 Verfügbare Metriken

### Grundmetriken

- **Memory Usage**: Redis-Speichernutzung
- **Connected Clients**: Anzahl verbundener Clients
- **Commands Processed**: Verarbeitete Befehle
- **Network I/O**: Netzwerkverkehr
- **Keyspace**: Informationen zu Datenbanken

### Zusätzliche Metriken

- **Server Info**: Version, Laufzeit, Modus
- **Persistence**: Status der Datenspeicherung
- **Replication**: Replikationsinformationen (falls konfiguriert)

## 🛠️ Monitoring erweitern

### Neue Panels hinzufügen

1. Dashboard im Bearbeitungsmodus öffnen
2. Neues Panel hinzufügen
3. Redis-ERNI-KI als Datenquelle wählen
4. Befehl und Felder konfigurieren:
   - **Command**: info
   - **Section**: memory/stats/server/clients
   - **Field**: spezifisches Feld aus Redis INFO

### Redis-Befehlsbeispiele

```bash
# Grundinformationen
INFO server
INFO memory
INFO stats
INFO clients

# Spezifische Metriken
DBSIZE
LASTSAVE
CONFIG GET maxmemory
```

## 🔍 Performance-Monitoring

### Wichtige zu beobachtende Kennzahlen

1. **used_memory** - Speichernutzung
2. **connected_clients** - Anzahl Clients
3. **total_commands_processed** - Gesamtzahl Befehle
4. **instantaneous_ops_per_sec** - Operationen pro Sekunde
5. **keyspace_hits/misses** - Cache-Effizienz

### Alerts und Schwellenwerte

- Memory usage > 80% der verfügbaren
- Connected clients > 100
- Hit Ratio < 90%
- Response time > 1ms

## 🚨 Fehlerbehebung

### Verbindungsprobleme

```bash
# Redis-Status prüfen
docker-compose ps redis

# Verbindung prüfen
docker-compose exec redis redis-cli -a ErniKiRedisSecurePassword2024 ping

# Grafana-Logs prüfen
docker-compose logs grafana --tail=20
```

### Plugin neu installieren

```bash
# Redis Data Source Plugin neu installieren
docker-compose exec grafana grafana-cli plugins uninstall redis-datasource
docker-compose exec grafana grafana-cli plugins install redis-datasource
docker-compose restart grafana
```

## 📚 Zusätzliche Ressourcen

### Offizielle Dokumentation

- [Redis Data Source Plugin](https://grafana.com/grafana/plugins/redis-datasource/)
- [Redis INFO Command](https://redis.io/commands/info/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Alternative Lösungen

1. **Redis Insight** für detaillierte Analyse
2. **Custom Scripts** mit Metriken-Versand an InfluxDB
3. **Direkte Redis-Befehle** über CLI zur Diagnose

**Hinweis**: Redis-Exporter wurde aus ERNI-KI entfernt aufgrund von
Kompatibilitätsproblemen mit Redis 7.4.5 Alpine. Grafana Redis Data Source
Plugin ist die bevorzugte Lösung.

## 🔄 Updates und Wartung

### Regelmäßige Aufgaben

- Festplattenspeicher für Grafana-Daten überwachen
- Dashboards bei geänderten Anforderungen aktualisieren
- Grafana-Konfigurationen sichern

### Automatische Updates

Grafana ist für automatische Updates über Watchtower mit Label
`monitoring-stack` konfiguriert.

---

**Status**: ✅ Aktiv **Letzte Aktualisierung**: 2025-09-19 **Version**: 1.0
**Autor**: Alteon Schultz (Tech Lead)

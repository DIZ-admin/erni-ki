---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# 🔍 Systemdiagnose ERNI-KI

## 📋 Überblick

Dieser Bereich enthält die ERNI-KI-Diagnosemethodik, basierend auf Erfahrungen
mit kritischen Testfehlern, die zu zu niedrigen Bewertungen führten.

## 📚 Dokumentation

### 📖 Kerndokumente

1. **[erni-ki-diagnostic-methodology.md](../../../operations/diagnostics/erni-ki-diagnostic-methodology.md)**
   - End-to-end Diagnoseleitfaden
   - Korrekte Testmethodik für Komponenten
   - Vermeidung typischer Diagnosefehler
   - Struktur eines Diagnoseberichts
   - Kriterien für System-Health

### 🛠️ Werkzeuge

1. **`../scripts/erni-ki-health-check.sh`**
   - Automatisiertes Diagnoseskript
   - Vollständiger Check aller Komponenten
   - Farbige Ausgabe und detailreicher Report
   - Berechnung des Gesamtgesundheits-Scores

## 🚀 Schnellstart

### Volle Diagnose ausführen

```bash
cd /path/to/erni-ki
./scripts/erni-ki-health-check.sh
```

### Manuelle Diagnose der Kernkomponenten

{% raw %}

```bash
# 1. Docker-Container prüfen
docker ps --filter "name=erni-ki" --format "table {{.Names}}\t{{.Status}}" | grep -c "healthy"

# 2. LiteLLM API testen
curl -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
     http://localhost:4000/v1/models

# 3. SearXNG testen
curl -s "http://localhost:8080/search?q=test&format=json" | jq -r '.results | length'

# 4. Redis testen
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping

# 5. Externen Zugriff prüfen
curl -I "https://ki.erni-gruppe.ch"
```

{% endraw %}

## 📊 Ergebnisinterpretation

### 🎯 Health Score

| Bereich | Status           | Beschreibung                                   |
| ------- | ---------------- | ---------------------------------------------- |
| 90-100% | 🟢 AUSGEZEICHNET | System arbeitet einwandfrei                    |
| 70-89%  | 🟡 GUT           | Kleinere Probleme, System funktionsfähig       |
| 50-69%  | 🟠 BEFRIEDIGEND  | Signifikante Probleme, eingeschränkte Funktion |
| <50%    | 🔴 KRITISCH      | Sofortiges Eingreifen erforderlich             |

### 🔍 Schlüsselkriterien

- **Healthy Containers:** Anzahl Container mit Status "healthy"
- **API Response Time:** Antwortzeiten kritischer APIs
- **External Access:** Erreichbarkeit via HTTPS-Domains
- **Integration Status:** Funktionsfähigkeit der Service-Integrationen

## ⚠️ Typische Probleme & Fixes

### 🚫 Häufige Diagnosefehler

1. **Tests ohne Authentifizierung**
   - ❌ `curl http://localhost:4000/v1/models`
   - ✅ `curl -H "Authorization: Bearer TOKEN" http://localhost:4000/v1/models`

2. **Falsche Endpoints**
   - ❌ `curl http://localhost:8080/search?q=test`
   - ✅ `curl http://localhost:8080/search?q=test&format=json`

3. **Redis-Passwörter ignoriert**
   - ❌ `docker exec redis redis-cli ping`
   - ✅ `docker exec redis redis-cli -a "PASSWORD" ping`

### 🔧 Schnelle Maßnahmen

```bash
docker restart erni-ki-[service-name]
docker logs erni-ki-[service-name] --since=1h
docker stats --no-stream
```

## 📈 Monitoring & Automatisierung

### 📅 Regelmäßige Diagnose

```bash
0 6 * * * /path/to/erni-ki/scripts/erni-ki-health-check.sh >> /var/log/erni-ki-health.log 2>&1
```

---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# Access-Log-Sync & Fluent Bit

Kurzanleitung zur Synchronisation von Access-Logs und Fluent-Bit-Pipeline.

## Ziele

- Nginx/OpenWebUI Access-Logs zentralisieren
- Weiterleitung an Loki/Grafana sicherstellen

## Schritte

1. **Pfad prüfen**
   - Standard: `logs/openwebui/access.log` (oder Mount aus nginx)

2. **Fluent Bit Input** (Beispiel)

   ```ini
   [INPUT]
       Name              tail
       Path              /logs/openwebui/access.log
       Tag               openwebui.access
       Parser            nginx
       Refresh_Interval  5
   ```

3. **Parser**
   - `Parsers_File` sicherstellen (nginx-Parser konfiguriert)

4. **Output zu Loki** (Beispiel)

   ```ini
   [OUTPUT]
       Name              loki
       Match             openwebui.access
       Url               http://loki:3100/loki/api/v1/push
       Labels            job=openwebui,app=openwebui,stream=access
       Log_Format        json
   ```

5. **Redeploy**
   - Fluent Bit neu starten: `docker compose restart fluent-bit`
   - Logs prüfen: `docker compose logs fluent-bit --tail=50`

## Troubleshooting

- Keine Logs: Pfad/Parser prüfen, Dateirechte
- Loki-Fehler: URL/Labels/Authentifizierung prüfen
- Hohe Latenz: `Mem_Buf_Limit`, `Refresh_Interval`, Batch-Größe anpassen

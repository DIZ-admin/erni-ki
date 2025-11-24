---
language: de
translation_status: in_progress
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# MCP Server Integration Guide

Kurzanleitung zur Integration eines MCP-Servers in ERNI-KI.

## Voraussetzungen

- MCP-Server erreichbar (HTTP/S)
- Zugriffstoken/API-Key, falls erforderlich
- Netzwerkzugang aus der Zielumgebung (lokal oder CI)

## Schritte

1. **Endpoint prüfen**

```bash
curl -I https://your-mcp-server/health
```

2. **Konfiguration setzen** (Beispiel .env)

```
MCP_SERVER_URL=https://your-mcp-server
MCP_SERVER_TOKEN=changeme
```

3. **Services neu starten** (falls benötigt)

```bash
docker compose restart openwebui litellm
```

4. **Funktionstest**

- In OpenWebUI: neuen Agenten/Tool hinzufügen, der den MCP-Endpoint nutzt
- Logs prüfen: `docker compose logs openwebui --tail=200`

## Fehlerbehebung

- **401/403**: Token/Headers prüfen
- **Timeout**: Netzwerk/DNS/Firewall prüfen
- **SSL-Fehler**: Zertifikat/CA-Bundle ergänzen

## Sicherheit

- Secrets nur über `.env` / CI-Secrets injizieren
- Kein Hardcoding von Tokens in Repo-Dateien
- Falls Self-Signed: Zertifikate sicher hinterlegen (z.B. `conf/ca/`), nicht im
  Repo

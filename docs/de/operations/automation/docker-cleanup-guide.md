---
language: de
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Leitfaden zur Bereinigung ungenutzter Docker-Ressourcen

[TOC]

## Überblick

Auf Basis der Docker-Analyse wurden folgende ungenutzte Ressourcen gefunden:

| Kategorie              | Anzahl | Potenzielle Einsparung |
| ---------------------- | ------ | ---------------------- |
| **Ungenutzte Images**  | 23     | ~21,78 GB              |
| **Ungenutzte Volumes** | 101+   | ~16,36 GB              |
| **Build-Cache**        | 0      | 0 GB                   |
| **Dangling Images**    | 0      | 0 GB                   |

**Gesamte potenzielle Einsparung: ~38 GB**

---

## Ungenutzte Docker Images

### Liste ungenutzter Images (ohne Container)

```
erni-foto-agency-dev-frontend:2024.05 1.17 GB
erni-foto-agency-erni-app:2024.05 582 MB
erni-foto-agency-dev-backend:2024.05 559 MB
erni-foto-agency-frontend:2024.05 1.14 GB
erni-foto-agency-backend:2024.05 559 MB
alpine:2024.05 8.32 MB
erni-foto-agency-erni-frontend:2024.05 3.3 GB
erni-foto-agency-erni-ag-ui-bridge:2024.05 167 MB
erni-foto-copilot:2024.05 1.22 GB
jaegertracing/all-in-one:2024.05 85.6 MB
ghcr.io/open-webui/open-webui:2024.05 4.83 GB (alte Version)
ghcr.io/open-webui/open-webui:v0.6.31 4.83 GB (alte Version)
erni-foto-agency-app:2024.05 2.14 GB
fluent/fluent-bit:2024.05 106 MB
postgres:15-alpine 279 MB
grafana/grafana:2024.05 733 MB
ghcr.io/berriai/litellm:v1.77.2.rc.1 2.2 GB (alte Version)
fluent/fluent-bit:3.1.0 88.2 MB
mysql:8.0.39 573 MB
elasticsearch:8.11.3 1.41 GB
```

**Gesamtgröße: ~21,78 GB**

---

## Befehle zur Bereinigung

### 1. Sichere Bereinigung (empfohlen)

#### Entfernen bestimmter ungenutzter Images

```bash
# Alte OpenWebUI-Versionen löschen
docker rmi ghcr.io/open-webui/open-webui:2024.05
docker rmi ghcr.io/open-webui/open-webui:v0.6.31

# Alte LiteLLM-Version löschen
docker rmi ghcr.io/berriai/litellm:v1.77.2.rc.1

# Ungenutzte ERNI-FOTO-Images löschen
docker rmi erni-foto-agency-dev-frontend:2024.05
docker rmi erni-foto-agency-dev-backend:2024.05
docker rmi erni-foto-agency-erni-app:2024.05
docker rmi erni-foto-agency-frontend:2024.05
docker rmi erni-foto-agency-backend:2024.05
docker rmi erni-foto-agency-erni-frontend:2024.05
docker rmi erni-foto-agency-erni-ag-ui-bridge:2024.05
docker rmi erni-foto-copilot:2024.05
docker rmi erni-foto-agency-app:2024.05

# Ungenutzte Service-Images löschen
docker rmi jaegertracing/all-in-one:2024.05
docker rmi fluent/fluent-bit:2024.05
docker rmi fluent/fluent-bit:3.1.0
docker rmi postgres:15-alpine
docker rmi grafana/grafana:2024.05
docker rmi mysql:8.0.39
docker rmi elasticsearch:8.11.3
docker rmi alpine:2024.05
```

**Erwartete Einsparung: ~21,78 GB**

## 2. Automatische Bereinigung aller ungenutzten Images

{% raw %}

```bash
# ACHTUNG: Löscht ALLE Images ohne Container!
# Nur nutzen, wenn sicher ist, dass die Images nicht mehr benötigt werden.

# Liste vor dem Löschen anzeigen
docker images --filter "dangling=false" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | \
 grep -v "$(docker ps -a --format '{{.Image}}' | sort -u | tr '\n' '|' | sed 's/|$//')"

# Images ohne Container, älter als 30 Tage, löschen
docker image prune -a --filter "until=720h"
```

{% endraw %}

---

## Ungenutzte Docker Volumes

### Inhalt vor dem Löschen prüfen

{% raw %}

```bash
# Liste aller ungenutzten Volumes
docker volume ls -qf dangling=true

# Inhalt der Volumes prüfen (erste 10)
for vol in $(docker volume ls -qf dangling=true | head -10); do
 echo "=== Volume: $vol ==="
 docker run --rm -v $vol:/data alpine ls -lah /data 2>/dev/null | head -10
 echo ""
done
```

{% endraw %}

## Ungenutzte Volumes löschen

```bash
# VORSICHT: Kann wichtige Daten löschen!

# Variante 1: Alle ungenutzten Volumes löschen
docker volume prune -f

# Variante 2: Einzelne Volumes nach Prüfung löschen
# docker volume rm <volume_id>
```

**Erwartete Einsparung: ~16,36 GB**

---

## Umfassende Docker-Bereinigung

### Volle Bereinigung (GEFÄHRLICH!)

```bash
# Löscht ALLES Unbenutzte: images, containers, volumes, networks
docker system prune -a --volumes -f

# Mit Rückfrage
docker system prune -a --volumes
```

## Sichere umfassende Bereinigung

{% raw %}

```bash
# 1. Gestoppte Container löschen
docker container prune -f

# 2. Ungenutzte Netzwerke löschen
docker network prune -f

# 3. Dangling images löschen (bereits erledigt)
docker image prune -f

# 4. Build-Cache löschen (bereits erledigt)
docker builder prune -af

# 5. Statistik prüfen
docker system df
```

{% endraw %}

---

## Automatisierung der Bereinigung

### Wöchentliches Cleanup-Skript erstellen

```bash
cat > scripts/cleanup-docker.sh << 'EOF'
# !/bin/bash
# Automatische Bereinigung der Docker-Ressourcen von ERNI-KI
# Läuft wöchentlich samstags um 04:00 per cron

PROJECT_DIR="/home/konstantin/Documents/augment-projects/erni-ki"
LOG_FILE="$PROJECT_DIR/logs/docker-cleanup.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starte Docker-Cleanup" >> "$LOG_FILE"

# Statistik vor der Bereinigung
BEFORE=$(docker system df --format "{{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}")
echo "$(date '+%Y-%m-%d %H:%M:%S') - Vor Cleanup:" >> "$LOG_FILE"
echo "$BEFORE" >> "$LOG_FILE"

# Gestoppte Container löschen
CONTAINERS=$(docker container prune -f 2>&1 | grep "Total reclaimed space" | awk '{print $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Gelöschte Container: $CONTAINERS" >> "$LOG_FILE"

# Ungenutzte Netzwerke löschen
NETWORKS=$(docker network prune -f 2>&1 | grep "Deleted Networks" | wc -l)
echo "$(date '+%Y-%m-%d %H:%M:%S') - Gelöschte Netzwerke: $NETWORKS" >> "$LOG_FILE"

# Dangling images löschen
IMAGES=$(docker image prune -f 2>&1 | grep "Total reclaimed space" | awk '{print $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Gelöschte dangling images: $IMAGES" >> "$LOG_FILE"

# Build-Cache löschen
CACHE=$(docker builder prune -af 2>&1 | grep "Total reclaimed space" | awk '{print $4}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Build-Cache bereinigt: $CACHE" >> "$LOG_FILE"

# Statistik nach der Bereinigung
AFTER=$(docker system df --format "{{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}")
echo "$(date '+%Y-%m-%d %H:%M:%S') - Nach Cleanup:" >> "$LOG_FILE"
echo "$AFTER" >> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker-Cleanup abgeschlossen" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
EOF

chmod +x scripts/cleanup-docker.sh
```

## In crontab eintragen

```bash
# Docker-Cleanup (jeden Samstag um 04:00)
0 4 * * 6 /home/konstantin/Documents/augment-projects/erni-ki/scripts/cleanup-docker.sh
```

---

## Monitoring der Docker-Ressourcen

### Prüfkommandos

{% raw %}

```bash
# Gesamtstatistik
docker system df

# Detailstatistik
docker system df -v

# Log-Größe der Container
sudo du -sh /var/lib/docker/containers/

# Volumes-Größe
sudo du -sh /var/lib/docker/volumes/

# Images-Größe
sudo du -sh /var/lib/docker/overlay2/

# Top-10 größte Images
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | sort -k2 -h | tail -10

# Top-10 größte Volumes
docker volume ls --format "{{.Name}}" | xargs -I {} sh -c 'echo "{}:$(docker volume inspect {} --format "{{.Mountpoint}}" | xargs sudo du -sh 2>/dev/null | awk "{print \$1}")"' | sort -t: -k2 -h | tail -10
```

{% endraw %}

---

## Empfehlungen

### Sofort (sicher)

1. **Alte OpenWebUI-Versionen löschen** (v0.6.31, v0.6.34) – spart ~9,66 GB
2. **Alte LiteLLM-Version löschen** (v1.77.2.rc.1) – spart ~2,2 GB
3. **Ungenutzte ERNI-FOTO-Images löschen** – spart ~9,92 GB

**Gesamte Einsparung: ~21,78 GB**

### Mit Vorsicht (prüfen)

1. **Ungenutzte Volumes prüfen** – potenziell ~16,36 GB

- Inhalt jedes Volumes prüfen
- Sicherstellen, dass keine wichtigen Daten enthalten sind
- Erst nach Bestätigung löschen

2. **Alte Service-Images löschen** (elasticsearch, mysql, fluent-bit)

- Nur, wenn sicher nicht benötigt

### Langfristig

1. **Automatische Bereinigung** per cron (wöchentlich) einrichten
2. **Docker-Größe monitoren** via `monitor-disk-space.sh`
3. **Regelmäßig prüfen**: `docker system df -v`

---

## Wiederherstellung gelöschter Images

Falls ein benötigtes Image versehentlich gelöscht wurde:

```bash
# Offizielle Images neu ziehen
docker pull <image_name>:<tag>

# Lokale Images neu bauen
cd <project_directory>
docker compose build <service_name>
```

---

## Prüfung nach der Bereinigung

```bash
# Prüfen, ob Services laufen
docker compose ps

# Logs auf Fehler prüfen
docker compose logs --tail=50

# Freien Speicher prüfen
df -h /
docker system df
```

---

**Status:** Dokumentation erstellt **Empfohlene Aktion:** Sichere Bereinigung
ungenutzter Images (~21,78 GB) **Priorität:** Mittel (innerhalb einer Woche
umsetzbar)

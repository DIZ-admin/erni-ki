---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Docker Log Rotation for ERNI-KI

[TOC]

## Description

Configure automatic rotation of Docker container logs to prevent uncontrolled
disk space growth.

## Recommended configuration

### Global setting (daemon.json)

Create or update `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker after changes:

```bash
sudo systemctl restart docker
```

**Effect:** Each container will store maximum 3 files of 10 MB each (30 MB per
container).

---

### Configuration for individual services (compose.yml)

Add to each service in `compose.yml`:

```yaml
services:
  openwebui:
  # ... rest of configuration
  logging:
  driver: 'json-file'
  options:
  max-size: '10m'
  max-file: '3'
```

## Size recommendations for different services

**High-load services (more logs):**

- `openwebui`, `ollama`, `nginx`, `litellm`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '20m'
  max-file: '5'
```

**Standard services:**

- `postgres`, `redis`, `prometheus`, `grafana`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '10m'
  max-file: '3'
```

**Low-load services:**

- `backrest`, `webhook`, `watchtower`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '5m'
  max-file: '2'
```

---

## Applying changes

### Option 1: Global configuration (recommended)

```bash
# 1. Create backup of current configuration
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup-$(date +%Y%m%d) 2>/dev/null || true

# 2. Create new configuration
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
 "log-driver": "json-file",
 "log-opts": {
 "max-size": "10m",
 "max-file": "3"
 }
}
EOF

# 3. Restart Docker
sudo systemctl restart docker

# 4. Check status
sudo systemctl status docker

# 5. Recreate containers to apply new settings
cd /home/konstantin/Documents/augment-projects/erni-ki
docker compose up -d --force-recreate
```

## Option 2: Configuration in compose.yml

```bash
# 1. Create backup
cp compose.yml .config-backup/compose.yml.backup-$(date +%Y%m%d-%H%M%S)

# 2. Add logging to each service (manually or via sed)
# Example for one service:
# services:
# openwebui:
# logging:
# driver: "json-file"
# options:
# max-size: "10m"
# max-file: "3"

# 3. Apply changes
docker compose up -d --force-recreate
```

---

## Check current settings

```bash
# Check specific container settings
docker inspect erni-ki-openwebui-1 | grep -A 10 "LogConfig"

# Check log size of all containers
docker ps -q | xargs -I {} sh -c 'echo "Container: {}"; docker inspect {} | grep -A 5 "LogPath" | grep LogPath | cut -d\" -f4 | xargs ls -lh 2>/dev/null'

# Total Docker logs size
sudo du -sh /var/lib/docker/containers/*/
```

---

## Clean existing logs

```bash
# WARNING: Will delete all current container logs!

# Stop all containers
docker compose down

# Clean logs
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Start containers
docker compose up -d
```

---

## Monitoring

Add to `scripts/monitor-disk-space.sh`:

```bash
# Docker logs size
DOCKER_LOGS_SIZE=$(sudo du -sh /var/lib/docker/containers/ 2>/dev/null | awk '{print $1}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker logs: $DOCKER_LOGS_SIZE" >> "$LOG_FILE"
```

---

## Savings calculation

**Without rotation:**

- 49 containers × ~100 MB logs = ~5 GB

**With rotation (10m × 3):**

- 49 containers × 30 MB = ~1.5 GB - **Savings: ~3.5 GB**

---

## Recommendations

1. **Use global configuration** via `/etc/docker/daemon.json` - simpler and
   uniform 2. **Configure monitoring** of log size via
   `monitor-disk-space.sh` 3. **Periodically check** log size:
   `sudo du -sh /var/lib/docker/containers/` 4. **Don't set values too small** -
   can lose important logs during diagnostics 5. **Recreate containers** after
   changing settings to apply

---

## Alternative logging drivers

### Syslog (for centralized logging)

{% raw %}

```yaml
logging:
  driver: 'syslog'
  options:
  syslog-address: 'tcp://localhost:514'
  tag: '{{.Name}}'
```

### Local (more efficient than json-file)

```yaml
logging:
  driver: 'local'
  options:
  max-size: '10m'
  max-file: '3'
```

{% endraw %}

---

**Status:** Documentation created **Application:** Requires manual execution of
commands **Priority:** Medium (recommended to apply within a week)

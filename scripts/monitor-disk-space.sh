#!/usr/bin/env bash
# ERNI-KI disk space monitoring
# Portable: uses repo root by default; override with PROJECT_DIR env
# Intended for cron (e.g., daily at 01:00)

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
LOG_FILE="${LOG_FILE:-$PROJECT_DIR/logs/disk-monitor.log}"
THRESHOLD="${THRESHOLD:-80}"  # Warning threshold in %

# Check disk usage
USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')

echo "$(date '+%Y-%m-%d %H:%M:%S') - Disk usage: ${USAGE}%, available: $AVAILABLE" >> "$LOG_FILE"

# Warn if threshold exceeded
if [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ⚠️ WARNING: Disk usage is ${USAGE}% (threshold: ${THRESHOLD}%)" >> "$LOG_FILE"

  # Optional: send webhook notification
  # WEBHOOK_URL="http://localhost:8080/api/webhook/disk-alert"
  # curl -X POST "$WEBHOOK_URL" -H "Content-Type: application/json" \
  #   -d "{\"message\": \"Disk usage: ${USAGE}%, available: $AVAILABLE\"}" 2>/dev/null
fi

# Log project size
PROJECT_SIZE=$(du -sh "$PROJECT_DIR" 2>/dev/null | awk '{print $1}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Project size: $PROJECT_SIZE" >> "$LOG_FILE"

# Log key directories size
DATA_SIZE=$(du -sh "$PROJECT_DIR/data" 2>/dev/null | awk '{print $1}')
BACKUP_SIZE=$(du -sh "$PROJECT_DIR/.config-backup" 2>/dev/null | awk '{print $1}')
LOGS_SIZE=$(du -sh "$PROJECT_DIR/logs" 2>/dev/null | awk '{print $1}')

echo "$(date '+%Y-%m-%d %H:%M:%S') - data/: $DATA_SIZE, .config-backup/: $BACKUP_SIZE, logs/: $LOGS_SIZE" >> "$LOG_FILE"

# Docker statistics
DOCKER_IMAGES=$(docker images -q | wc -l || echo 0)
DOCKER_CONTAINERS=$(docker ps -q | wc -l || echo 0)
DOCKER_VOLUMES=$(docker volume ls -q | wc -l || echo 0)

echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker: $DOCKER_IMAGES images, $DOCKER_CONTAINERS containers, $DOCKER_VOLUMES volumes" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

# Rotate log (keep last 1000 lines)
if [ $(wc -l < "$LOG_FILE") -gt 1000 ]; then
  tail -n 1000 "$LOG_FILE" > "$LOG_FILE.tmp"
  mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

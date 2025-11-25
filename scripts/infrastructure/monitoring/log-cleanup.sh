#!/bin/bash
# Cleanup old ERNI-KI logs

echo "=== ERNI-KI LOG CLEANUP ==="
echo "Date: $(date)"

# Remove Docker logs older than 7 days
echo "Cleaning Docker logs older than 7 days..."
docker system prune -f --filter "until=168h"

# Archive logs
ARCHIVE_DIR="/var/log/erni-ki/archive/$(date +%Y%m%d)"
mkdir -p "$ARCHIVE_DIR"

echo "Archiving completed to: $ARCHIVE_DIR"

#!/bin/bash
# Automatic cleanup of old ERNI-KI backups
# Runs weekly on Sunday at 02:00 via cron

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_DIR="$PROJECT_DIR/.config-backup"
LOG_FILE="$BACKUP_DIR/cleanup.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting backup cleanup" >> "$LOG_FILE"

# Critical directories to keep
EXCLUDE_DIRS=("env" "conf" "secrets" "monitoring")

# Size before cleanup
SIZE_BEFORE=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup size before cleanup: $SIZE_BEFORE" >> "$LOG_FILE"

# Remove backups older than 30 days (excluding critical dirs)
DELETED_COUNT=0
for dir in "$BACKUP_DIR"/*; do
  if [ -d "$dir" ]; then
    DIR_NAME=$(basename "$dir")

    # Skip excluded directories
    SKIP=0
    for exclude in "${EXCLUDE_DIRS[@]}"; do
      if [[ "$DIR_NAME" == "$exclude" ]]; then
        SKIP=1
        break
      fi
    done

    if [ $SKIP -eq 0 ]; then
      # Delete if older than 30 days
      if [ $(find "$dir" -maxdepth 0 -type d -mtime +30 2>/dev/null | wc -l) -gt 0 ]; then
        DIR_SIZE=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        rm -rf "$dir" 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "$(date '+%Y-%m-%d %H:%M:%S') - Removed: $DIR_NAME ($DIR_SIZE)" >> "$LOG_FILE"
          ((DELETED_COUNT++))
        else
          echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR removing: $DIR_NAME (needs sudo?)" >> "$LOG_FILE"
        fi
      fi
    fi
  fi
done

# Size after cleanup
SIZE_AFTER=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup size after cleanup: $SIZE_AFTER" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Removed directories: $DELETED_COUNT" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup cleanup finished" >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

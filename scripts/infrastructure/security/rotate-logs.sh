#!/bin/bash
# ERNI-KI Manual Log Rotation Script (default retention 7 days)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATE=$(date +%Y%m%d-%H%M%S)

echo "🔄 ERNI-KI log rotation - $(date)"

rotate_logs() {
    local log_dir="$1"
    local retention_days="$2"
    local description="$3"

    if [[ ! -d "$log_dir" ]]; then
        echo "📁 Creating directory: $log_dir"
        mkdir -p "$log_dir"
        return
    fi

    echo "🔄 Rotating $description in $log_dir"

    find "$log_dir" -name "*.log" -type f -mtime +0 -exec gzip {} \; 2>/dev/null || true
    find "$log_dir" -name "*.log.gz" -type f -mtime +$retention_days -delete 2>/dev/null || true

    local log_count=$(find "$log_dir" -name "*.log" -type f | wc -l)
    local gz_count=$(find "$log_dir" -name "*.log.gz" -type f | wc -l)

    echo "   📊 Active logs: $log_count, archived: $gz_count"
}

rotate_logs "$PROJECT_ROOT/logs" 7 "primary logs"
rotate_logs "$PROJECT_ROOT/.config-backup/logs" 7 "backup logs"
rotate_logs "$PROJECT_ROOT/monitoring/logs/critical" 30 "critical/alert logs"

echo "🗄️  Cleaning Fluent Bit database files..."
if [[ -d "$PROJECT_ROOT/data/fluent-bit/db" ]]; then
    find "$PROJECT_ROOT/data/fluent-bit/db" -name "*.db-wal" -size +50M -exec cp {} {}.backup-$DATE \; 2>/dev/null || true
    find "$PROJECT_ROOT/data/fluent-bit/db" -name "*.db-wal" -size +50M -exec truncate -s 0 {} \; 2>/dev/null || true
    find "$PROJECT_ROOT/data/fluent-bit/db" -name "*.backup-*" -mtime +1 -exec gzip {} \; 2>/dev/null || true
    find "$PROJECT_ROOT/data/fluent-bit/db" -name "*.backup-*.gz" -mtime +7 -delete 2>/dev/null || true
fi

echo
echo "💾 Disk usage overview:"
echo "   📁 Primary logs: $(du -sh "$PROJECT_ROOT/logs" 2>/dev/null | cut -f1 || echo "0B")"
echo "   📁 Backup logs: $(du -sh "$PROJECT_ROOT/.config-backup/logs" 2>/dev/null | cut -f1 || echo "0B")"
echo "   📁 Critical logs: $(du -sh "$PROJECT_ROOT/monitoring/logs/critical" 2>/dev/null | cut -f1 || echo "0B")"
if [[ -d "$PROJECT_ROOT/data/fluent-bit/db" ]]; then
    echo "   📁 Fluent Bit DB: $(du -sh "$PROJECT_ROOT/data/fluent-bit/db" 2>/dev/null | cut -f1 || echo "0B")"
else
    echo "   📁 Fluent Bit DB: N/A"
fi

echo
echo "💿 Disk free space:"
df -h "$PROJECT_ROOT" | tail -1 | awk '{print "   🖥️  Used: " $3 " of " $2 " (" $5 "), free: " $4}'

echo
echo "✅ Log rotation complete - $(date)"

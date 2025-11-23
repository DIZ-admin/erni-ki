#!/bin/bash
# ERNI-KI Cron Setup for Log Rotation
# Automatic log rotation setup via cron

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ROTATE_SCRIPT="$PROJECT_ROOT/scripts/rotate-logs.sh"

echo "⏰ Setting up automatic log rotation via cron..."

# Check script existence
if [ ! -f "$ROTATE_SCRIPT" ]; then
    echo "❌ Script rotate-logs.sh not found"
    exit 1
fi

# Create temporary crontab file
TEMP_CRON=$(mktemp)
trap "rm -f $TEMP_CRON" EXIT

# Get current crontab (if any)
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Remove old ERNI-KI entries (if any)
sed -i '/# ERNI-KI Log Rotation/d' "$TEMP_CRON"
sed -i '/rotate-logs\.sh/d' "$TEMP_CRON"

# Add new cron tasks
cat >> "$TEMP_CRON" << EOF

# ERNI-KI Log Rotation - Automatic log rotation
# Daily rotation of local logs at 03:00
0 3 * * * cd "$PROJECT_ROOT" && ./scripts/rotate-logs.sh >> logs/rotation.log 2>&1

EOF

# Install new crontab
if crontab "$TEMP_CRON"; then
    echo "✅ Cron tasks installed successfully"
else
    echo "❌ Error installing cron tasks"
    exit 1
fi

# Create rotation logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Create initial log files
touch "$PROJECT_ROOT/logs/rotation.log"

echo ""
echo "📋 Installed cron tasks:"
echo "   🔄 03:00 daily - Local log rotation"
echo ""
echo "📁 Rotation logs:"
echo "   📄 Local logs: $PROJECT_ROOT/logs/rotation.log"
echo ""
echo "🔧 Cron management:"
echo "   • View tasks: crontab -l"
echo "   • Edit: crontab -e"
echo "   • Remove all: crontab -r"
echo ""
echo "🧪 Testing:"
echo "   • Manual rotation: ./scripts/rotate-logs.sh"
# Check cron service status
if systemctl is-active --quiet cron 2>/dev/null || systemctl is-active --quiet crond 2>/dev/null; then
    echo "✅ Cron service is active"
else
    echo "⚠️  Cron service may be inactive. Check: systemctl status cron"
fi

echo ""
echo "🎉 Automatic log rotation setup completed!"

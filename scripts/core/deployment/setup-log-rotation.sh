#!/bin/bash
# ERNI-KI Log Rotation Setup Script
# Configure automatic log rotation with 7-day retention

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/common.sh
source "${SCRIPT_DIR}/../../lib/common.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGROTATE_CONFIG="$PROJECT_ROOT/conf/logrotate/erni-ki"

echo "🔄 Configuring automatic ERNI-KI log rotation..."

# Permission check
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Do not run this script as root. Use sudo only when installing the configuration."
    exit 1
fi

# Create required directories
echo "📁 Creating log directories..."
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/.config-backup/logs"
mkdir -p "$PROJECT_ROOT/monitoring/logs/critical"

# Ensure logrotate configuration exists
if [ ! -f "$LOGROTATE_CONFIG" ]; then
    echo "❌ Logrotate configuration not found: $LOGROTATE_CONFIG"
    exit 1
fi

# Dry-run logrotate configuration
echo "🧪 Testing logrotate configuration..."
if ! logrotate -d "$LOGROTATE_CONFIG" >/dev/null 2>&1; then
    echo "❌ Logrotate configuration error"
    logrotate -d "$LOGROTATE_CONFIG"
    exit 1
fi

# Install configuration system-wide (requires sudo)
echo "⚙️  Installing logrotate configuration system-wide..."
if sudo cp "$LOGROTATE_CONFIG" /etc/logrotate.d/erni-ki; then
    echo "✅ Logrotate configuration installed to /etc/logrotate.d/erni-ki"
else
    echo "❌ Failed to install logrotate configuration"
    exit 1
fi

# Validate installed configuration
echo "🔍 Validating installed configuration..."
if sudo logrotate -d /etc/logrotate.d/erni-ki >/dev/null 2>&1; then
    echo "✅ Logrotate configuration is valid"
else
    echo "❌ Error in installed configuration"
    sudo logrotate -d /etc/logrotate.d/erni-ki
    exit 1
fi

# Create test log for verification
echo "📝 Creating test log..."
echo "$(date): Test log entry for rotation" >> "$PROJECT_ROOT/logs/test-rotation.log"

# Test rotation run
echo "🔄 Test rotation run..."
if sudo logrotate -f /etc/logrotate.d/erni-ki; then
    echo "✅ Test rotation completed successfully"
else
    echo "⚠️  Warnings during test rotation (expected on first run)"
fi

# Check cron job for logrotate
echo "⏰ Checking cron entry for logrotate..."
if crontab -l 2>/dev/null | grep -q logrotate; then
    echo "✅ Cron job for logrotate already configured"
else
    echo "ℹ️  Logrotate will run via system cron (/etc/cron.daily/logrotate)"
fi

echo ""
echo "🎉 Automatic log rotation setup complete!"
echo ""
echo "📊 Configuration:"
echo "   • Daily log rotation"
echo "   • 7-day retention for standard logs"
echo "   • 30-day retention for critical logs"
echo "   • Compression of old logs"
echo "   • Automatic creation of new files"
echo ""
echo "📁 Log directories:"
echo "   • Primary logs: $PROJECT_ROOT/logs/"
echo "   • Backup logs: $PROJECT_ROOT/.config-backup/logs/"
echo "   • Critical logs: $PROJECT_ROOT/monitoring/logs/critical/"
echo ""
echo "🔧 Operations:"
echo "   • Manual rotation: sudo logrotate -f /etc/logrotate.d/erni-ki"
echo "   • Config check: sudo logrotate -d /etc/logrotate.d/erni-ki"
echo "   • Status: sudo cat /var/lib/logrotate/status"

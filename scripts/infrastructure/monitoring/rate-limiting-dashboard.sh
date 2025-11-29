#!/bin/bash

# ERNI-KI Rate Limiting Dashboard
# Simple dashboard for rate limiting monitoring

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$PROJECT_ROOT/logs/rate-limiting-state.json"

clear
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        ERNI-KI Rate Limiting Dashboard                      ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo

# Current status
echo "📊 Current status:"
if [[ -f "$STATE_FILE" ]]; then
    echo "   Last update: $(jq -r '.timestamp' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
    echo "   Blocks per minute: $(jq -r '.total_blocks' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
    echo "   Max excess: $(jq -r '.max_excess' "$STATE_FILE" 2>/dev/null || echo 'N/A')"
else
    echo "   ⚠️  No monitoring data"
fi

echo

# Stats per zone
echo "🎯 Zone statistics:"
if [[ -f "$STATE_FILE" ]] && jq -e '.zones | length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    jq -r '.zones[] | "   \(.zone): \(.count) blocks"' "$STATE_FILE" 2>/dev/null
else
    echo "   ✅ No blocks"
fi

echo

# Top IPs
echo "🌐 Top IP addresses:"
if [[ -f "$STATE_FILE" ]] && jq -e '.top_ips | length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    jq -r '.top_ips[] | "   \(.ip): \(.count) blocks"' "$STATE_FILE" 2>/dev/null | head -5
else
    echo "   ✅ No problematic IPs"
fi

echo

# Recent alerts
echo "🚨 Recent alerts:"
alert_file="$PROJECT_ROOT/logs/rate-limiting-alerts.log"
if [[ -f "$alert_file" ]]; then
    tail -5 "$alert_file" | grep -E "^\[.*\] \[.*\]" | while read -r line; do
        echo "   $line"
    done
else
    echo "   ✅ No alerts"
fi

echo
echo "Updated: $(date)"
echo "Press Ctrl+C to exit"

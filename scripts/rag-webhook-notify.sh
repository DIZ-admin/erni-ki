#!/bin/bash

# RAG Webhook Notification Script
# Sends RAG system status notifications via webhook
# Author: Augment Agent
# Date: 2025-10-24

set -euo pipefail

# Webhook configuration (can be set via env vars)
WEBHOOK_URL="${RAG_WEBHOOK_URL:-}"
WEBHOOK_ENABLED="${RAG_WEBHOOK_ENABLED:-false}"

# Exit if webhook is not configured
if [ "$WEBHOOK_ENABLED" != "true" ] || [ -z "$WEBHOOK_URL" ]; then
    echo "Webhook notifications disabled. Set RAG_WEBHOOK_ENABLED=true and RAG_WEBHOOK_URL to enable."
    exit 0
fi

# Parameters
STATUS="${1:-unknown}"
MESSAGE="${2:-RAG system status update}"
DETAILS="${3:-}"

# Color mapping for Discord/Slack
case "$STATUS" in
    "healthy")
        COLOR="3066993"  # green
        EMOJI="✅"
        ;;
    "warning")
        COLOR="16776960"  # yellow
        EMOJI="⚠️"
        ;;
    "error")
        COLOR="15158332"  # red
        EMOJI="❌"
        ;;
    *)
        COLOR="9807270"  # gray
        EMOJI="ℹ️"
        ;;
esac

# Build Discord payload
DISCORD_PAYLOAD=$(cat <<EOF
{
  "embeds": [{
    "title": "${EMOJI} ERNI-KI RAG System Alert",
    "description": "${MESSAGE}",
    "color": ${COLOR},
    "fields": [
      {
        "name": "Status",
        "value": "${STATUS}",
        "inline": true
      },
      {
        "name": "Timestamp",
        "value": "$(date '+%Y-%m-%d %H:%M:%S UTC')",
        "inline": true
      }
    ],
    "footer": {
      "text": "ERNI-KI RAG Monitor"
    }
  }]
}
EOF
)

# Add details if provided
if [ -n "$DETAILS" ]; then
    DISCORD_PAYLOAD=$(echo "$DISCORD_PAYLOAD" | jq --arg details "$DETAILS" '.embeds[0].fields += [{"name": "Details", "value": $details, "inline": false}]')
fi

# Send webhook
response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$DISCORD_PAYLOAD" \
    "$WEBHOOK_URL" 2>/dev/null || echo "000")

if [ "$response" = "204" ] || [ "$response" = "200" ]; then
    echo "Webhook notification sent successfully (HTTP $response)"
    exit 0
else
    echo "Failed to send webhook notification (HTTP $response)"
    exit 1
fi

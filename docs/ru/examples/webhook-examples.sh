#!/bin/bash

################################################################################
# ERNI-KI Webhook Examples
#
# Demonstrates how to send properly signed webhook requests to ERNI-KI
# webhook endpoints using curl and openssl.
#
# Prerequisites:
#   - curl
#   - openssl
#   - jq (for JSON formatting)
#
# Usage:
#   source webhook-examples.sh
#   send_critical_alert "OllamaDown" "Ollama service is down"
#
################################################################################

set -euo pipefail

# Configuration
WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:5001}"
WEBHOOK_SECRET="${WEBHOOK_SECRET:-your-webhook-secret}"

################################################################################
# Helper Functions
################################################################################

# Generate HMAC-SHA256 signature
generate_signature() {
    local body="$1"
    echo -n "$body" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | sed 's/^.* //'
}

# Pretty print JSON response
print_response() {
    local response="$1"
    if command -v jq &>/dev/null; then
        echo "$response" | jq . 2>/dev/null || echo "$response"
    else
        echo "$response"
    fi
}

# Create alert payload
create_alert_payload() {
    local alertname="$1"
    local severity="${2:-warning}"
    local summary="${3:-$alertname}"
    local status="${4:-firing}"

    cat <<EOF
{
  "alerts": [
    {
      "status": "$status",
      "labels": {
        "alertname": "$alertname",
        "severity": "$severity"
      },
      "annotations": {
        "summary": "$summary"
      },
      "startsAt": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "$alertname"
  },
  "commonLabels": {
    "severity": "$severity"
  },
  "commonAnnotations": {
    "summary": "$summary"
  },
  "externalURL": "http://alertmanager:9093",
  "version": "4",
  "groupKey": "{}:{alertname=\"$alertname\"}"
}
EOF
}

################################################################################
# Generic Webhook Functions
################################################################################

# Send generic alert
send_generic_alert() {
    local alertname="$1"
    local summary="${2:-$alertname}"
    local severity="${3:-warning}"

    echo "📤 Sending generic alert: $alertname"

    local payload=$(create_alert_payload "$alertname" "$severity" "$summary")
    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    local response=$(curl -s -X POST "$WEBHOOK_URL/webhook" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -d "$body")

    print_response "$response"
    echo ""
}

# Send test alert for verification
test_webhook() {
    local endpoint="${1:-generic}"
    echo "[TEST] Testing webhook endpoint: $endpoint"

    local url="$WEBHOOK_URL/webhook"
    if [ "$endpoint" != "generic" ]; then
        url="$url/$endpoint"
    fi

    local payload=$(create_alert_payload "TestAlert" "warning" "Test alert from curl")
    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    echo "   URL: $url"
    echo "   Signature: ${signature:0:16}..."
    echo ""

    local response=$(curl -s -X POST "$url" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "$body")

    local http_code="${response##*HTTP_CODE:}"
    local body_response="${response%HTTP_CODE:*}"

    echo "   HTTP Status: $http_code"
    echo "   Response:"
    print_response "$body_response" | sed 's/^/   /'
    echo ""
}

################################################################################
# Critical Alert Functions
################################################################################

# Send critical alert with auto-recovery
send_critical_alert() {
    local alertname="$1"
    local summary="${2:-$alertname}"
    local service="${3:-ollama}"
    local recovery="${4:-false}"

    echo "🚨 Sending critical alert: $alertname"
    echo "   Service: $service"
    echo "   Auto-recovery: $recovery"

    local payload=$(cat <<EOF
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "$alertname",
        "severity": "critical",
        "service": "$service"
      },
      "annotations": {
        "summary": "$summary"
        $([ "$recovery" = "true" ] && echo ',"recovery":"auto"' || echo '')
      },
      "startsAt": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "$alertname"
  },
  "commonLabels": {
    "severity": "critical",
    "service": "$service"
  },
  "commonAnnotations": {
    "summary": "$summary"
  },
  "externalURL": "http://alertmanager:9093",
  "version": "4",
  "groupKey": "{}:{alertname=\"$alertname\"}"
}
EOF
    )

    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    local response=$(curl -s -X POST "$WEBHOOK_URL/webhook/critical" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -d "$body")

    print_response "$response"
    echo ""
}

# Trigger Ollama recovery
trigger_ollama_recovery() {
    echo "[FIX] Triggering Ollama auto-recovery..."
    send_critical_alert "OllamaServiceDown" "Ollama service is down" "ollama" "true"
}

# Trigger OpenWebUI recovery
trigger_webui_recovery() {
    echo "[FIX] Triggering OpenWebUI auto-recovery..."
    send_critical_alert "OpenWebUIDown" "OpenWebUI service is down" "openwebui" "true"
}

# Trigger SearXNG recovery
trigger_searxng_recovery() {
    echo "[FIX] Triggering SearXNG auto-recovery..."
    send_critical_alert "SearXNGDown" "SearXNG service is down" "searxng" "true"
}

################################################################################
# Warning Alert Functions
################################################################################

# Send warning alert
send_warning_alert() {
    local alertname="$1"
    local summary="${2:-$alertname}"

    echo "[WARN] Sending warning alert: $alertname"

    local payload=$(create_alert_payload "$alertname" "warning" "$summary")
    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    local response=$(curl -s -X POST "$WEBHOOK_URL/webhook/warning" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -d "$body")

    print_response "$response"
    echo ""
}

# Send high memory usage alert
send_memory_warning() {
    local usage="${1:-80}"
    send_warning_alert "HighMemoryUsage" "Memory usage is ${usage}%"
}

# Send high CPU usage alert
send_cpu_warning() {
    local usage="${1:-85}"
    send_warning_alert "HighCPUUsage" "CPU usage is ${usage}%"
}

# Send disk space warning
send_disk_warning() {
    local usage="${1:-90}"
    send_warning_alert "HighDiskUsage" "Disk usage is ${usage}%"
}

################################################################################
# GPU Alert Functions
################################################################################

# Send GPU alert
send_gpu_alert() {
    local alertname="$1"
    local gpu_id="${2:-0}"
    local component="${3:-memory}"
    local summary="${4:-GPU $gpu_id $component error}"

    echo "🎮 Sending GPU alert: $alertname"

    local payload=$(cat <<EOF
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "$alertname",
        "severity": "warning",
        "gpu_id": "$gpu_id",
        "component": "$component"
      },
      "annotations": {
        "summary": "$summary"
      },
      "startsAt": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "$alertname"
  },
  "commonLabels": {
    "severity": "warning",
    "gpu_id": "$gpu_id",
    "component": "$component"
  },
  "commonAnnotations": {
    "summary": "$summary"
  },
  "externalURL": "http://alertmanager:9093",
  "version": "4",
  "groupKey": "{}:{alertname=\"$alertname\"}"
}
EOF
    )

    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    local response=$(curl -s -X POST "$WEBHOOK_URL/webhook/gpu" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -d "$body")

    print_response "$response"
    echo ""
}

# Send GPU memory error
send_gpu_memory_error() {
    local gpu_id="${1:-0}"
    send_gpu_alert "GPUMemoryError" "$gpu_id" "memory" "GPU $gpu_id memory error"
}

# Send CUDA error
send_cuda_error() {
    local gpu_id="${1:-0}"
    send_gpu_alert "CUDAError" "$gpu_id" "cuda" "CUDA error on GPU $gpu_id"
}

# Send GPU temperature warning
send_gpu_temperature_warning() {
    local gpu_id="${1:-0}"
    local temp="${2:-85}"
    send_gpu_alert "GPUTemperatureHigh" "$gpu_id" "temperature" "GPU $gpu_id temperature: ${temp}°C"
}

################################################################################
# Database Alert Functions
################################################################################

# Send database alert
send_database_alert() {
    local alertname="$1"
    local database="${2:-openwebui}"
    local summary="${3:-$alertname}"

    echo "[DB] Sending database alert: $alertname"

    local payload=$(cat <<EOF
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "$alertname",
        "severity": "warning",
        "database": "$database"
      },
      "annotations": {
        "summary": "$summary"
      },
      "startsAt": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "$alertname"
  },
  "commonLabels": {
    "severity": "warning",
    "database": "$database"
  },
  "commonAnnotations": {
    "summary": "$summary"
  },
  "externalURL": "http://alertmanager:9093",
  "version": "4",
  "groupKey": "{}:{alertname=\"$alertname\"}"
}
EOF
    )

    local body=$(echo "$payload" | jq -c .)
    local signature=$(generate_signature "$body")

    local response=$(curl -s -X POST "$WEBHOOK_URL/webhook/database" \
        -H "Content-Type: application/json" \
        -H "X-Signature: $signature" \
        -d "$body")

    print_response "$response"
    echo ""
}

# Send database connection pool warning
send_db_pool_warning() {
    local database="${1:-openwebui}"
    local connections="${2:-32/40}"
    send_database_alert "DatabaseHighConnections" "$database" "Database connection pool: $connections"
}

# Send slow query alert
send_slow_query_alert() {
    local database="${1:-openwebui}"
    send_database_alert "SlowQueries" "$database" "Slow queries detected"
}

################################################################################
# Example Usage
################################################################################

# Print usage information
print_usage() {
    cat <<EOF
ERNI-KI Webhook Examples

Environment Variables:
  WEBHOOK_URL     Base URL (default: http://localhost:5001)
  WEBHOOK_SECRET  Secret key for HMAC (required)

Functions:
  # Generic alerts
  send_generic_alert "AlertName" "Summary" [severity]
  test_webhook [endpoint]

  # Critical alerts
  send_critical_alert "AlertName" "Summary" [service] [recovery]
  trigger_ollama_recovery
  trigger_webui_recovery
  trigger_searxng_recovery

  # Warning alerts
  send_warning_alert "AlertName" "Summary"
  send_memory_warning [usage_percent]
  send_cpu_warning [usage_percent]
  send_disk_warning [usage_percent]

  # GPU alerts
  send_gpu_alert "AlertName" [gpu_id] [component] [summary]
  send_gpu_memory_error [gpu_id]
  send_cuda_error [gpu_id]
  send_gpu_temperature_warning [gpu_id] [temp]

  # Database alerts
  send_database_alert "AlertName" [database] [summary]
  send_db_pool_warning [database]
  send_slow_query_alert [database]

Examples:
  source webhook-examples.sh
  WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" send_memory_warning 85 # pragma: allowlist secret
  WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" trigger_ollama_recovery # pragma: allowlist secret

EOF
}

# If sourced, export functions
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    # Sourced - export all functions
    export -f generate_signature
    export -f print_response
    export -f create_alert_payload
    export -f send_generic_alert
    export -f test_webhook
    export -f send_critical_alert
    export -f trigger_ollama_recovery
    export -f trigger_webui_recovery
    export -f trigger_searxng_recovery
    export -f send_warning_alert
    export -f send_memory_warning
    export -f send_cpu_warning
    export -f send_disk_warning
    export -f send_gpu_alert
    export -f send_gpu_memory_error
    export -f send_cuda_error
    export -f send_gpu_temperature_warning
    export -f send_database_alert
    export -f send_db_pool_warning
    export -f send_slow_query_alert
    export -f print_usage
else
    # Executed - print usage
    print_usage
fi

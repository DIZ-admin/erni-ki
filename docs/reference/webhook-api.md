---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# Справочник API вебхуков

> **Document Version:** 2025.11 **Last Updated:** 2025-11-29 **Status:**
> Webhooks with HMAC authentication enabled (October 2025+)

## Overview

ERNI-KI provides secure webhook endpoints for receiving alerts from Prometheus
Alertmanager and other monitoring systems. All webhook endpoints require
HMAC-SHA256 signature verification for security.

**Base URL:** `http://localhost:5001` (development) or
`https://ki.erni-gruppe.ch` (production)

## Webhook Endpoints

### General Webhook Endpoint

**Endpoint:** `POST /webhook`

Receives and processes generic alerts from Alertmanager.

**Authentication:** Required (HMAC-SHA256 signature)

**Request Headers:**

```
Content-Type: application/json
X-Signature: <HMAC-SHA256-hex-digest>

```

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighCPUUsage",
        "severity": "warning",
        "instance": "server-1"
      },
      "annotations": {
        "summary": "High CPU usage detected",
        "description": "CPU usage is above 80% on server-1"
      },
      "startsAt": "2025-11-29T10:00:00Z",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "HighCPUUsage"
  },
  "commonLabels": {
    "severity": "warning"
  },
  "commonAnnotations": {
    "summary": "High CPU usage detected"
  },
  "externalURL": "http://alertmanager:9093",
  "version": "4",
  "groupKey": "{}:{alertname=\"HighCPUUsage\"}"
}
```

**Response:**

```json
{
  "status": "success",
  "processed": 1,
  "alerts": [
    {
      "alertname": "HighCPUUsage",
      "status": "processed"
    }
  ]
}
```

**Status Codes:**

- `200 OK` - Alerts processed successfully
- `400 Bad Request` - Invalid alert format or missing required fields
- `401 Unauthorized` - Invalid or missing signature
- `429 Too Many Requests` - Rate limit exceeded (10 per minute)
- `500 Internal Server Error` - Server error processing alerts

---

### Critical Alert Endpoint

**Endpoint:** `POST /webhook/critical`

Handles critical severity alerts with automatic recovery procedures.

**Triggering Conditions:**

- Alert severity = "critical"
- System service health issues (ollama, openwebui, searxng)
- Database connection failures
- GPU/memory errors

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "OllamaServiceDown",
        "severity": "critical",
        "service": "ollama"
      },
      "annotations": {
        "summary": "Ollama service is down",
        "recovery": "auto"
      }
    }
  ]
}
```

**Automatic Recovery:**

If the alert includes `"recovery": "auto"` in annotations, the endpoint will:

1. Verify the service is in ALLOWED_SERVICES list (`ollama`, `openwebui`,
   `searxng`)
2. Locate the recovery script: `/app/scripts/recovery/{service}-recovery.sh`
3. Execute the recovery script with timeout of 300 seconds
4. Log recovery attempt results

**Example Recovery Script:**

```bash
#!/bin/bash
# /app/scripts/recovery/ollama-recovery.sh
set -e

echo "Attempting Ollama recovery..."
docker-compose restart ollama
sleep 5

# Verify recovery
if curl -s http://ollama:11434/api/tags >/dev/null 2>&1; then
 echo " Ollama recovered successfully"
 exit 0
else
 echo " Ollama recovery failed"
 exit 1
fi

```

**Response:**

```json
{
  "status": "success",
  "processed": 1,
  "recovery": {
    "service": "ollama",
    "attempted": true,
    "success": true,
    "execution_time_seconds": 12.5,
    "message": "Service recovered successfully"
  }
}
```

---

### Warning Alert Endpoint

**Endpoint:** `POST /webhook/warning`

Handles warning severity alerts with notification routing.

**Triggering Conditions:**

- Alert severity = "warning"
- Resource threshold exceeded (CPU, memory, disk)
- Performance degradation detected

**Notification Routing:**

Alerts are routed to configured channels:

- **Discord** - if `DISCORD_WEBHOOK_URL` is configured
- **Slack** - if `SLACK_WEBHOOK_URL` is configured
- **Telegram** - if `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` are configured

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighMemoryUsage",
        "severity": "warning",
        "instance": "gpu-server"
      },
      "annotations": {
        "summary": "Memory usage above 75%",
        "description": "Used: 24GB/32GB"
      }
    }
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "processed": 1,
  "notifications": {
    "discord": {
      "sent": true,
      "timestamp": "2025-11-29T10:00:00Z"
    },
    "slack": {
      "sent": true,
      "timestamp": "2025-11-29T10:00:00Z"
    },
    "telegram": {
      "sent": false,
      "reason": "Not configured"
    }
  }
}
```

---

### GPU Alert Endpoint

**Endpoint:** `POST /webhook/gpu`

Handles GPU-specific alerts and CUDA errors.

**Triggering Conditions:**

- GPU memory errors
- CUDA kernel failures
- Temperature threshold exceeded
- GPU utilization anomalies

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "GPUMemoryError",
        "severity": "critical",
        "gpu_id": "0",
        "component": "memory"
      },
      "annotations": {
        "summary": "GPU 0 memory error detected"
      }
    }
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "gpu_alert": {
    "gpu_id": "0",
    "component": "memory",
    "action_taken": "Monitored for recovery"
  }
}
```

---

### AI Model Alert Endpoint

**Endpoint:** `POST /webhook/ai`

Handles LLM and model serving issues.

**Triggering Conditions:**

- Ollama service errors
- Model loading failures
- Inference timeout
- Token limit exceeded

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "OllamaInferenceSlow",
        "severity": "warning",
        "model": "llama3.2:3b"
      },
      "annotations": {
        "summary": "Inference latency above 5s",
        "model": "llama3.2:3b",
        "latency_ms": "5234"
      }
    }
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "ai_alert": {
    "model": "llama3.2:3b",
    "latency_ms": 5234,
    "action": "Logged for optimization"
  }
}
```

---

### Database Alert Endpoint

**Endpoint:** `POST /webhook/database`

Handles database-specific alerts.

**Triggering Conditions:**

- PostgreSQL connection failures
- Query performance degradation
- Replication lag
- Disk space warnings
- Connection pool exhaustion

**Request Body:**

```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "PostgreSQLHighConnections",
        "severity": "warning",
        "database": "openwebui"
      },
      "annotations": {
        "summary": "Database connection pool usage above 80%",
        "connections": "32/40"
      }
    }
  ]
}
```

**Response:**

```json
{
  "status": "success",
  "database_alert": {
    "database": "openwebui",
    "connections": "32/40",
    "action": "Logged for monitoring"
  }
}
```

---

## HMAC Signature Generation

All webhook requests must include an `X-Signature` header containing an
HMAC-SHA256 signature of the request body.

### Python Example

```python
import hmac
import hashlib
import json
import requests
from datetime import datetime

# Configuration
WEBHOOK_URL = "http://localhost:5001/webhook/critical"
WEBHOOK_SECRET = "EXAMPLE_WEBHOOK_SECRET"  # pragma: allowlist secret

# Sample alert payload
payload = {
 "alerts": [
 {
 "status": "firing",
 "labels": {
 "alertname": "TestAlert",
 "severity": "critical"
 },
 "annotations": {
 "summary": "Test alert from Python client"
 },
 "startsAt": datetime.utcnow().isoformat() + "Z",
 "endsAt": "0001-01-01T00:00:00Z"
 }
 ],
 "groupLabels": {"alertname": "TestAlert"},
 "commonLabels": {},
 "commonAnnotations": {},
 "externalURL": "http://alertmanager:9093",
 "version": "4",
 "groupKey": '{}:{alertname="TestAlert"}'
}

# Convert payload to JSON
body = json.dumps(payload, separators=(',', ':')).encode('utf-8')

# Generate HMAC-SHA256 signature
signature = hmac.new(
 WEBHOOK_SECRET.encode('utf-8'),
 body,
 hashlib.sha256
).hexdigest()

# Send request
headers = {
 "Content-Type": "application/json",
 "X-Signature": signature
}

response = requests.post(WEBHOOK_URL, data=body, headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")

```

### cURL Example

```bash
#!/bin/bash

WEBHOOK_URL="http://localhost:5001/webhook/critical"
WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" # pragma: allowlist secret

# Create alert payload
PAYLOAD='
{
 "alerts": [
 {
 "status": "firing",
 "labels": {
 "alertname": "TestAlert",
 "severity": "critical"
 },
 "annotations": {
 "summary": "Test alert from cURL"
 },
 "startsAt": "2025-11-29T10:00:00Z",
 "endsAt": "0001-01-01T00:00:00Z"
 }
 ],
 "groupLabels": {"alertname": "TestAlert"},
 "commonLabels": {},
 "commonAnnotations": {},
 "externalURL": "http://alertmanager:9093",
 "version": "4",
 "groupKey": "{}"
}
'

# Generate signature (compact JSON without spaces)
BODY=$(echo "$PAYLOAD" | jq -c .)
SIGNATURE=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex | sed 's/^.* //')

# Send request
curl -X POST "$WEBHOOK_URL" \
 -H "Content-Type: application/json" \
 -H "X-Signature: $SIGNATURE" \
 -d "$BODY"

```

### JavaScript Example

```javascript
const crypto = require('crypto');
const https = require('https');

const WEBHOOK_URL = 'http://localhost:5001/webhook/critical';
const WEBHOOK_SECRET = 'EXAMPLE_WEBHOOK_SECRET'; // pragma: allowlist secret

const payload = {
  alerts: [
    {
      status: 'firing',
      labels: {
        alertname: 'TestAlert',
        severity: 'critical',
      },
      annotations: {
        summary: 'Test alert from JavaScript',
      },
      startsAt: new Date().toISOString(),
      endsAt: '0001-01-01T00:00:00Z',
    },
  ],
  groupLabels: { alertname: 'TestAlert' },
  commonLabels: {},
  commonAnnotations: {},
  externalURL: 'http://alertmanager:9093',
  version: '4',
  groupKey: '{}',
};

// Compact JSON serialization
const body = JSON.stringify(payload);

// Generate HMAC-SHA256 signature
const signature = crypto
  .createHmac('sha256', WEBHOOK_SECRET)
  .update(body)
  .digest('hex');

// Send request
const options = {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Signature': signature,
    'Content-Length': Buffer.byteLength(body),
  },
};

const req = https.request(WEBHOOK_URL, options, res => {
  let data = '';
  res.on('data', chunk => {
    data += chunk;
  });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', JSON.parse(data));
  });
});

req.on('error', error => {
  console.error('Request failed:', error);
});

req.write(body);
req.end();
```

---

## Alertmanager Integration

### Configuring Alertmanager to Send Webhooks

Add the webhook receiver to your Alertmanager configuration:

**File:** `etc/alertmanager/alertmanager.yml`

```yaml
global:
 resolve_timeout: 5m

receivers:
 # Generic webhook receiver
 - name: 'webhook-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook'
 send_resolved: true

 # Critical alerts with auto-recovery
 - name: 'critical-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook/critical'
 send_resolved: true

 # Warning alerts with notifications
 - name: 'warning-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook/warning'
 send_resolved: true

 # GPU-specific alerts
 - name: 'gpu-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook/gpu'
 send_resolved: true

 # AI model alerts
 - name: 'ai-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook/ai'
 send_resolved: true

 # Database alerts
 - name: 'database-receiver'
 webhook_configs:
 - url: 'http://webhook-receiver:5001/webhook/database'
 send_resolved: true

route:
 receiver: 'webhook-receiver'
 group_by: ['alertname', 'cluster', 'service']
 group_wait: 10s
 group_interval: 10s
 repeat_interval: 12h

 routes:
 # Critical alerts go to critical receiver
 - match:
 severity: critical
 receiver: 'critical-receiver'
 continue: true

 # Warning alerts
 - match:
 severity: warning
 receiver: 'warning-receiver'
 continue: true

 # GPU alerts
 - match:
 category: gpu
 receiver: 'gpu-receiver'
 continue: true

 # AI/model alerts
 - match:
 category: ai
 receiver: 'ai-receiver'
 continue: true

 # Database alerts
 - match:
 category: database
 receiver: 'database-receiver'
 continue: true

```

### Setting Webhook Secret

Configure the webhook secret via environment variable:

```bash
# Docker Compose
export ALERTMANAGER_WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" # pragma: allowlist secret

# Or in .env file
echo "ALERTMANAGER_WEBHOOK_SECRET=EXAMPLE_WEBHOOK_SECRET" >> env/alertmanager.env # pragma: allowlist secret

```

---

## Rate Limiting

All webhook endpoints are rate-limited to **10 requests per minute** per IP
address to prevent abuse.

**Rate Limit Headers:**

```
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 8
X-RateLimit-Reset: 1701270600

```

**Rate Limit Exceeded Response:**

```
HTTP/1.1 429 Too Many Requests

{
 "error": "Rate limit exceeded",
 "retry_after": 60
}

```

---

## Error Handling

### Validation Errors

```json
{
  "error": "Payload validation failed",
  "details": {
    "field": "alerts",
    "message": "Field required"
  }
}
```

### Signature Verification Failure

```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing signature"
}
```

### Service Unavailable

```json
{
  "error": "Service error",
  "message": "Failed to process alert",
  "details": "Database connection failed"
}
```

---

## Testing Webhooks

### Using webhook.site

1. Create a test webhook at https://webhook.site
2. Copy the unique URL
3. Send test alerts to that URL to verify payload structure

### Using ngrok

```bash
# Start local webhook receiver
python conf/webhook-receiver/webhook-receiver.py

# In another terminal, create public tunnel
ngrok http 5001

# Configure Alertmanager to send to ngrok URL
# https://xxxx-yy-zzz.ngrok.io/webhook

```

### Health Check

```bash
# Verify webhook receiver is running
curl -s http://localhost:5001/health | jq .

# Expected response:
# {
# "status": "healthy",
# "timestamp": "2025-11-29T10:00:00Z"
# }

```

---

## Troubleshooting

### Signature Verification Failing

**Issue:** Getting 401 Unauthorized on all requests

**Solutions:**

1. Verify `WEBHOOK_SECRET` matches in Alertmanager config
2. Check that JSON serialization is compact (no spaces)
3. Ensure you're signing the raw request body, not the parsed JSON
4. Verify HMAC algorithm is SHA256, not SHA1

### Alerts Not Being Processed

**Issue:** Webhook receives request but alerts not processed

**Solutions:**

1. Check webhook receiver logs: `docker-compose logs webhook-receiver`
2. Verify request body format matches specification
3. Check rate limiting not exceeded
4. Ensure required fields present in alert labels/annotations

### Recovery Script Not Executing

**Issue:** Critical alert received but recovery script not running

**Solutions:**

1. Verify service is in `ALLOWED_SERVICES` (ollama, openwebui, searxng)
2. Check recovery script exists at `/app/scripts/recovery/{service}-recovery.sh`
3. Verify script has execute permissions: `chmod +x {service}-recovery.sh`
4. Check logs for timeout: `timeout 300s` applies

---

## Related Documentation

- [API Reference](./api-reference.md) - Full OpenWebUI API documentation
- See [Monitoring Guide](../operations/monitoring/monitoring-guide.md) for
  details.
- [Development Guide](../development/setup-guide.md) - Local development setup
- [Security Policy](../security/security-policy.md) - Authentication and
  authorization

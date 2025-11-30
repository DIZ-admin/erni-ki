---
language: en
translation_status: complete
doc_version: '2025.11'
title: 'API Reference'
system_version: '0.6.3'
last_updated: '2025-11-30'
system_status: 'Production Ready'
---

# ERNI-KI API Reference

Complete API documentation for ERNI-KI v0.6.3. All endpoints are available through the main OpenWebUI interface or LiteLLM gateway.

**Base URLs:**
- OpenWebUI: `http://localhost:8080` (development) | `https://ki.erni-gruppe.ch` (production)
- LiteLLM Gateway: `http://localhost:8000`
- Webhook Receiver: `http://localhost:5000`

**Authentication:** JWT Bearer token (optional for some endpoints, required for protected operations)

---

## OpenAPI 3.0 Specification

### Info
```yaml
openapi: 3.0.0
info:
  title: ERNI-KI AI Platform API
  version: "0.6.3"
  description: |
    Production-grade AI platform combining OpenWebUI, LiteLLM, and RAG.
    Supports local LLMs (Ollama), document processing (Docling), and search (SearXNG).
  contact:
    name: ERNI-KI Team
    url: https://github.com/DIZ-admin/erni-ki
    email: support@erni-ki.local
  license:
    name: MIT
    url: https://github.com/DIZ-admin/erni-ki/blob/main/LICENSE
```

---

## Core Endpoints

### 1. Chat API

**Service:** OpenWebUI v0.6.36

#### POST /api/chat

Send a message to the LLM and receive a response.

**Request:**
```http
POST /api/chat HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Authorization: Bearer {token}

{
  "message": "What is ERNI-KI?",
  "model": "ollama",
  "temperature": 0.7,
  "top_p": 0.9,
  "max_tokens": 2000
}
```

**Response (200 OK):**
```json
{
  "id": "chat-abc123",
  "object": "text_completion",
  "created": 1701345600,
  "model": "ollama",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "ERNI-KI is a production AI platform..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 150,
    "total_tokens": 165
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": {
    "message": "Invalid request payload",
    "type": "invalid_request_error",
    "param": "model",
    "code": "invalid_value"
  }
}
```

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| message | string | Yes | - | User message to send to LLM |
| model | string | Yes | - | Model name (e.g., "ollama") |
| temperature | float | No | 0.7 | Sampling temperature (0-2) |
| top_p | float | No | 0.9 | Top-p sampling (0-1) |
| max_tokens | integer | No | 2000 | Max response tokens |
| stream | boolean | No | false | Stream response (chunked) |

**Status Codes:**
- `200 OK` - Successful response
- `400 Bad Request` - Invalid parameters
- `401 Unauthorized` - Missing/invalid token
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Model unavailable

---

### 2. RAG Search API

**Service:** SearXNG

#### GET /api/searxng/search

Search across multiple sources using RAG (Retrieval-Augmented Generation).

**Request:**
```http
GET /api/searxng/search?q=python+programming&lang=en&limit=10
Host: localhost:8080
```

**Response (200 OK):**
```json
{
  "query": "python programming",
  "results": [
    {
      "title": "Official Python Website",
      "url": "https://www.python.org",
      "snippet": "The official home of the Python Programming Language...",
      "source": "google",
      "img_url": null
    },
    {
      "title": "Python Tutorials",
      "url": "https://docs.python.org",
      "snippet": "Complete Python documentation and tutorials...",
      "source": "bing"
    }
  ],
  "total_results": 450000,
  "page": 1,
  "page_size": 10
}
```

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| q | string | Yes | - | Search query |
| lang | string | No | en | Language code (en, de, ru, etc) |
| limit | integer | No | 10 | Max results to return |
| page | integer | No | 1 | Page number for pagination |
| time_range | string | No | - | Time filter (day, week, month, year) |
| safe_search | integer | No | 0 | Safe search level (0-2) |

---

### 3. Health Checks

#### GET /health

Check if service is running.

**Response (200 OK):**
```json
{
  "status": "ok",
  "service": "openwebui",
  "version": "0.6.36",
  "timestamp": "2025-11-30T14:30:00Z",
  "dependencies": {
    "database": "connected",
    "redis": "connected",
    "ollama": "connected"
  }
}
```

#### GET /api/v1/health (LiteLLM)

**Response (200 OK):**
```json
{
  "status": "healthy",
  "version": "1.80.0.rc.1",
  "models": [
    {
      "name": "ollama",
      "status": "loaded",
      "memory_mb": 4096
    }
  ]
}
```

---

### 4. Models API

#### GET /api/v1/models

List available models.

**Response (200 OK):**
```json
{
  "object": "list",
  "data": [
    {
      "id": "ollama",
      "object": "model",
      "owned_by": "ollama",
      "permission": [],
      "created": 1701000000,
      "root": "ollama",
      "parent": null
    }
  ]
}
```

---

## Webhook API

**Service:** Webhook Receiver (Custom)

### POST /webhooks/prometheus

Receive Prometheus AlertManager alerts.

**Request:**
```json
{
  "receiver": "slack",
  "status": "firing",
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "OpenWebUIHighLatency",
        "severity": "warning",
        "instance": "openwebui:8080"
      },
      "annotations": {
        "summary": "OpenWebUI response time > 5 seconds",
        "description": "p99 latency: 5.2s (threshold: 5s)"
      },
      "startsAt": "2025-11-30T14:25:00Z",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "OpenWebUIHighLatency"
  },
  "commonLabels": {
    "severity": "warning"
  },
  "commonAnnotations": {
    "summary": "OpenWebUI performance alert"
  },
  "externalURL": "http://localhost:9093",
  "version": "4",
  "groupKey": "{}/{}:{}",
  "truncatedAlerts": 0
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Alert received and processed",
  "alert_count": 1,
  "notifications_sent": 1,
  "timestamp": "2025-11-30T14:25:00Z"
}
```

---

## Document Processing API

### POST /api/process-document

Process documents with Docling (OCR, layout analysis).

**Request:**
```http
POST /api/process-document HTTP/1.1
Host: localhost:8080
Content-Type: multipart/form-data

file=@document.pdf
language=en
extract_tables=true
extract_images=true
```

**Response (200 OK):**
```json
{
  "file_id": "doc-abc123",
  "filename": "document.pdf",
  "pages": 45,
  "text_extracted": true,
  "tables_found": 3,
  "images_found": 12,
  "language": "en",
  "processing_time_ms": 2345,
  "content": {
    "title": "Document Title",
    "text": "Full extracted text...",
    "tables": [
      {
        "page": 5,
        "content": "CSV format table..."
      }
    ]
  }
}
```

---

## Authentication

### Bearer Token

Include JWT token in Authorization header:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Endpoints

#### POST /api/auth/login

**Request:**
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "id": "user-123",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
```

#### POST /api/auth/refresh

Refresh expired token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

---

## Error Handling

### Standard Error Response

```json
{
  "error": {
    "message": "Human-readable error message",
    "type": "error_type",
    "code": "ERROR_CODE",
    "details": {
      "field": "parameter_name",
      "reason": "Additional context"
    }
  }
}
```

### Common Error Codes

| Code | HTTP | Meaning |
|------|------|---------|
| INVALID_REQUEST | 400 | Malformed request |
| AUTHENTICATION_FAILED | 401 | Invalid/missing credentials |
| PERMISSION_DENIED | 403 | User lacks permissions |
| NOT_FOUND | 404 | Resource not found |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| INTERNAL_ERROR | 500 | Server error |
| SERVICE_UNAVAILABLE | 503 | Service temporarily down |

---

## Rate Limiting

**Limits per minute (default):**
- Anonymous: 10 requests
- Authenticated: 100 requests
- Admin: Unlimited

**Headers in response:**
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1701345660
```

---

## Examples

### Python

```python
import requests

url = "http://localhost:8080/api/chat"
headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer YOUR_TOKEN"
}
payload = {
    "message": "Hello, ERNI-KI!",
    "model": "ollama",
    "temperature": 0.7
}

response = requests.post(url, json=payload, headers=headers)
print(response.json())
```

### JavaScript

```javascript
const response = await fetch('http://localhost:8080/api/chat', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_TOKEN'
  },
  body: JSON.stringify({
    message: 'Hello, ERNI-KI!',
    model: 'ollama',
    temperature: 0.7
  })
});

const data = await response.json();
console.log(data);
```

### cURL

```bash
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "message": "Hello, ERNI-KI!",
    "model": "ollama",
    "temperature": 0.7
  }'
```

---

## API Versioning

Current version: **v0.6.3**

- Breaking changes → Major version bump (v1.0.0)
- New features → Minor version bump (v0.7.0)
- Bug fixes → Patch version bump (v0.6.4)

Deprecated endpoints are supported for 2 minor versions before removal.

---

## See Also

- [LiteLLM Documentation](https://docs.litellm.ai)
- [OpenWebUI Documentation](https://docs.openwebui.com)
- [SearXNG Documentation](https://docs.searxng.org)
- [Authentication Guide](../getting-started/authentication.md)
- [Webhook Setup](./webhook-receiver-setup.md)

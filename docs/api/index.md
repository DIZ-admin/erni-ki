---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# API Reference

This section documents the ERNI-KI platform APIs.

## Auth Service API

The Auth Service provides JWT token validation for the ERNI-KI platform.

### Base URLs

| Environment       | URL                        |
| ----------------- | -------------------------- |
| Local Development | `http://localhost:9090`    |
| Docker Internal   | `http://auth-service:9090` |

### Endpoints

#### GET `/` - Service Information

Returns basic information about the auth service.

**Response (200 OK):**

```json
{
  "message": "auth-service is running",
  "version": "1.0.0",
  "status": "healthy",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### GET `/health` - Health Check

Returns the health status of the auth service.

**Response (200 OK):**

```json
{
  "status": "healthy",
  "service": "auth-service",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### GET `/validate` - Token Validation

Validates a JWT token stored in the `token` HTTP cookie.

**Parameters:**

| Name    | Location | Required | Description              |
| ------- | -------- | -------- | ------------------------ |
| `token` | Cookie   | Yes      | JWT authentication token |

**Response (200 OK):**

```json
{
  "message": "authorized",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response (401 Unauthorized):**

```json
{
  "message": "unauthorized",
  "error": "token missing",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Authentication

The Auth Service uses cookie-based JWT authentication. Tokens are stored in HTTP
cookies and validated using the `WEBUI_SECRET_KEY` environment variable.

### OpenAPI Specification

The complete OpenAPI 3.0.3 specification is available in
[auth-service-openapi.yaml](auth-service-openapi.yaml).

## Other APIs

Additional API documentation will be added as services are developed:

- **LiteLLM Proxy** - LLM model routing and load balancing
- **Webhook Service** - Alert handling and auto-recovery
- **Metrics API** - Prometheus metrics endpoints

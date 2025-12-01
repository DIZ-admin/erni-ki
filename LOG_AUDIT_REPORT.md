# Log Audit Report: ERNI-KI System (Last Hour)

**Period:** 2025-12-01 09:14:50 - 10:14:50 (UTC+01:00) **Auditor:** Antigravity
**Date Generated:** 2025-12-01

## Executive Summary

The log audit for the last hour revealed **several critical and warning-level
issues** primarily affecting the AI/RAG stack. The most critical issues involve
**Redis authentication failures** in OpenWebUI and **Ollama embedding service
500 errors**. Additionally, **GPU discovery failures** were detected in the
Ollama service.

Most other services (Nginx, PostgreSQL, Prometheus, SearXNG, Redis, LiteLLM)
showed no errors during this period.

---

## Critical Issues

### 1. Redis Authentication Failures (OpenWebUI)

**Service:** `erni-ki-openwebui-1` **Severity:** 🔴 **CRITICAL**

**Errors:**

```
ERROR [open_webui.main] Error updating models: invalid username-password pair or user is disabled.
redis.exceptions.AuthenticationError: invalid username-password pair or user is disabled.

ERROR [open_webui.routers.retrieval:process_web_search] invalid username-password pair or user is disabled.
ERROR [open_webui.utils.middleware:chat_web_search_handler] 400: invalid username-password pair or user is disabled.
```

**Impact:**

- OpenWebUI cannot connect to Redis for caching and session management.
- Web search functionality is impaired.
- Model updates are failing.

**Root Cause:**

- Incorrect Redis password configuration in OpenWebUI environment.
- Redis password might have changed but OpenWebUI environment not updated.

**Recommendation:**

- Verify Redis password in `env/redis.env` and `secrets/redis_password`.
- Update OpenWebUI environment (`env/openwebui.env`) to match.
- Restart `erni-ki-openwebui-1` after fixing credentials.

---

### 2. Ollama Embedding Service 500 Errors

**Service:** `erni-ki-openwebui-1` → `erni-ki-ollama-1` **Severity:** 🔴
**CRITICAL**

**Errors:**

```
ERROR [open_webui.retrieval.utils:agenerate_ollama_batch_embeddings]
Error generating ollama batch embeddings: 500, message='Internal Server Error', url='http://ollama:11434/api/embed'
aiohttp.client_exceptions.ClientResponseError: 500, message='Internal Server Error'

ERROR [open_webui.routers.retrieval:save_docs_to_vector_db] list index out of range
IndexError: list index out of range
```

**Impact:**

- Document embeddings are failing.
- Vector database ingestion is broken.
- RAG functionality is severely degraded.

**Root Cause:**

- Ollama `/api/embed` endpoint returning 500 errors.
- Likely related to model context size warnings (see below).

**Recommendation:**

- Check Ollama model configuration for embedding models.
- Verify embedding model is loaded: `docker exec erni-ki-ollama-1 ollama list`.
- Review Ollama resource limits and GPU availability.

---

## High-Severity Warnings

### 3. Ollama GPU Discovery Failures

**Service:** `erni-ki-ollama-1` **Severity:** 🟠 **HIGH**

**Warnings:**

```
level=INFO msg="failure during GPU discovery" error="failed to finish discovery before timeout"
level=WARN msg="unable to refresh free memory, using old values"
```

**Impact:**

- GPU may not be properly detected or utilized.
- Performance degradation for inference tasks.
- Memory management issues.

**Recommendation:**

- Check NVIDIA driver status: `nvidia-smi`.
- Verify `runtime: nvidia` is correctly configured in `compose.yml`.
- Review GPU environment variables: `NVIDIA_VISIBLE_DEVICES`,
  `CUDA_VISIBLE_DEVICES`.

---

### 4. Ollama Model Context Size Mismatch

**Service:** `erni-ki-ollama-1` **Severity:** 🟠 **HIGH**

**Warnings:**

```
level=WARN msg="requested context size too large for model" num_ctx=8192 n_ctx_train=2048
level=WARN msg="flash attention enabled but not supported by model"
```

**Impact:**

- Model is being asked to process larger contexts than it was trained for.
- Potential quality degradation or failures in long-context scenarios.

**Recommendation:**

- Review model configuration and reduce `num_ctx` to match model's training
  context (2048).
- Disable flash attention for models that don't support it.

---

### 5. CUDA Detection Failures (OpenWebUI)

**Service:** `erni-ki-openwebui-1` **Severity:** 🟡 **MEDIUM**

**Errors:**

```
ERROR:open_webui.env:Error when testing CUDA but USE_CUDA_DOCKER is true. Resetting USE_CUDA_DOCKER to false: CUDA not available
```

**Impact:**

- OpenWebUI is configured to use CUDA but cannot detect it.
- Falling back to CPU mode.

**Recommendation:**

- Review OpenWebUI runtime configuration in `compose.yml`.
- Ensure `runtime: nvidia` is set for `openwebui` service.
- Check if GPU is needed for OpenWebUI or if this is a false positive.

---

### 6. JWT Security Warning

**Service:** `erni-ki-openwebui-1` **Severity:** 🟡 **MEDIUM**

**Warnings:**

```
WARNI [open_webui.env] ⚠️  SECURITY WARNING: JWT_EXPIRES_IN is set to '-1'
```

**Impact:**

- JWT tokens never expire, which is a security risk.

**Recommendation:**

- Set a reasonable expiration time for JWT tokens in `env/openwebui.env`.
- Recommended: 24 hours (`JWT_EXPIRES_IN=86400`).

---

## Low-Severity Issues

### 7. Connection Errors to LiteLLM (Transient)

**Service:** `erni-ki-openwebui-1` **Severity:** 🟢 **LOW**

**Errors:**

```
ERROR [open_webui.routers.openai:send_get_request] Connection error: Cannot connect to host litellm:4000
```

**Impact:**

- Temporary connection failure at 08:15:42.
- No repeated occurrences suggest a transient issue.

**Recommendation:**

- Monitor for recurrence.
- Verify LiteLLM service health: `docker ps | grep litellm`.

---

### 8. CrossEncoder Error

**Service:** `erni-ki-openwebui-1` **Severity:** 🟢 **LOW**

**Errors:**

```
ERROR [open_webui.routers.retrieval] CrossEncoder: 'dict' object has no attribute 'model_type'
ERROR [open_webui.main] Error updating models: [ERROR: CrossEncoder error]
```

**Impact:**

- CrossEncoder model loading issue.
- Affects re-ranking functionality.

**Recommendation:**

- Review CrossEncoder configuration in OpenWebUI.
- Check if the model file is corrupted.

---

## Healthy Services (No Errors)

The following services showed **no errors or warnings** during the audit period:

- ✅ `erni-ki-nginx-1` - Reverse proxy
- ✅ `erni-ki-db-1` - PostgreSQL database
- ✅ `erni-ki-redis-1` - Redis cache
- ✅ `erni-ki-prometheus` - Metrics collection
- ✅ `erni-ki-searxng-1` - Search engine

---

## Recommended Actions (Priority Order)

| Priority | Action                           | Service               | Impact                   |
| :------- | :------------------------------- | :-------------------- | :----------------------- |
| **P0**   | Fix Redis authentication         | `openwebui`           | Restore caching & search |
| **P0**   | Investigate Ollama 500 errors    | `ollama`, `openwebui` | Fix RAG/embeddings       |
| **P1**   | Resolve GPU discovery timeout    | `ollama`              | Improve performance      |
| **P1**   | Fix model context size config    | `ollama`              | Prevent context errors   |
| **P2**   | Set JWT expiration time          | `openwebui`           | Improve security         |
| **P2**   | Review CUDA config for OpenWebUI | `openwebui`           | Optimize GPU usage       |

---

## Monitoring Recommendations

1. **Set up alerts** for Redis authentication failures.
2. **Monitor Ollama** `/api/embed` endpoint health.
3. **Track GPU utilization** to detect discovery issues early.
4. **Log volume analysis** - consider log rotation for heavy services.

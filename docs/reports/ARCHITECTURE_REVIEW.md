---
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-30'
---

# ERNI-KI PROJECT - ARCHITECTURE REVIEW REPORT

**Date:** 2025-11-30 **Auditor:** Claude Architecture Analysis **Project:**
ERNI-KI (AI Knowledge Infrastructure)

---

## EXECUTIVE SUMMARY

**Overall Assessment:** SOUND microservices architecture with service coupling
concerns

**Key Findings:**

- Proper service isolation via Docker containers
- Clear data flow from Alertmanager → Webhook → Processors
- Tight coupling between webhook handler and notification services
- Missing circuit breaker pattern for external API calls
- Limited retry/resilience mechanisms
- Health checks properly configured
- Error propagation inconsistent across services

---

## 1. MICROSERVICES DESIGN ANALYSIS

### 1.1 Service Inventory

**Core Services:**

```
Webhook Receiver (Flask)
 Alert ingestion
 Signature verification
 Alert processing
 Recovery orchestration

Exporters (Prometheus)
 Ollama exporter (metrics collection)
 RAG exporter (health monitoring)
 Postgres exporter (database metrics)

Auth Service (Go)
 JWT token verification
 Session management
 User validation

Database Layer
 PostgreSQL (persistent storage)
 Redis (caching/sessions)
 Loki (log aggregation)

Monitoring Stack
 Prometheus (metrics)
 Grafana (visualization)
 Alertmanager (alert management)
 Fluent Bit (log shipping)
```

**Service Count:** 13 core services + 5 external services

**Assessment:** WELL-ORGANIZED

### 1.2 Service Coupling Analysis

**Tight Coupling Issues:**

**Issue 1: Webhook Handler → Notification Services**

```python
# webhook_handler.py
def _process_single_alert(self, alert, group_labels):
 message_data = {...}

 # Direct calls to external services
 if DISCORD_WEBHOOK_URL:
 self._send_discord_notification(message_data)

 if SLACK_WEBHOOK_URL:
 self._send_slack_notification(message_data)

 if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
 self._send_telegram_notification(message_data)
```

**Problem:**

- If Discord API is down, entire alert processing fails
- No fallback mechanism
- Blocking I/O blocks other alerts

**Recommendation: Implement Message Queue Pattern**

```python
# Use Redis Queue or RabbitMQ
from rq import Queue
from redis import Redis

redis_conn = Redis()
q = Queue(connection=redis_conn)

# In alert handler:
def _process_single_alert(self, alert, group_labels):
 message_data = {...}

 # Queue notifications asynchronously
 q.enqueue('notify_discord', message_data)
 q.enqueue('notify_slack', message_data)
 q.enqueue('notify_telegram', message_data)

 # Return immediately (fire-and-forget)
 return {"status": "queued"}
```

**Benefit:** Decouples notification delivery from alert processing

**Effort:** 2-3 days

---

**Issue 2: Recovery Script Execution Coupling**

```python
# webhook-receiver.py
def handle_critical_alert(alert):
 service = alert["labels"]["service"]

 if service in ALLOWED_SERVICES:
 run_recovery_script(service) # Blocking call
```

**Problem:**

- Blocks webhook response while script runs
- If script hangs, alert handler is stuck
- No timeout enforcement

**Recommendation:** Use Timeout + Background Task

```python
from threading import Thread
from subprocess import run, TimeoutExpired

def run_recovery_async(service: str):
 """Run recovery script in background with timeout."""
 def _run():
 try:
 result = run(
 [str(RECOVERY_DIR / f"{service}-recovery.sh")],
 timeout=RECOVERY_SCRIPT_TIMEOUT,
 capture_output=True
 )
 logger.info(f"Recovery completed: {service}")
 except TimeoutExpired:
 logger.error(f"Recovery timeout: {service}")
 except Exception as e:
 logger.error(f"Recovery failed: {service}: {e}")

 thread = Thread(target=_run, daemon=False)
 thread.start()
```

---

### 1.3 Data Flow Analysis

**Alert Flow:**

```
Alertmanager
 ↓ (Webhook POST)
Nginx Reverse Proxy
 ↓ (Forward to port 9093)
Webhook Receiver
 ↓ (HTTP POST)
 → Validate signature (HMAC-SHA256)
 → Parse JSON with Pydantic
 → Save to file (JSON)
 → Process alerts
 → Extract metadata
 → Determine severity
 → Call notification services
 → Discord Webhook
 → Slack Webhook
 → Telegram API
 → Trigger recovery scripts (if critical)
 → Run shell scripts in /app/scripts/recovery/
```

**Assessment:** CLEAR data flow

**Issues:**

- No request correlation ID for tracing
- Limited observability (no distributed tracing)
- Error context lost between services

**Recommendation:** Add Request Context Middleware

```python
import uuid
from contextvars import ContextVar

request_id_var: ContextVar[str] = ContextVar('request_id')

@app.before_request
def set_request_id():
 request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
 request_id_var.set(request_id)
 g.request_id = request_id

@app.after_request
def add_request_id_header(response):
 response.headers['X-Request-ID'] = g.request_id
 return response
```

---

## 2. ERROR HANDLING ARCHITECTURE

### 2.1 Error Propagation Patterns

**Current State:** INCONSISTENT

**Example 1: webhook-receiver.py (Catches all errors)**

```python
def process_alert(alert_data, alert_type="general"):
 try:
 # ... processing ...
 except Exception as e:
 logger.error(f"Error processing alert: {e}")
 # Returns result dict, doesn't propagate error
```

**Example 2: webhook_handler.py (Catches network errors)**

```python
try:
 self._process_single_alert(alert, group_labels)
 results["processed"] += 1
except requests.RequestException as e:
 # Different exception handling strategy
 logger.error(f"Network error: {e}")
 results["processed"] += 1
```

**Problem:**

- No consistent error classification
- Difficult to distinguish retriable vs permanent errors
- No proper HTTP status codes returned

**Recommendation: Create Error Hierarchy**

```python
from enum import Enum

class AlertErrorType(Enum):
 VALIDATION_ERROR = "validation"
 NETWORK_ERROR = "network"
 TIMEOUT_ERROR = "timeout"
 PROCESSING_ERROR = "processing"
 SERVICE_ERROR = "service"

class AlertProcessingError(Exception):
 def __init__(self, error_type: AlertErrorType, message: str, retriable: bool = False):
 self.error_type = error_type
 self.message = message
 self.retriable = retriable
 super().__init__(message)

# Usage:
try:
 response = requests.post(url, timeout=10)
except requests.Timeout:
 raise AlertProcessingError(
 AlertErrorType.TIMEOUT_ERROR,
 "Notification delivery timeout",
 retriable=True
 )
```

**Effort:** 1 day

---

### 2.2 Resilience Patterns

**Current State:** LIMITED

**Missing Patterns:**

- Circuit Breaker (for external APIs)
- Retry with exponential backoff
- Bulkhead pattern (resource isolation)
- Fallback strategies

**Recommended Implementation:**

```python
from tenacity import retry, stop_after_attempt, wait_exponential
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
@retry(
 stop=stop_after_attempt(3),
 wait=wait_exponential(multiplier=1, min=2, max=10)
)
def send_notification(platform: str, url: str, payload: dict):
 """Send notification with automatic retry and circuit breaker."""
 response = requests.post(url, json=payload, timeout=10)
 response.raise_for_status()
 return response
```

**Benefits:**

- Automatic retry on transient failures
- Circuit breaker prevents cascading failures
- Exponential backoff prevents thundering herd

**Effort:** 1 day

---

## 3. SCALABILITY ASSESSMENT

### 3.1 Horizontal Scalability

**Current State:** LIMITED

**Issues:**

- Single webhook receiver instance
- No load balancing for webhook endpoints
- Alert queue not distributed

**Recommendation: Deploy Multiple Webhook Instances**

```yaml
# docker-compose.yml
webhook-receiver-1:
 image: erni-ki/webhook-receiver
 ports:
 - "9093:9093"
 environment:
 - INSTANCE_ID=webhook-1
 - REDIS_URL=redis://redis:6379

webhook-receiver-2:
 image: erni-ki/webhook-receiver
 ports:
 - "9094:9093"
 environment:
 - INSTANCE_ID=webhook-2
 - REDIS_URL=redis://redis:6379

# Nginx load balance
upstream webhook_receivers {
 server webhook-receiver-1:9093;
 server webhook-receiver-2:9093;
}

server {
 location /webhook {
 proxy_pass http://webhook_receivers;
 }
}
```

**Effort:** 2-3 days

### 3.2 Vertical Scalability

**Current State:** ADEQUATE

**Resource Limits Configured:**

```yaml
mem_limit: 4g
cpus: '2.0'
```

**Recommendations:**

- Monitor memory usage patterns
- Profile CPU hotspots
- Optimize database queries

---

## 4. DEPENDENCY ANALYSIS

**Internal Dependencies:**

```
Webhook Receiver
 Pydantic (validation)
 Flask (HTTP server)
 Requests (HTTP client)
 Python stdlib

Exporters
 Prometheus Client (metrics)
 Requests (HTTP client)
 Threading

Auth Service
 Gin (HTTP framework)
 JWT-Go (token handling)
 Go stdlib
```

**Assessment:** MINIMAL, appropriate dependencies

---

## 5. COMMUNICATION PATTERNS

### 5.1 Synchronous Communication

**Current:** All services communicate synchronously

**Issues:**

- Alert processing blocked by notification delivery
- Cascading failures possible
- No deferred processing capability

**Recommendation:** Introduce asynchronous messaging for:

- Notification delivery (Discord, Slack, Telegram)
- Recovery script execution
- Metrics export

---

## 6. MONITORING & OBSERVABILITY

**Current State:** GOOD

**Implemented:**

- Health checks on all services
- Prometheus metrics exposed
- Logging to Loki
- Distributed tracing prepared (Jaeger config exists)

**Gaps:**

- Request tracing not fully implemented
- Error rate SLI not defined
- Performance baselines not established

---

## ARCHITECTURE SCORECARD

```

 ARCHITECTURE ASSESSMENT SCORECARD


 Service Isolation:
 Data Flow Clarity:
 Error Handling:
 Resilience Patterns:
 Scalability:
 Observability:
 Documentation:

 OVERALL: 75%
 GOOD WITH GAPS

```

---

## REMEDIATION ROADMAP

**Phase 1 (Sprint 1):** Error handling & resilience

- Add error classification hierarchy
- Implement circuit breaker for external APIs
- Add retry logic with exponential backoff
- **Effort:** 3 days

**Phase 2 (Sprint 2):** Asynchronous patterns

- Introduce message queue (Redis/RabbitMQ)
- Decouple notification delivery
- Implement background job workers
- **Effort:** 4 days

**Phase 3 (Sprint 3):** Scalability

- Deploy multiple webhook instances
- Implement load balancing
- Add distributed tracing
- **Effort:** 3 days

**Phase 4 (Sprint 4):** Observability

- Complete distributed tracing implementation
- Define SLIs/SLOs
- Add performance monitoring
- **Effort:** 2 days

**Total Effort:** 12 days

---

**Report Generated:** 2025-11-30 **Overall Architecture Grade:** B (Good with
improvable areas)

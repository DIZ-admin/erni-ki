---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# Testing Guide

> **Document Version:** 1.0 **Last Updated:** 2025-11-29 **Test Framework:**
> pytest (Python), Jest/Playwright (JavaScript) **Coverage Target:** >85%

This guide covers running, writing, and maintaining tests in ERNI-KI.

## Quick Start

```bash
# Run all tests
npm run test

# Run Python tests
pytest tests/ -v

# Run tests with coverage
npm run test:coverage
pytest tests/ --cov

# Watch mode (automatically rerun on changes)
npm run test -- --watch
pytest-watch tests/

```

## Test Structure

```
erni-ki-1/
 tests/
 unit/
 webhook-receiver.test.py
 logger.test.py
 sync-models.test.py
 integration/
 webhook-integration.test.py
 database-integration.test.py
 api-integration.test.py
 e2e/
 workflows.spec.ts
 api.spec.ts
 __tests__/
 (JavaScript tests)
 conftest.py

```

## Unit Tests

### Running Unit Tests

```bash
# Python unit tests
pytest tests/unit/ -v

# JavaScript unit tests
npm run test -- tests/unit

# Specific test file
pytest tests/unit/webhook-receiver.test.py -v

# Specific test function
pytest tests/unit/webhook-receiver.test.py::test_verify_signature -v

# Stop on first failure
pytest -x

# Show print statements
pytest -s

```

### Writing Python Unit Tests

Example: Testing HMAC signature verification

```python
# tests/unit/webhook-receiver.test.py
import json
import pytest
# Example of direct import via file path
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "webhook_handler", Path("conf/webhook-receiver/webhook_handler.py")
)

class TestWebhookSignatures:
 """Test HMAC signature verification"""

 def test_valid_signature(self):
 """Valid signature should be accepted"""
 secret = "EXAMPLE_WEBHOOK_KEY"  # pragma: allowlist secret
 payload = {"alerts": []}
 body = json.dumps(payload, separators=(",", ":")).encode()

 import hmac, hashlib
 signature = hmac.new(
 secret.encode(), body, hashlib.sha256
 ).hexdigest()

 result = verify_signature(body, signature, secret)
 assert result is True

 def test_invalid_signature(self):
 """Invalid signature should be rejected"""
 secret = "EXAMPLE_WEBHOOK_KEY"  # pragma: allowlist secret
 body = b'{"alerts":[]}'
 invalid_signature = "0" * 64

 result = verify_signature(body, invalid_signature, secret)
 assert result is False

 def test_missing_signature(self):
 """Missing signature should be rejected"""
 body = b'{"alerts":[]}'
 result = verify_signature(body, None, "example-secret")
 assert result is False

 @pytest.mark.parametrize("secret", [
 "short",
 "a" * 100,
 "special!@#$%^&*()",
 "unicode-",
 ])
 def test_various_secrets(self, secret):
 """Verify signature works with various secret types"""
 import hmac, hashlib
 body = b'test-payload'
 signature = hmac.new(
 secret.encode(), body, hashlib.sha256
 ).hexdigest()

 result = verify_signature(body, signature, secret)
 assert result is True

```

### Writing JavaScript Unit Tests

Example: Testing alert payload validation

```javascript
// __tests__/webhook-validation.test.js
const { validateAlertPayload } = require('../src/webhook');

describe('Alert Payload Validation', () => {
  test('valid payload is accepted', () => {
    const payload = {
      alerts: [
        {
          status: 'firing',
          labels: { alertname: 'Test' },
          annotations: { summary: 'Test alert' },
        },
      ],
      groupLabels: {},
      commonLabels: {},
      commonAnnotations: {},
      externalURL: 'http://alertmanager:9093',
      version: '4',
      groupKey: '{}',
    };

    expect(validateAlertPayload(payload)).toBe(true);
  });

  test('missing alerts field is rejected', () => {
    const payload = { groupLabels: {} };
    expect(validateAlertPayload(payload)).toBe(false);
  });

  test('invalid alert status is rejected', () => {
    const payload = {
      alerts: [
        {
          status: 'invalid',
          labels: {},
          annotations: {},
        },
      ],
    };
    expect(validateAlertPayload(payload)).toBe(false);
  });

  test.each([['firing'], ['resolved']])('status "%s" is valid', status => {
    const payload = {
      alerts: [{ status, labels: {}, annotations: {} }],
    };
    expect(validateAlertPayload(payload)).toBe(true);
  });
});
```

## Integration Tests

### Running Integration Tests

```bash
# Start services in background
docker-compose up -d db redis ollama

# Run integration tests (requires services running)
pytest tests/integration/ -v --tb=short

# JavaScript integration tests
npm run test:integration

# With specific service
docker-compose up -d webhook-receiver
pytest tests/integration/webhook-integration.test.py -v

```

### Writing Integration Tests

Example: Testing webhook endpoint with real database

```python
# tests/integration/webhook-integration.test.py
import json
import pytest
import requests
from datetime import datetime

@pytest.fixture
 def webhook_client():
 """Create webhook client"""
 return WebhookTestClient(
 base_url="http://localhost:5001",
 secret="EXAMPLE_WEBHOOK_KEY",  # pragma: allowlist secret
 )

@pytest.fixture
def sample_alert():
 """Create sample alert payload"""
 return {
 "alerts": [{
 "status": "firing",
 "labels": {
 "alertname": "TestAlert",
 "severity": "warning"
 },
 "annotations": {
 "summary": "Test alert"
 },
 "startsAt": datetime.utcnow().isoformat() + "Z",
 "endsAt": "0001-01-01T00:00:00Z"
 }],
 "groupLabels": {"alertname": "TestAlert"},
 "commonLabels": {},
 "commonAnnotations": {},
 "externalURL": "http://alertmanager:9093",
 "version": "4",
 "groupKey": '{}'
 }

class TestWebhookEndpoints:
 """Test webhook endpoints with real services"""

 def test_generic_webhook_accepted(self, webhook_client, sample_alert):
 """Generic webhook endpoint should accept valid alerts"""
 response = webhook_client.post("/webhook", sample_alert)

 assert response.status_code == 200
 assert response.json()["status"] == "success"
 assert response.json()["processed"] == 1

 def test_critical_alert_triggers_recovery(
 self, webhook_client, sample_alert
 ):
 """Critical alert should trigger recovery if configured"""
 sample_alert["alerts"][0]["labels"]["severity"] = "critical"
 sample_alert["alerts"][0]["labels"]["service"] = "ollama"
 sample_alert["alerts"][0]["annotations"]["recovery"] = "auto"

 response = webhook_client.post("/webhook/critical", sample_alert)

 assert response.status_code == 200
 result = response.json()
 assert result.get("recovery", {}).get("service") == "ollama"

 def test_invalid_signature_rejected(self, sample_alert):
 """Webhook with invalid signature should be rejected"""
 response = requests.post(
 "http://localhost:5001/webhook",
 json=sample_alert,
 headers={"X-Signature": "invalid-signature"}
 )

 assert response.status_code == 401
 assert "Unauthorized" in response.text

 def test_rate_limiting_enforced(self, webhook_client, sample_alert):
 """Rate limiting should be enforced"""
 # Send 10 requests (limit)
 for _ in range(10):
 response = webhook_client.post("/webhook", sample_alert)
 assert response.status_code == 200

 # 11th request should be rate limited
 response = webhook_client.post("/webhook", sample_alert)
 assert response.status_code == 429

```

## End-to-End Tests

### Running E2E Tests

```bash
# Start all services
docker-compose up -d

# Wait for services to be healthy
sleep 30

# Run Playwright E2E tests
npm run test:e2e

# Run specific test file
npm run test:e2e -- webhook.spec.ts

# Run in headed mode (see browser)
npm run test:e2e -- --headed

# Debug mode
npm run test:e2e -- --debug

```

### Writing E2E Tests

Example: Testing webhook alert processing through UI

```typescript
// tests/e2e/webhook.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Webhook Alert Processing', () => {
  test('should display received alert in dashboard', async ({ page }) => {
    // Navigate to dashboard
    await page.goto('http://localhost:8080');

    // Send webhook alert
    const alertPayload = {
      alerts: [
        {
          status: 'firing',
          labels: {
            alertname: 'E2ETest',
            severity: 'critical',
          },
          annotations: {
            summary: 'E2E test alert',
          },
        },
      ],
      groupLabels: {},
      commonLabels: {},
      commonAnnotations: {},
      externalURL: 'http://alertmanager:9093',
      version: '4',
      groupKey: '{}',
    };

    const response = await fetch('http://localhost:5001/webhook', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Signature': generateSignature(JSON.stringify(alertPayload)),
      },
      body: JSON.stringify(alertPayload),
    });

    expect(response.ok).toBeTruthy();

    // Wait for alert to appear in UI
    await page.waitForSelector('[data-testid="alert-E2ETest"]', {
      timeout: 5000,
    });

    // Verify alert details
    const alertElement = page.locator('[data-testid="alert-E2ETest"]');
    await expect(alertElement).toContainText('E2E test alert');
  });

  test('should process critical alert with recovery', async ({ page }) => {
    // Send critical alert with recovery
    const response = await page.request.post(
      'http://localhost:5001/webhook/critical',
      {
        data: {
          alerts: [
            {
              status: 'firing',
              labels: {
                alertname: 'ServiceDown',
                service: 'ollama',
              },
              annotations: {
                summary: 'Service is down',
                recovery: 'auto',
              },
            },
          ],
          groupLabels: {},
          commonLabels: {},
          commonAnnotations: {},
          externalURL: 'http://alertmanager:9093',
          version: '4',
          groupKey: '{}',
        },
      },
    );

    expect(response.ok()).toBeTruthy();

    const result = await response.json();
    expect(result.recovery?.success).toBeDefined();
  });
});

function generateSignature(body: string): string {
  const crypto = require('crypto');
  const secret = process.env.WEBHOOK_SECRET || 'test-secret';
  return crypto.createHmac('sha256', secret).update(body).digest('hex');
}
```

## Code Coverage

### Viewing Coverage

```bash
# Generate coverage report
npm run test:coverage
pytest tests/ --cov --cov-report=html

# View HTML report
open htmlcov/index.html # macOS
xdg-open htmlcov/index.html # Linux

# View terminal report
pytest tests/ --cov --cov-report=term-missing

```

### Coverage Requirements

- **Overall target:** >85%
- **Critical functions:** >90%
- **Security-related code:** 100%
- **New code:** >80%

### Improving Coverage

```bash
# Find untested lines
pytest tests/ --cov --cov-report=term-missing

# Show coverage by file
coverage report -m

# Highlight missing lines in Python
coverage html

```

## Continuous Integration

### Local CI Check

```bash
# Run all quality checks locally
npm run lint
npm run test
npm run test:coverage
mypy .

```

### GitHub Actions

Tests run automatically on:

- Push to develop/main branches
- Pull requests
- Scheduled nightly runs

View results: https://github.com/erni-gruppe/erni-ki-1/actions

## Test Databases

### Using Test Database

```python
# conftest.py fixture
@pytest.fixture
def db_session():
 """Create test database session"""
 # Create test database
 engine = create_engine('sqlite:///:memory:')
 Session = sessionmaker(bind=engine)
 session = Session()

 yield session

 # Cleanup
 session.close()

# Usage in test
def test_alert_storage(db_session):
 """Test storing alert in database"""
 alert = Alert(name="Test", severity="critical")
 db_session.add(alert)
 db_session.commit()

 retrieved = db_session.query(Alert).filter_by(name="Test").first()
 assert retrieved is not None
 assert retrieved.severity == "critical"

```

### Using Real Database in Docker

```bash
# Start test database container
docker run -d \
 -e POSTGRES_USER=test \
 -e POSTGRES_PASSWORD=test \
 -p 5433:5432 \
 postgres:15

# Run tests with test database
TEST_DATABASE_URL=postgresql://example:example@localhost:5433/test pytest tests/  # pragma: allowlist secret

# Stop container
docker stop <container_id>

```

## Debugging Tests

### Python Debugging

```bash
# Run with debugger on failure
pytest -x --pdb

# Drop into debugger at specific test
pytest tests/test_file.py::test_function --pdb

# Print statements visible
pytest -s

```

### JavaScript Debugging

```bash
# Debug mode with breakpoints
npm run test -- --debug

# Use Chrome DevTools
# Paste chrome://inspect in browser

# Pause on failure
npm run test -- --pause-on-failure

```

## Test Fixtures

### Common Python Fixtures

```python
# conftest.py
import pytest
from datetime import datetime

@pytest.fixture
def alert_payload():
 """Standard alert payload"""
 return {
 "alerts": [{
 "status": "firing",
 "labels": {"alertname": "Test"},
 "annotations": {"summary": "Test alert"},
 "startsAt": datetime.utcnow().isoformat() + "Z",
 "endsAt": "0001-01-01T00:00:00Z"
 }],
 "groupLabels": {},
 "commonLabels": {},
 "commonAnnotations": {},
 "externalURL": "http://alertmanager:9093",
 "version": "4",
 "groupKey": "{}"
 }

@pytest.fixture
def mock_webhook_secret(monkeypatch):
 """Mock webhook secret"""
 monkeypatch.setenv("WEBHOOK_SECRET", "test-secret")

@pytest.fixture
def mock_database(monkeypatch):
 """Mock database connection"""
 # Mock database here
 pass

```

## Troubleshooting Tests

### Test Failures

```bash
# Show full error output
pytest -vv --tb=long

# Show local variables on failure
pytest -l

# Stop at first failure
pytest -x

# Show slow tests
pytest --durations=10

```

### Flaky Tests

Tests that randomly fail need investigation:

```bash
# Run specific test multiple times
pytest tests/test_file.py::test_function --count=10

# Run with random seed
pytest --random-order

# Increase timeout for timing-sensitive tests
@pytest.mark.timeout(30)
def test_slow_operation():
 pass

```

### Mocking External Services

```python
# Mock requests to external APIs
import pytest
from unittest.mock import patch, MagicMock

@pytest.fixture
def mock_ollama():
 """Mock Ollama API"""
 with patch('requests.get') as mock_get:
 mock_response = MagicMock()
 mock_response.json.return_value = {"models": []}
 mock_get.return_value = mock_response
 yield mock_get

def test_with_mock_ollama(mock_ollama):
 # Code that calls Ollama will use mock
 result = get_ollama_models()
 mock_ollama.assert_called_once()

```

## Best Practices

1. **Test Behavior, Not Implementation**

- Focus on what code does, not how it does it
- Makes refactoring safer

2. **Use Descriptive Test Names**

- `test_valid_signature_accepted` (good)
- `test_sig()` (bad)

3. **One Assertion Per Test**

- Easier to debug when tests fail
- Clear test purpose

4. **Use Fixtures for Setup**

- Keep tests DRY
- Consistent test data

5. **Test Edge Cases**

- Empty inputs
- Large inputs
- Invalid formats
- Rate limits

6. **Keep Tests Fast**

- Use mocks for external services
- Use in-memory databases
- Avoid unnecessary delays

## Related Documentation

- [Development Setup Guide](./setup-guide.md)
- [Code Quality Standards](../quality/code-standards.md)
- [API Reference](../reference/api-reference.md)
- [Webhook Testing Examples](../examples/index.md)

---

**Questions about testing?** Check our
[troubleshooting guide](../troubleshooting/common-issues.md) or open an issue!

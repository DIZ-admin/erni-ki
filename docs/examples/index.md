---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-29'
---

# ERNI-KI Code Examples

This directory contains practical, runnable examples for integrating with
ERNI-KI services.

## Webhook Integration Examples

### Python Client Example

**File:** `webhook-client-python.py`

A complete Python CLI client for sending signed webhook requests to ERNI-KI
webhook endpoints.

**Features:**

- HMAC-SHA256 signature generation
- Support for all webhook endpoint types
- Customizable labels and annotations
- Built-in convenience methods for critical, GPU, and database alerts
- Error handling and timeout support
- JSON output option for parsing

**Usage:**

```bash
# Install dependencies
pip install requests

# Set webhook secret
export WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" # pragma: allowlist secret

# Send critical alert with auto-recovery
python webhook-client-python.py \
  --endpoint critical \
  --alert-name "OllamaDown" \
  --severity critical \
  --summary "Ollama service is down" \
  --service ollama \
  --auto-recovery \
  --json-output

# Send GPU alert
python webhook-client-python.py \
  --endpoint gpu \
  --alert-name "GPUMemoryError" \
  --gpu-id 0 \
  --gpu-component memory \
  --summary "GPU 0 memory error detected"

# Send warning alert with custom labels
python webhook-client-python.py \
  --endpoint warning \
  --alert-name "HighMemory" \
  --severity warning \
  --summary "Memory usage above 80%" \
  --label "instance=gpu-server" \
  --label "component=memory"

# See all options
python webhook-client-python.py --help

```

### Shell Script Examples

**File:** `webhook-examples.sh`

Bash functions for sending webhook alerts using curl and openssl.

**Features:**

- Modular function library - source and use individual functions
- No external dependencies (uses curl + openssl)
- Support for all webhook endpoint types
- Helper functions for common scenarios
- Signature generation and verification

**Usage:**

```bash
# Source the library
source webhook-examples.sh

# Set webhook secret
export WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" # pragma: allowlist secret

# Test webhook endpoint
test_webhook critical

# Send memory warning
send_memory_warning 85

# Trigger Ollama recovery
trigger_ollama_recovery

# Send custom GPU alert
send_gpu_alert "GPUCUDAError" 0 cuda "CUDA error on GPU 0"

# Send database alert
send_db_pool_warning "openwebui" "32/40"

# List all available functions
print_usage

```

## Integration with Monitoring Systems

### Alertmanager Integration

To configure Alertmanager to send webhooks to ERNI-KI:

1. Set the webhook secret in your environment:

   ```bash
   export ALERTMANAGER_WEBHOOK_SECRET="EXAMPLE_WEBHOOK_SECRET" # pragma: allowlist secret
   ```

2. Configure Alertmanager routing in `etc/alertmanager/alertmanager.yml`:

   ```yaml
   receivers:
     - name: 'critical-receiver'
       webhook_configs:
         - url: 'http://webhook-receiver:5001/webhook/critical'

   route:
     routes:
       - match:
           severity: critical
         receiver: 'critical-receiver'
   ```

3. Use the webhook client to test:

   ```bash
   python webhook-client-python.py \
     --endpoint critical \
     --alert-name "TestAlert" \
     --summary "Test alert"
   ```

### Custom Integration

To integrate ERNI-KI webhooks in your application:

1. Generate HMAC-SHA256 signature of request body
2. Set `X-Signature` header to the hex digest
3. POST to webhook endpoint with `Content-Type: application/json`

See [Webhook API Reference](../reference/webhook-api.md) for complete
specification.

## Testing

### Quick Webhook Test

```bash
# Source examples and set secret
source webhook-examples.sh
export WEBHOOK_SECRET="TEST_WEBHOOK_SECRET" # pragma: allowlist secret

# Run all webhook types
test_webhook generic
test_webhook critical
test_webhook warning
test_webhook gpu
test_webhook ai
test_webhook database

# Check webhook receiver logs
docker-compose logs -f webhook-receiver

```

### Integration Test

```bash
# Start webhook receiver
docker-compose up -d webhook-receiver

# Send test alert
python webhook-client-python.py \
  --url http://localhost:5001 \
  --secret "test-secret" \
  --endpoint critical \
  --alert-name "IntegrationTest" \
  --summary "Testing integration" \
  --json-output

# Monitor webhook receiver logs
docker-compose logs webhook-receiver

```

## Related Documentation

- [Webhook API Reference](../reference/webhook-api.md) - Complete API
  specification
- [API Reference](../reference/api-reference.md) - Full OpenWebUI API
  documentation
- [Development Setup Guide](../development/setup-guide.md) - Local development
  setup
- [Security Policy](../security/security-policy.md) - Authentication and
  authorization

## Troubleshooting

### Signature Verification Failing

**Issue:** Getting 401 Unauthorized

**Solution:** Verify webhook secret and JSON serialization:

```bash
# Generate compact JSON (no spaces)
python -m json.tool --compact <<< '{"test":"value"}'

# Verify signature locally
python -c "
import hmac, hashlib, json
secret = 'EXAMPLE_WEBHOOK_SECRET'  # pragma: allowlist secret
body = json.dumps({'test': 'value'}, separators=(',', ':')).encode()
sig = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
print(f'Signature: {sig}')
"

```

### Webhook Not Receiving Alerts

**Issue:** Alerts sent but not processed

**Solution:** Check webhook receiver logs:

```bash
docker-compose logs webhook-receiver | grep "error\|ERROR"
docker-compose logs webhook-receiver | grep "TestAlert"

```

### Rate Limiting

**Issue:** Getting 429 Too Many Requests

**Solution:** Wait before sending more alerts (10 per minute limit):

```bash
# Use exponential backoff
for i in {1..3}; do
  python webhook-client-python.py ... || sleep $((2 ** i))
done

```

## Contributing Examples

To add new examples:

1. Create a new file in this directory
2. Include usage comments at the top
3. Add entry to this documentation file
4. Test with actual webhook receiver

---

For more information, see the
[full webhook API documentation](../reference/webhook-api.md).

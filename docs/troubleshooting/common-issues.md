---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-09'
---

# Troubleshooting Guide

> **Document Version:** 1.0 **Last Updated:** 2025-12-09 **Resolution Time:**
> Most issues resolvable in <15 minutes

This guide helps diagnose and resolve common ERNI-KI issues.

## Quick Diagnostics

### System Health Check

```bash
# Check all services running
docker-compose ps

# Expected: All services showing "Up"
# If not: docker-compose logs <service_name>

# Check resource usage
docker stats
# If high: Increase Docker memory limit

# Check network connectivity
curl -s http://localhost:8080/health | jq .
curl -s http://localhost:5001/health | jq .
curl -s http://ollama:11434/api/tags | jq .

# Check disk space
df -h
# If low (<5GB): Clean up old images/containers
docker system prune -a


```

### Log Collection

```bash
# Collect all service logs (last hour)
docker-compose logs --since 1h > erni-ki-logs.txt

# Specific service logs
docker-compose logs webhook-receiver --since 1h
docker-compose logs openwebui --since 1h
docker-compose logs db --tail=100

# Search for errors
docker-compose logs --since 1h | grep -i error
docker-compose logs --since 1h | grep -i "exception\|traceback"

# Stream logs in real-time
docker-compose logs -f webhook-receiver


```

---

## Service Issues

### OpenWebUI Not Accessible

**Symptoms:** `curl: (7) Failed to connect to localhost:8080`

**Diagnosis:**

```bash
# Is service running?
docker-compose ps openwebui

# Check health endpoint
curl -v http://localhost:8080/health

# Check logs
docker-compose logs openwebui --tail=20

# Check port binding
lsof -i :8080


```

**Solutions:**

1. **Service crashed:**

```bash
docker-compose restart openwebui
sleep 10
curl http://localhost:8080/health

```

2. **Port already in use:**

```bash
# Find process using port
lsof -i :8080
# Kill process or change port in docker-compose.override.yml

```

3. **Insufficient memory:**

```bash
# Check memory usage
docker stats openwebui

# Increase Docker memory:
# Docker Desktop > Settings > Resources > Memory: 8GB+

```

4. **Database connection issue:**

```bash
# Check database is running
docker-compose ps db

# Test database connection
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"

```

---

### Ollama Service Down

**Symptoms:** Ollama API returns 503 or times out

**Diagnosis:**

```bash
# Check service status
docker-compose ps ollama

# Test endpoint
curl -s http://ollama:11434/api/tags | jq .

# Check GPU
docker-compose exec ollama nvidia-smi

# Check logs
docker-compose logs ollama --tail=50


```

**Solutions:**

1. **Restart Ollama:**

```bash
docker-compose restart ollama
sleep 15
curl http://ollama:11434/api/tags | jq .

```

2. **GPU memory exhausted:**

```bash
# Check GPU memory
docker-compose exec ollama nvidia-smi

# Unload models
curl -X DELETE http://localhost:11434/api/tags/llama3.2:3b

# If persistent: Increase GPU memory or reduce model size

```

3. **Disk space full:**

```bash
# Check disk
df -h

# Clean up old models
docker-compose exec ollama rm -rf ~/.ollama/models/old-model

# Or use docker system prune
docker system prune -a --volumes

```

4. **Network connectivity issue:**

```bash
# Check Docker network
docker network ls
docker network inspect erni-ki_default

# Restart network
docker-compose down
docker-compose up -d

```

---

### Database Connection Failed

**Symptoms:** `postgresql://... connection refused` or
`FATAL: database "openwebui" does not exist`

**Diagnosis:**

```bash
# Is PostgreSQL running?
docker-compose ps db

# Check logs
docker-compose logs db --tail=20

# Try to connect
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"

# Check network
docker network inspect erni-ki_default


```

**Solutions:**

1. **Database not initialized:**

```bash
# Check if volume exists
docker volume ls | grep db_data

# If not, reinitialize
docker-compose down -v
docker-compose up -d db
sleep 30

# Verify database
docker-compose exec db psql -U openwebui_user -d openwebui -c "SELECT 1;"

```

2. **Wrong credentials:**

```bash
# Check credentials in .env
grep POSTGRES_PASSWORD .env
grep OPENWEBUI_DB_USER .env

# Test with explicit credentials
psql -h localhost -U openwebui_user -d openwebui \
 -c "SELECT 1;" \
 -W # Will prompt for password

```

3. **Database corrupted:**

```bash
# Backup current data
docker-compose exec db pg_dump -U openwebui_user openwebui > backup.sql

# Reset database
docker-compose down -v
docker-compose up -d db

# Restore from backup (if needed)
docker-compose exec db psql -U openwebui_user openwebui < backup.sql

```

4. **Connection pool exhausted:**

```bash
# Check active connections
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "SELECT COUNT(*) FROM pg_stat_activity;"

# Increase pool size in openwebui.env
echo "DATABASE_CONNECTION_POOL_SIZE=20" >> env/openwebui.env
docker-compose restart openwebui

```

---

## Webhook Issues

### Webhook Signature Verification Failing

**Symptoms:** `401 Unauthorized` on valid webhook requests

**Diagnosis:**

```bash
# Check webhook secret is set
echo $ALERTMANAGER_WEBHOOK_SECRET | wc -c # Should be 32+ chars

# Verify signature generation
python3 -c "
import hmac, hashlib, json
secret = '$ALERTMANAGER_WEBHOOK_SECRET'
body = b'{\"alerts\":[]}'
sig = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
print(f'Expected: {sig}')
"

# Test webhook endpoint
curl -X POST http://localhost:5001/webhook \
  -H "Content-Type: application/json" \
  -H "X-Signature: $(python3 -c '...')" \
  -d '{"alerts":[]}'


```

**Solutions:**

1. **Secret mismatch:**

```bash
# Verify secret in both places:
# 1. Environment variable
echo $ALERTMANAGER_WEBHOOK_SECRET

# 2. Alertmanager config
grep WEBHOOK_SECRET etc/alertmanager/alertmanager.yml

# 3. Secret file
cat secrets/alertmanager_webhook_secret.txt

# They must all match!

```

2. **JSON serialization issue:**

```bash
# Ensure compact JSON (no spaces)
echo '{"alerts":[]}' | python3 -m json.tool --compact

# When generating signature, use same format
body=$(python3 -c "import json; print(json.dumps(payload, separators=(',', ':')))")

```

3. **Signature algorithm mismatch:**

```bash
# Verify using SHA256, not SHA1
echo -n '{"alerts":[]}' | openssl dgst -sha256 -hmac "$ALERTMANAGER_WEBHOOK_SECRET" -hex

```

4. **Webhook receiver logs:**

```bash
docker-compose logs webhook-receiver | grep -i "signature\|authorized"

```

### Alerts Not Reaching Webhook

**Symptoms:** Alertmanager firing alerts but webhook not receiving them

**Diagnosis:**

```bash
# Check Alertmanager configured correctly
docker-compose exec alertmanager cat /etc/alertmanager/config.yml

# Check webhook receiver is running
docker-compose ps webhook-receiver

# Test connectivity from Alertmanager
docker-compose exec alertmanager curl -v http://webhook-receiver:5001/health

# Check Alertmanager logs
docker-compose logs alertmanager --tail=20 | grep webhook


```

**Solutions:**

1. **Alertmanager not configured for webhook:**

```bash
# Edit alertmanager.yml
cat etc/alertmanager/alertmanager.yml

# Ensure webhook_configs section exists:
# receivers:
#  - name: 'webhook-receiver'
#    webhook_configs:
#      - url: 'http://webhook-receiver:5001/webhook'

# Reload Alertmanager
docker-compose restart alertmanager

```

2. **Network connectivity between services:**

```bash
# Check Docker network
docker-compose exec alertmanager ping webhook-receiver

# Should respond: PING webhook-receiver (xxx.xxx.xxx.xxx)

```

3. **Webhook receiver service down:**

```bash
docker-compose ps webhook-receiver

# If not running:
docker-compose restart webhook-receiver

# If keeps crashing:
docker-compose logs webhook-receiver --tail=50

```

4. **Alert routing issue:**

```bash
# Check alert rules match receiver
docker-compose exec alertmanager curl localhost:9093/api/v2/alerts

# Verify alert has correct labels that match route

```

### Webhook Rate Limiting

**Symptoms:** `429 Too Many Requests` response

**Diagnosis:**

```bash
# Check current rate limit configuration
grep -r "per_minute\|rate_limit" conf/webhook-receiver/

# Check request frequency
docker-compose logs webhook-receiver | grep "Request\|rate"


```

**Solutions:**

1. **Increase rate limit:**

```bash
# Edit webhook-receiver configuration
# Current: 10 requests/minute per IP

# Option 1: Change in code (conf/webhook-receiver/webhook-receiver.py)
# @limiter.limit("20 per minute") # Increase to 20

# Option 2: Set via environment
echo "WEBHOOK_RATE_LIMIT=20" >> env/alertmanager.env
docker-compose restart webhook-receiver

```

2. **Batch alerts:**

```bash
# Instead of sending one alert at a time,
# Alertmanager batches multiple alerts in group_interval

# In alertmanager.yml:
# group_interval: 10s # Wait 10s to batch alerts

```

3. **Use different webhook endpoints:**

```bash
# Distribute load across endpoints
# - /webhook (generic, 10/min)
# - /webhook/critical (critical, 10/min)
# - /webhook/warning (warning, 10/min)

# This gives you 30 requests/minute total

```

---

## Performance Issues

### High Latency on API Calls

**Symptoms:** API responses taking >2 seconds

**Diagnosis:**

```bash
# Check response times
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8080/api/v1/chats

# Monitor in real-time
watch -n 1 'docker stats --no-stream | grep openwebui'

# Check database query performance
docker-compose exec db psql -U openwebui_user -d openwebui \
  -c "SHOW slow_query_log;"

# Check logs for slow requests
docker-compose logs openwebui | grep "duration"


```

**Solutions:**

1. **Database optimization:**

```bash
# Check for missing indexes
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "SELECT * FROM pg_stat_user_indexes ORDER BY idx_scan DESC;"

# Vacuum and analyze
docker-compose exec db vacuumdb -U openwebui_user -d openwebui
docker-compose exec db analyzedb -U openwebui_user -d openwebui

```

2. **Resource constraints:**

```bash
# Check CPU usage
docker stats --no-stream | grep openwebui

# If high: Increase allocated resources
# Edit docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       cpus: '2'
#       memory: 4G

```

3. **Network latency:**

```bash
# Test network latency to database
docker-compose exec openwebui ping db

# If high latency: Check Docker network
docker network inspect erni-ki_default

```

4. **Connection pooling:**

```bash
# Check connection pool usage
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';"

```

### High Memory Usage

**Symptoms:** Docker containers consuming >70% available RAM

**Diagnosis:**

```bash
# Check memory per container
docker stats --no-stream

# Check specific container memory
docker exec <container_id> ps aux --sort=-%mem | head -5

# Check for memory leaks
docker stats openwebui --no-stream
# Monitor over time to see if increasing


```

**Solutions:**

1. **Increase Docker memory limit:**

```bash
# Docker Desktop > Settings > Resources > Memory: 8GB+ (for development)
# For production: 16GB+ recommended

# Or use docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       memory: 4G

```

2. **Reduce cache size:**

```bash
# Check Redis memory
docker-compose exec redis redis-cli INFO memory

# Reduce max memory
docker-compose exec redis redis-cli CONFIG SET maxmemory 1gb

```

3. **Identify memory leaks:**

```bash
# Monitor memory over time
while true; do
 echo "$(date): $(docker stats --no-stream openwebui | tail -1)"
 sleep 60
done

# If consistently increasing: Check application logs for leaks
docker-compose logs openwebui | grep -i "memory\|leak"

```

### High CPU Usage

**Symptoms:** CPU usage >80% consistently

**Diagnosis:**

```bash
# Check CPU per container
docker stats --no-stream

# Check processes consuming CPU
docker exec <container_id> top -bn1 | head -15

# Check application logs
docker-compose logs openwebui | tail -50


```

**Solutions:**

1. **Increase CPU allocation:**

```bash
# Edit docker-compose.yml:
# deploy:
#   resources:
#     limits:
#       cpus: '2'

```

2. **Optimize queries:**

```bash
# Identify slow queries
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "SELECT query, mean_exec_time FROM pg_stat_statements \
 ORDER BY mean_exec_time DESC LIMIT 5;"

# Add indexes for frequently queried columns

```

3. **Reduce polling frequency:**

```bash
# Check if services are polling too frequently
grep -r "sleep\|interval" conf/
# Increase polling intervals

```

---

## GPU Issues

### GPU Not Detected

**Symptoms:** `CUDA_ERROR_NO_DEVICE` or `nvidia-smi: not found`

**Diagnosis:**

```bash
# Check GPU availability
docker-compose exec ollama nvidia-smi

# Check CUDA visibility
docker-compose exec ollama env | grep CUDA

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi


```

**Solutions:**

1. **Enable GPU in Docker:**

```bash
# Edit docker-compose.yml:
# services:
#   ollama:
#     deploy:
#       resources:
#         reservations:
#           devices:
#             - driver: nvidia
#               count: 1
#               capabilities: [gpu]

```

2. **Install NVIDIA drivers:**

```bash
# Check driver version
nvidia-smi

# If not installed:
# Ubuntu: sudo apt-get install nvidia-driver-525
# macOS: Not supported (use Metal)

```

3. **Update Docker for GPU:**

```bash
# Docker Desktop > Settings > Resources > Enable GPU acceleration
# Or install nvidia-docker

```

### GPU Memory Exhaustion

**Symptoms:** `CUDA_ERROR_OUT_OF_MEMORY` or `RuntimeError: CUDA out of memory`

**Diagnosis:**

```bash
# Check GPU memory usage
docker-compose exec ollama nvidia-smi

# Check allocated memory per process
docker-compose exec ollama nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv


```

**Solutions:**

1. **Reduce model size:**

```bash
# Use smaller quantized model
# Instead of: llama3.1:70b (40GB)
# Use: llama3.1:8b (4GB)

# Or use quantized version: llama3.2:3b (2GB)

```

2. **Clear GPU memory:**

```bash
# Unload all models
curl -X DELETE http://localhost:11434/api/tags/llama3.1:70b

# Restart Ollama
docker-compose restart ollama

```

3. **Increase GPU memory:**

```bash
# Not possible if GPU is at capacity
# Options:
# 1. Add more GPUs
# 2. Use CPU-only inference (much slower)
# 3. Use smaller models

```

---

## Security Issues

### Authentication Failures

**Symptoms:** `401 Unauthorized` or `403 Forbidden` on API calls

**Diagnosis:**

```bash
# Check if user exists
docker-compose exec db psql -U openwebui_user -d openwebui \
  -c "SELECT id, name, email FROM user LIMIT 5;"

# Check token validity
curl -v -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/chats

# Check logs for auth errors
docker-compose logs openwebui | grep -i "auth\|token\|401\|403"


```

**Solutions:**

1. **Invalid or expired token:**

```bash
# Get new token
curl -X POST http://localhost:8080/api/v1/auths/signin \
 -H "Content-Type: application/json" \
 -d '{"email":"admin@localhost","password":"CHANGEME"}' # pragma: allowlist secret

# Use token in header
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/v1/chats

```

2. **User doesn't exist:**

```bash
# Create admin user
docker-compose exec openwebui python -c "
from models import User
from sqlalchemy import create_engine

# Create user through UI or API
"

```

3. **Permission issue:**

```bash
# Check user role
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "SELECT id, name, role FROM user WHERE email='admin@localhost';"

```

### Exposed Secrets

**Symptoms:** Secrets appear in logs or responses

**Diagnosis:**

```bash
# Scan for secrets in logs
docker-compose logs | grep -i "password\|token\|secret\|key"

# Scan code for hardcoded secrets
grep -r "password\|api_key\|secret" . --include="*.py" --include="*.js"

# Use secret detection tool
detect-secrets scan


```

**Solutions:**

1. **Move secrets to environment:**

```bash
# Create .env file
cp env/example.env .env

# Add secrets (example placeholder)
echo "OPENWEBUI_ADMIN_PASSWORD=CHANGE_ME_PASSWORD" >> .env # pragma: allowlist secret

# Never commit .env to git
echo ".env" >> .gitignore

```

2. **Rotate exposed secrets:**

```bash
# Generate new password
openssl rand -base64 32

# Update in database
docker-compose exec db psql -U openwebui_user -d openwebui \
 -c "UPDATE user SET password_hash='...' WHERE id='admin';"

```

---

## Network Issues

### Cannot Reach Other Services

**Symptoms:** `Connection refused` or `Name resolution failed`

**Diagnosis:**

```bash
# Check service is running
docker-compose ps ollama

# Test connectivity
docker-compose exec webhook-receiver ping ollama

# Check DNS resolution
docker-compose exec webhook-receiver nslookup ollama

# Check network
docker network inspect erni-ki_default


```

**Solutions:**

1. **Service not running:**

```bash
docker-compose up -d ollama
sleep 10
docker-compose ps ollama

```

2. **Network isolation:**

```bash
# Ensure all services on same network
docker network ls
docker network inspect erni-ki_default

# Should see all services listed

```

3. **Port not exposed:**

```bash
# Check service port binding
docker-compose exec ollama netstat -tlnp | grep :11434

# If not listening, restart service
docker-compose restart ollama

```

---

## Recovery Procedures

### Full System Recovery

```bash
# 1. Stop everything
docker-compose down

# 2. Remove volumes (WARNING: DELETES DATA)
docker-compose down -v

# 3. Remove images
docker-compose rm

# 4. Rebuild from scratch
docker-compose build --no-cache

# 5. Start fresh
docker-compose up -d

# 6. Restore from backup
docker-compose exec db psql -U openwebui_user openwebui < backup.sql


```

### Emergency Rollback

```bash
# If current version broken:
docker-compose down
git checkout HEAD~1 # Go to previous commit
docker-compose build
docker-compose up -d

# Verify
curl http://localhost:8080/health


```

### Data Recovery

```bash
# List available backups
ls -la backups/

# Restore from backup
docker-compose exec db psql -U openwebui_user openwebui < backups/latest.sql

# Verify restore
docker-compose exec db psql -U openwebui_user -d openwebui \
  -c "SELECT COUNT(*) FROM chat;"


```

---

## Getting Help

### Collect Debug Information

```bash
# Create debug bundle
tar -czf debug-bundle.tar.gz \
  <(docker-compose logs --since 1h) \
  <(docker stats --no-stream) \
  <(docker-compose config) \
  <(docker network inspect erni-ki_default)

# Share for support


```

### Report Issues

1. **Check existing issues:** https://github.com/DIZ-admin/erni-ki/issues
2. **Search for similar issues**
3. **Create new issue with:**

- Clear title and description
- Steps to reproduce
- Error messages and logs
- System information (OS, Docker version)
- Debug bundle (if relevant)

### Contact Support

- **Slack:** #erni-ki-support
- **Email:** support@erni-gruppe.ch
- **Docs:** local documentation in repository (external portal temporarily
  unavailable)

---

See
[Troubleshooting Guide](../operations/troubleshooting/troubleshooting-guide.md)
for more help.

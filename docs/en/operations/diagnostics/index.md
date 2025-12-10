---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI SYSTEM DIAGNOSTICS

[TOC]

## Overview

This section contains comprehensive ERNI-KI system diagnostic methodology,
developed based on experience fixing critical testing errors that led to
underestimation of actual system performance.

## Documentation

### Main documents

1. **[erni-ki-diagnostic-methodology.md](./erni-ki-diagnostic-methodology.md)**

- Comprehensive diagnostic instructions
- Correct component testing methodology
- Avoiding typical diagnostic errors
- Diagnostic report structure
- System health evaluation criteria

### Tools

1. **`../scripts/erni-ki-health-check.sh`**

- Automated diagnostic script
- Full check of all system components
- Color output and detailed reporting
- Overall system health score calculation

## Quick start

### Run full diagnostics

```bash
# Navigate to ERNI-KI root directory
cd /path/to/erni-ki

# Run automated diagnostics
./scripts/erni-ki-health-check.sh
```

## Manual diagnostics of key components

{% raw %}

```bash
# 1. Check Docker containers
docker ps --filter "name=erni-ki" --format "table {{.Names}}\t{{.Status}}" | grep -c "healthy"

# 2. Test LiteLLM API
curl -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
 http://localhost:4000/v1/models

# 3. Test SearXNG
curl -s "http://localhost:8080/search?q=test&format=json" | jq -r '.results | length'

# 4. Test Redis
docker exec erni-ki-redis-1 redis-cli -a "$REDIS_PASSWORD" ping

# 5. Test external access
curl -I "https://ki.erni-gruppe.ch"
```

{% endraw %}

## Interpreting results

### System health rating scale

| Range   | Status          | Description                               |
| ------- | --------------- | ----------------------------------------- |
| 90-100% | [OK] EXCELLENT  | System working perfectly                  |
| 70-89%  | [WARNING] GOOD  | Minor issues, system functional           |
| 50-69%  | 🟠 SATISFACTORY | Significant issues, limited functionality |
| <50%    | CRITICAL        | System requires immediate intervention    |

### Key indicators

- **Healthy Containers**: Number of containers in "healthy" status
- **API Response Time**: Response time of critical API endpoints
- **External Access**: HTTPS domain accessibility
- **Integration Status**: Functionality of service integrations

## Typical problems and solutions

### Common diagnostic errors

1. **Testing without authentication**

- `curl http://localhost:4000/v1/models`
- `curl -H "Authorization: Bearer TOKEN" http://localhost:4000/v1/models`

2. **Incorrect endpoints**

- `curl http://localhost:8080/search?q=test`
- `curl http://localhost:8080/search?q=test&format=json`

3. **Ignoring Redis passwords**

- `docker exec redis redis-cli ping`
- `docker exec redis redis-cli -a "PASSWORD" ping`

### Quick fixes

```bash
# Restart problematic container
docker restart erni-ki-[service-name]

# Check logs
docker logs erni-ki-[service-name] --since=1h

# Check resource usage
docker stats --no-stream
```

## Monitoring and automation

### Regular diagnostics

```bash
# Add to crontab for daily check at 06:00
0 6 * * * /path/to/erni-ki/scripts/erni-ki-health-check.sh >> /var/log/erni-ki-health.log 2>&1
```

## Configure alerts

```bash
# Example script for sending notifications on issues
# !/bin/bash
HEALTH_SCORE=$(./scripts/erni-ki-health-check.sh | grep "System Health Score" | grep -o '[0-9]*')

if [[ $HEALTH_SCORE -lt 80 ]]; then
 echo "ERNI-KI Health Alert: System health is ${HEALTH_SCORE}%" | mail -s "ERNI-KI Alert" admin@example.com
fi
```

## Best practices

### Recommendations

1. **Regularity**: Conduct diagnostics at least once per day 2.
   **Documentation**: Keep log of changes and issues 3. **Automation**: Use
   scripts for repetitive checks 4. **Monitoring**: Set up alerts for critical
   metrics 5. **Training**: Study documentation of each component

### Diagnostic process

1. **Preparation**: Ensure system is stable 2. **Execution**: Run full
   diagnostics 3. **Analysis**: Review results and identify issues 4.
   **Actions**: Take measures to fix issues 5. **Verification**: Repeat
   diagnostics to confirm fixes

## Support

When diagnostic issues arise:

1. Check configuration files are up to date
2. Ensure testing commands are correct
3. Review logs of problematic components
4. Refer to specific service documentation

## Change history

- **v2.0** (2025-09-25): Comprehensive methodology revision based on experience
  fixing diagnostic errors
- **v1.0** (2025-09-01): Initial version of basic diagnostics

---

**Remember**: Correct diagnostics is the foundation of stable ERNI-KI operation.
Don't let incorrect testing underestimate actual system performance!

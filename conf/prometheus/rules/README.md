# Prometheus Alert Rules

Modular alert rules structure for ERNI-KI monitoring.

## Directory Structure

```
rules/
  10-infrastructure.yml  - Infrastructure monitoring (CPU, Memory, Disk, Containers)
  20-databases.yml       - Database alerts (PostgreSQL, Redis, Backups)
  30-ai-services.yml     - AI service alerts (Ollama, OpenWebUI, LiteLLM, RAG)
  40-logging.yml         - Logging stack alerts (Elasticsearch, Fluent Bit)
  50-gpu.yml             - GPU monitoring alerts (NVIDIA)
  60-sla.yml             - SLA and network alerts (Nginx, Cloudflare, Security)
```

## Naming Convention

Files are prefixed with numbers for load order:
- `10-*` - Infrastructure (loaded first)
- `20-*` - Databases
- `30-*` - AI Services
- `40-*` - Logging
- `50-*` - GPU
- `60-*` - SLA (loaded last)

## Alert Structure

Each rule file follows this structure:

```yaml
# Category Alert Rules
# Brief description

groups:
  - name: category.rules
    rules:
      - alert: AlertName
        expr: metric_expression > threshold
        for: duration
        labels:
          severity: critical|warning
          service: service-name
          category: category-name
          owner: team-name
          escalation: pagerduty|slack
        annotations:
          summary: "Brief alert summary"
          description: "Detailed description with {{ $value }} template."
          runbook: "docs/operations/monitoring-guide.md#section"
```

## Severity Levels

- **critical**: Immediate attention required, service down or data loss risk
- **warning**: Needs attention, but not immediately critical

## Validation

Validate rules before deployment:

```bash
docker run --rm --entrypoint promtool \
  -v $(pwd)/conf/prometheus/rules:/rules:ro \
  prom/prometheus:v3.0.1 \
  check rules /rules/*.yml
```

## Adding New Rules

1. Identify the appropriate category file
2. Add the rule following the standard structure
3. Validate with promtool
4. Test in staging before production

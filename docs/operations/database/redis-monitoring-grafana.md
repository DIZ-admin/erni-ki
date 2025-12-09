---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Redis Monitoring with Grafana in ERNI-KI

## Overview

The ERNI-KI system now includes comprehensive Redis monitoring via Grafana using
the Redis Data Source plugin. This solution replaces the problematic
Redis-exporter and provides stable monitoring for Redis 7.4.5 Alpine.

## Quick Start

### Grafana Access

- **URL**: <http://localhost:3000>
- **Login**: admin
- **Password**: admin123

### Access Redis Dashboard

1. Open Grafana in browser
2. Navigate to "Dashboards" section
3. Find dashboard "Redis Monitoring - ERNI-KI"

## Technical Configuration

### Redis Data Source

- **Name**: Redis-ERNI-KI
- **Type**: redis-datasource
- **URL**: redis://redis:6379
- **Authentication**: requirepass ($REDIS_PASSWORD)
- **Mode**: standalone

### Automatic Configuration

Configuration is applied automatically via Grafana provisioning:

- Data Source: `conf/grafana/provisioning/datasources/redis.yml`
- Dashboard: `conf/grafana/dashboards/infrastructure/redis-monitoring.json`

## Available Metrics

### Main Metrics

- **Memory Usage**: Redis memory usage
- **Connected Clients**: Number of connected clients
- **Commands Processed**: Processed commands
- **Network I/O**: Network traffic
- **Keyspace**: Database information

### Additional Metrics

- **Server Info**: Version, uptime, mode
- **Persistence**: Data persistence status
- **Replication**: Replication information (if configured)

## Extending Monitoring

### Adding New Panels

1. Open dashboard in edit mode
2. Add new panel
3. Select Redis-ERNI-KI as data source
4. Configure command and fields:

- **Command**: info
- **Section**: memory/stats/server/clients
- **Field**: specific field from Redis INFO

### Redis Command Examples

```bash
# Basic information
INFO server
INFO memory
INFO stats
INFO clients

# Specific metrics
DBSIZE
LASTSAVE
CONFIG GET maxmemory
```

## Performance Monitoring

### Key Indicators to Track

1. **used_memory** - memory usage
2. **connected_clients** - number of clients
3. **total_commands_processed** - total commands
4. **instantaneous_ops_per_sec** - operations per second
5. **keyspace_hits/misses** - cache effectiveness

### Alerts and Thresholds

- Memory usage > 80% of available
- Connected clients > 100
- Hit ratio < 90%
- Response time > 1ms

## Troubleshooting

### Connection Issues

```bash
# Check Redis status
docker-compose ps redis

# Check connection
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Check Grafana logs
docker-compose logs grafana --tail=20
```

## Plugin Reinstallation

```bash
# Reinstall Redis Data Source plugin
docker-compose exec grafana grafana-cli plugins uninstall redis-datasource
docker-compose exec grafana grafana-cli plugins install redis-datasource
docker-compose restart grafana
```

## Additional Resources

### Official Documentation

- [Redis Data Source Plugin](https://grafana.com/grafana/plugins/redis-datasource/)
- [Redis INFO Command](https://redis.io/commands/info/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

### Alternative Solutions

1. **Redis Insight** for detailed analysis
2. **Custom scripts** with metrics sent to InfluxDB
3. **Direct Redis commands** via CLI for diagnostics

**Note**: Redis-exporter was removed from ERNI-KI system due to compatibility
issues with Redis 7.4.5 Alpine. Grafana Redis Data Source Plugin is the
preferred solution.

## Updates and Maintenance

### Regular Tasks

- Monitor disk space for Grafana data
- Update dashboards when requirements change
- Backup Grafana configurations

### Automatic Updates

Grafana is configured for automatic updates via Watchtower with the
`monitoring-stack` label.

---

**Status**: Active **Last Updated**: 2025-09-19 **Version**: 1.0 **Date**:
2025-11-18

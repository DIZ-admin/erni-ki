---
language: en
title: 'Database Monitoring Plan'
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Monitoring Plan

## Introduction

This plan describes the database-level monitoring strategy, including key
metrics and alerting rules.

## Metrics

- Use **PostgreSQL Exporter** (port `9188`) to collect DBMS metrics.
- Track LVM metrics to monitor disk space.

## Alerts

- Configure critical alerts such as `PostgreSQLDown` and
  `PostgreSQLHighConnections`.
- See `conf/prometheus/alerts.yml` for the complete list of rules.

## References

- [`docs/operations/monitoring/monitoring-guide.md`](../monitoring/monitoring-guide.md)
  — general monitoring guide.

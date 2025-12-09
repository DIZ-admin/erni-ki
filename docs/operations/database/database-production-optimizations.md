---
language: en
title: 'Production Database Optimizations'
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Production Database Optimizations

## Introduction

This guide describes production PostgreSQL database optimization strategies to
ensure high performance and reliability.

## Configuration and Maintenance

- Configure **pg_stat_statements** to track slow queries.
- Regularly run **vacuum jobs** to clean up dead tuples (see
  [`docs/operations/automation/automated-maintenance-guide.md`](../automation/automated-maintenance-guide.md)).

## Performance Monitoring

- Track **bloat** (table/index bloat) to prevent performance degradation.
- Monitor **replication lag** if replication is used.

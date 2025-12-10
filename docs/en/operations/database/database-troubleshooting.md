---
language: en
title: 'Database Troubleshooting'
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Troubleshooting

## Introduction

This document provides steps for diagnosing and resolving common database
issues.

## Diagnostic Tools

- Use `docker compose exec db psql` for direct database access.
- Check current activity via the `pg_stat_activity` view.

## Known Issues

- Compare current symptoms with the report
  `../../archive/reports/log-analysis-correction-2025-11-04.md` to identify
  recurring issues.

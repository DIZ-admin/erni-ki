---
language: ru
title: 'Database Monitoring Plan'
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Database Monitoring Plan

## Введение

Этот план описывает стратегию мониторинга уровня базы данных, включая ключевые
метрики и правила оповещения.

## Метрики

- Используйте **PostgreSQL Exporter** (порт `9188`) для сбора метрик СУБД.
- Отслеживайте метрики LVM для контроля дискового пространства.

## Оповещения

- Настройте критические алерты, такие как `PostgreSQLDown` и
  `PostgreSQLHighConnections`.
- Полный список правил см. в `conf/prometheus/alerts.yml`.

## Ссылки

- [`docs/operations/monitoring/monitoring-guide.md`](../monitoring/monitoring-guide.md)
  — общее руководство по мониторингу.

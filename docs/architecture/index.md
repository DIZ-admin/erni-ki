---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Архитектурная документация

Этот каталог содержит исчерпывающую техническую документацию по архитектуре
системы ERNI-KI.

## Содержание

- **[architecture.md](architecture.md)** - Полный обзор архитектуры системы
  (v0.61.3)
  - Компоненты системы и их взаимодействие
  - Сетевая архитектура и маппинг портов
  - Инвентаризация сервисов и зависимости
  - Диаграммы Mermaid для визуализации

- **[services-overview.md](services-overview.md)** - Детальный каталог сервисов
  - AI/ML сервисы (Ollama, LiteLLM, Context7)
  - Сервисы данных (PostgreSQL, Redis)
  - Инфраструктурные сервисы (Nginx, Cloudflare)
  - Стек мониторинга (Prometheus, Grafana, Loki)

- **[service-inventory.md](service-inventory.md)** - Машиночитаемый каталог
  сервисов

- **[nginx-configuration.md](nginx-configuration.md)** - Настройка Nginx reverse
  proxy
  - Конфигурация SSL/TLS
  - Ограничение скорости (Rate limiting)
  - Проксирование WebSocket
  - Заголовки безопасности

## Быстрые ссылки

- [Обзор системы](../overview.md)
- [Руководство по эксплуатации](../operations/index.md)
- [Руководство по установке](../getting-started/installation.md)

## Версия

Текущая версия архитектуры: **12.1** (Wave 3) Последнее обновление:
**2025-11-22**

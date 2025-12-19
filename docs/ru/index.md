---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-19'
---

# ERNI Academy KI

Добро пожаловать в единый портал обучения и поддержки ERNI KI. Здесь собраны
инструкции по работе с Open WebUI, примеры промптов и новости продукта на
русском языке как на основном языке портала.

- Для быстрого старта переходите в раздел [Academy KI](academy/index.md).
- Следите за обновлениями в [ленте новостей](academy/news/index.md).
- Если что-то не работает, сначала нажмите
  **[Проверить статус системы](operations/core/status-page.md)**.

## Актуальное состояние платформы

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-12-15) — Production Ready v0.61.3**
>
> - Контейнеры: 34/34 services healthy
> - Графана: 5/5 Grafana dashboards (provisioned)
> - Алерты: 20 Prometheus alert rules active
> - AI/GPU: Ollama 0.13.0 + OpenWebUI v0.6.40 (GPU)
> - Context & RAG: LiteLLM v1.80.0-stable.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.7.3, Grafana v12.3.0, Loki v3.6.2, Fluent Bit
>   v4.2.0, Alertmanager v0.29.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: синхронизировано с compose.yml: searxng 2025.11.21, cloudflared
>   2025.11.1, Tika 3.2.3.0-full, экспортеры усилены

<!-- STATUS_SNIPPET_END -->

## Как устроен портал

1.**Русский — канонический язык.**Все материалы сначала публикуются здесь и
становятся источником для переводов. 2.**Переключатель языка**позволяет
переходить на немецкий и английский варианты страниц, когда они
готовы. 3.**Структура едина**: Academy KI → Основы, Промптинг, HowTo, Новости, а
также раздел «Система» с доступом к статусу сервисов.

---
page_id: site.home
translation_status: complete
doc_version: '2025.02'
---

# ERNI Academy KI

Добро пожаловать в единый портал обучения и поддержки ERNI KI. Здесь собраны
инструкции по работе с Open WebUI, примеры промптов и новости продукта на
русском языке как на основном языке портала.

- Для быстрого старта переходите в раздел [Academy KI](academy/index.md).
- Следите за обновлениями в [ленте новостей](academy/news/index.md).
- Если что-то не работает, сначала нажмите
  **[Проверить статус системы](system/status.md)**.

## Актуальное состояние платформы

<!-- STATUS_SNIPPET_START -->

> **Статус системы (2025-11-14) — Production Ready v12.1**
>
> - Контейнеры: 30/30 контейнеров healthy
> - Графана: 18/18 Grafana дашбордов
> - Алерты: 27 Prometheus alert rules активны
> - AI/GPU: Ollama 0.12.11 + OpenWebUI v0.6.36 (GPU)
> - Context & RAG: LiteLLM v1.80.0.rc.1 + Context7, Docling, Tika, EdgeTTS
> - Мониторинг: Prometheus v3.0.1, Grafana v11.6.6, Loki v3.5.5, Fluent Bit
>   v3.2.0, Alertmanager v0.28.0
> - Автоматизация: Cron: PostgreSQL VACUUM 03:00, Docker cleanup 04:00, Backrest
>   01:30, Watchtower selective updates
> - Примечание: Наблюдаемость и AI стек актуализированы в ноябре 2025

<!-- STATUS_SNIPPET_END -->

## Как устроен портал

1. **Русский — канонический язык.** Все материалы сначала публикуются здесь и
   становятся источником для переводов.
2. **Переключатель языка** позволяет переходить на немецкий и английский
   варианты страниц, когда они готовы.
3. **Структура едина**: Academy KI → Основы, Промптинг, HowTo, Новости, а также
   раздел «Система» с доступом к статусу сервисов.

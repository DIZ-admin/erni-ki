---
language: ru
translation_status: complete
doc_version: '2025.11'
---

# Troubleshooting ERNI-KI

- Начните с `docker compose ps`, `docker compose logs` и `docker compose top`.
- Используйте `docs/operations/core/operations-handbook.md` и
  `docs/operations/troubleshooting/troubleshooting-guide.md` для типовых
  сценариев.
- Проверяйте healthchecks (`curl -s http://localhost:PORT/metrics`).

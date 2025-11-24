---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Backup Guide

Краткий путеводитель по резервному копированию ERNI-KI и ссылкам на детальные
процедуры.

## Что покрываем

- PostgreSQL (данные OpenWebUI)
- Конфигурации: `env/`, `conf/`, `compose.yml`
- Пользовательские артефакты (uploads, модели Ollama)
- Критичные логи (последние 7 дней)
- Сертификаты TLS

## Быстрый чеклист

1. **Автобэкапы Backrest**
   - Статус: `docker compose ps backrest`
   - Логи: `docker compose logs backrest --tail=50`
   - История: `curl -s http://localhost:9898/api/v1/repos`

2. **Бэкап перед изменениями**
   - Снимите snapshot (Backrest full/incremental)
   - Экспортируйте конфиг:
     `tar -czf config-$(date +%F).tgz env conf compose.yml`

3. **Валидация восстановления (раз в месяц)**
   - Разверните на тестовом стенде
   - Проверьте запуск OpenWebUI + БД
   - Убедитесь, что uploads и модели доступны

## Когда что использовать

- **Рутинные бэкапы и vacuum/maintenance:**  
  см. `operations/automation/automated-maintenance-guide.md`

- **Полные пошаговые процедуры бэкапа/рестора:**  
  см. `operations/maintenance/backup-restore-procedures.md`

- **Рестарт сервисов после восстановления:**  
  см. `operations/maintenance/service-restart-procedures.md`

## RPO/RTO

- **RPO:** ≤ 15 минут (инкрементальные бэкапы + WAL streaming)
- **RTO:** ≤ 45 минут для OpenWebUI + БД
- Проверяйте показатели ежемесячно и фиксируйте результат в Backrest dashboard.

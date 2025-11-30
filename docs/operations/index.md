---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-28'
---

# Документация по эксплуатации

Этот каталог содержит операционные руководства, ранбуки и процедуры для
управления платформой ERNI-KI.

## Содержание

### Основные руководства

-**[admin-guide.md](core/admin-guide.md)**- Справочник системного администратора

- Управление пользователями
- Конфигурация сервисов
- Процедуры резервного копирования и восстановления
- Управление безопасностью

-**[monitoring-guide.md](monitoring/monitoring-guide.md)**- Полная документация
по мониторингу

- Метрики Prometheus и алерты
- Дашборды Grafana (5 настроенных)
- Агрегация логов Loki
- Отслеживание SLO (Service Level Objective)

### Устранение неполадок и Ранбуки

-**[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md)**-
Процедуры диагностики и частые проблемы -**Обслуживание:**
[Перезапуск сервисов](maintenance/service-restart-procedures.md),
[Резервное копирование и восстановление](maintenance/backup-restore-procedures.md)

### Специализированные руководства

-**Автоматизация:**
[Автоматизированное обслуживание](automation/automated-maintenance-guide.md) -**Базы
данных:**[Обзор операций](database/index.md) -**Мониторинг:**[Руководство по мониторингу](monitoring/monitoring-guide.md)

### Диагностика

-**[diagnostics/index.md](diagnostics/index.md)**- Диагностические отчеты и
методологии

## Быстрый старт

**Для операторов:**Начните с [admin-guide.md](core/admin-guide.md).**Для
мониторинга:**См. [monitoring-guide.md](monitoring/monitoring-guide.md).**Для
инцидентов:**Проверьте
[troubleshooting-guide.md](troubleshooting/troubleshooting-guide.md).

## Операционный ритм

-**Ежедневно:**проверка статус-страницы, `CronJobFailed`, контроль
бэкапов. -**Еженедельно:**аудит изменений по `configuration-change-process.md` и
обновление журнала maintenance. -**Ежемесячно:**тренировочные восстановления по
`maintenance/backup-restore-procedures.md`.

## Связанная документация

- [Обзор архитектуры](../architecture/index.md)
- [Начало работы](../getting-started/index.md)
- [Безопасность](../security/index.md)

## Версия

Версия документации:**12.1**Последнее обновление:**2025-11-24**

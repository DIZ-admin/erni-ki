# Operations & Runbooks

## Рутины

- **Очистка Docling shared volume:**
  `scripts/maintenance/docling-shared-cleanup.sh --apply` (cron рекомендация в
  `docs/operations/runbooks/docling-shared-volume.md`).
- **Vacuum/backup:** расписание cron описано в README (Backrest 01:30, VACUUM
  03:00, docker cleanup 04:00).
- **Download Docling models:**
  `./scripts/maintenance/download-docling-models.sh`.

## Бэкапы

- Backrest (`backrest` сервис) хранит конфиги и данные PostgreSQL.
- Проверяйте права на каталоги бэкапов и доступ к Docker socket.
- План восстановления/верификации: см.
  `docs/operations/runbooks/backup-restore.md` (и план автоматизации Backrest в
  задачах Archon).

## Обновления и релизы

- Лейблы watchtower управляют автообновлением; критичные сервисы обновлять
  вручную по чеклисту `docs/operations/maintenance/image-upgrade-checklist.md`.
- Перед релизом — чеклист [[Checklists]].

## Инциденты

- История инцидентов/аудитов: `docs/archive/incidents/`, `docs/archive/audits/`.
- Страница статуса: `docs/operations/core/status-page.md` (+ локализации).

## Полезные документы

- Runbooks: `docs/operations/runbooks/`.
- HowTo: `docs/howto/` и `docs/en/academy/howto/`.
- Академия/обучение: `docs/academy/README.md`, `docs/index.md` (+ en/de).

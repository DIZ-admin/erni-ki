# 🚀 Быстрое руководство по настройке Backrest для ERNI-KI

## 📋 Предварительные требования

- Backrest запущен и доступен по адресу http://localhost:9898
- Учетные данные из файла `.backrest_secrets`

## 🔑 Учетные данные для входа

```bash
# Получить учетные данные
cat .backrest_secrets
```

- **Пользователь**: admin
- **Пароль**: (из файла .backrest_secrets, строка BACKREST_PASSWORD)
- **Ключ шифрования**: (из файла .backrest_secrets, строка RESTIC_PASSWORD)

## 🏗️ Шаг 1: Создание репозитория

1. Откройте http://localhost:9898
2. Войдите с учетными данными выше
3. Нажмите **"Add Repository"**
4. Заполните форму:

```
Repository ID: erni-ki-local
Repository URI: /backup-sources/.config-backup
Password: [RESTIC_PASSWORD из .backrest_secrets]
```

5. **Prune Policy**:
```
Schedule: 0 3 * * *
Max Unused Bytes: 1GB
```

6. **Check Policy**:
```
Schedule: 0 4 * * 0
```

7. Нажмите **"Create Repository"**

## 📦 Шаг 2: Создание плана бэкапа

1. Нажмите **"Add Plan"**
2. Заполните основные настройки:

```
Plan ID: erni-ki-critical-data
Repository: erni-ki-local
```

3. **Paths** (добавьте каждый путь отдельно):
```
/backup-sources/env
/backup-sources/conf
/backup-sources/data/postgres
/backup-sources/data/openwebui
/backup-sources/data/ollama
```

4. **Excludes** (добавьте каждое исключение отдельно):
```
*.log
*.tmp
**/cache/**
**/temp/**
**/.git/**
**/node_modules/**
```

5. **Schedule**:
```
0 2 * * *
```

6. **Retention Policy** (выберите "Time-based"):
```
Keep Daily: 7
Keep Weekly: 4
Keep Monthly: 0
Keep Yearly: 0
```

7. Нажмите **"Create Plan"**

## 🧪 Шаг 3: Создание тестового бэкапа

1. Перейдите на страницу **"Plans"**
2. Найдите план `erni-ki-critical-data`
3. Нажмите кнопку **"Backup Now"**
4. Дождитесь завершения операции

## ✅ Шаг 4: Проверка результата

```bash
# Проверка созданного бэкапа
./scripts/check-local-backup.sh

# Полная проверка с restic
./scripts/check-local-backup.sh --full

# Просмотр содержимого директории
ls -la .config-backup/
```

## 🔍 Ожидаемый результат

После успешного создания бэкапа:

1. **Директория `.config-backup/`** содержит файлы репозитория restic
2. **Размер бэкапа** зависит от объема данных (обычно несколько GB)
3. **Веб-интерфейс Backrest** показывает успешные снапшоты
4. **Скрипт проверки** не выдает ошибок

## 🚨 Устранение проблем

### Проблема: "Repository not found"
```bash
# Проверьте монтирование директории в контейнере
docker-compose exec backrest ls -la /backup-sources/
```

### Проблема: "Permission denied"
```bash
# Проверьте права доступа
ls -la .config-backup/
sudo chown -R $USER:$USER .config-backup/
```

### Проблема: Backrest недоступен
```bash
# Проверьте статус контейнера
docker-compose ps backrest
docker-compose logs backrest
```

## 📚 Дополнительные ресурсы

- **Статус системы**: `./scripts/backrest-management.sh status`
- **Руководство по восстановлению**: `docs/local-backup-restore-guide.md`
- **Официальная документация**: https://garethgeorge.github.io/backrest/

## 🎯 Следующие шаги

После настройки локального бэкапа рекомендуется:

1. **Настроить внешнее хранилище** (S3, B2) для дополнительной защиты
2. **Настроить уведомления** о статусе бэкапов
3. **Протестировать восстановление** данных
4. **Добавить мониторинг** бэкапов в систему алертов

---

**Важно**: Сохраните файл `.backrest_secrets` в безопасном месте!

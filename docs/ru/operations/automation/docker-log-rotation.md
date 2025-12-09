---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Docker Log Rotation для ERNI-KI

[TOC]

## Описание

Настройка автоматической ротации логов Docker контейнеров для предотвращения
неконтролируемого роста дискового пространства.

## Рекомендуемая конфигурация

### Глобальная настройка (daemon.json)

Создать или обновить `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

После изменения перезапустить Docker:

```bash
sudo systemctl restart docker
```

**Эффект:**Каждый контейнер будет хранить максимум 3 файла по 10 MB (30 MB на
контейнер).

---

### Настройка для отдельных сервисов (compose.yml)

Добавить в каждый сервис в `compose.yml`:

```yaml
services:
  openwebui:
  # ... остальная конфигурация
  logging:
  driver: 'json-file'
  options:
  max-size: '10m'
  max-file: '3'
```

## Рекомендации по размерам для разных сервисов

**Высоконагруженные сервисы (больше логов):**

- `openwebui`, `ollama`, `nginx`, `litellm`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '20m'
  max-file: '5'
```

**Стандартные сервисы:**

- `postgres`, `redis`, `prometheus`, `grafana`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '10m'
  max-file: '3'
```

**Низконагруженные сервисы:**

- `backrest`, `webhook`, `watchtower`

```yaml
logging:
  driver: 'json-file'
  options:
  max-size: '5m'
  max-file: '2'
```

---

## Применение изменений

### Вариант 1: Глобальная настройка (рекомендуется)

```bash
# 1. Создать backup текущей конфигурации
sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup-$(date +%Y%m%d) 2>/dev/null || true

# 2. Создать новую конфигурацию
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
 "log-driver": "json-file",
 "log-opts": {
 "max-size": "10m",
 "max-file": "3"
 }
}
EOF

# 3. Перезапустить Docker
sudo systemctl restart docker

# 4. Проверить статус
sudo systemctl status docker

# 5. Пересоздать контейнеры для применения новых настроек
cd /home/konstantin/Documents/augment-projects/erni-ki
docker compose up -d --force-recreate
```

## Вариант 2: Настройка в compose.yml

```bash
# 1. Создать backup
cp compose.yml .config-backup/compose.yml.backup-$(date +%Y%m%d-%H%M%S)

# 2. Добавить logging в каждый сервис (вручную или через sed)
# Пример для одного сервиса:
# services:
# openwebui:
# logging:
# driver: "json-file"
# options:
# max-size: "10m"
# max-file: "3"

# 3. Применить изменения
docker compose up -d --force-recreate
```

---

## Проверка текущих настроек

```bash
# Проверить настройки конкретного контейнера
docker inspect erni-ki-openwebui-1 | grep -A 10 "LogConfig"

# Проверить размер логов всех контейнеров
docker ps -q | xargs -I {} sh -c 'echo "Container: {}"; docker inspect {} | grep -A 5 "LogPath" | grep LogPath | cut -d\" -f4 | xargs ls -lh 2>/dev/null'

# Общий размер логов Docker
sudo du -sh /var/lib/docker/containers/*/
```

---

## Очистка существующих логов

```bash
# ВНИМАНИЕ: Удалит все текущие логи контейнеров!

# Остановить все контейнеры
docker compose down

# Очистить логи
sudo truncate -s 0 /var/lib/docker/containers/*/*-json.log

# Запустить контейнеры
docker compose up -d
```

---

## Мониторинг

Добавить в `scripts/monitor-disk-space.sh`:

```bash
# Размер логов Docker
DOCKER_LOGS_SIZE=$(sudo du -sh /var/lib/docker/containers/ 2>/dev/null | awk '{print $1}')
echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker logs: $DOCKER_LOGS_SIZE" >> "$LOG_FILE"
```

---

## Расчёт экономии

**Без ротации:**

- 49 контейнеров × ~100 MB логов = ~5 GB

**С ротацией (10m × 3):**

- 49 контейнеров × 30 MB = ~1.5 GB -**Экономия: ~3.5 GB**

---

## Рекомендации

1.**Использовать глобальную настройку**через `/etc/docker/daemon.json` - проще и
единообразно 2.**Настроить мониторинг**размера логов через
`monitor-disk-space.sh` 3.**Периодически проверять**размер логов:
`sudo du -sh /var/lib/docker/containers/` 4.**Не устанавливать слишком маленькие
значения**- можно потерять важные логи при диагностике 5.**Пересоздать
контейнеры**после изменения настроек для применения

---

## Альтернативные драйверы логирования

### Syslog (для централизованного логирования)

{% raw %}

```yaml
logging:
  driver: 'syslog'
  options:
  syslog-address: 'tcp://localhost:514'
  tag: '{{.Name}}'
```

### Local (более эффективный, чем json-file)

```yaml
logging:
  driver: 'local'
  options:
  max-size: '10m'
  max-file: '3'
```

{% endraw %}

---

**Статус:**Документация создана**Применение:**Требует ручного выполнения
команд**Приоритет:**Средний (рекомендуется применить в течение недели)

# 🛠️ Скрипты автоматизации ERNI-KI

Коллекция скриптов для упрощения развертывания, управления и мониторинга AI
платформы ERNI-KI.

---

## 🚀 Быстрый старт

### Для новых пользователей

```bash
# Быстрый запуск за 5 минут (рекомендуется)
./scripts/quick_start.sh

# Или полная настройка с интерактивными опциями
./scripts/setup.sh
```

### Для опытных пользователей

```bash
# Ручная настройка по документации
# См. DEPLOYMENT_GUIDE.md
```

---

## 📋 Описание скриптов

### 🔧 Настройка и развертывание

#### `setup.sh` - Полная интерактивная настройка

**Назначение:** Комплексная настройка системы с пользовательским вводом **Время
выполнения:** 5-10 минут **Возможности:**

- Проверка всех зависимостей
- Копирование и настройка конфигураций
- Генерация секретных ключей
- Настройка домена и Cloudflare
- Создание вспомогательных скриптов

```bash
./scripts/setup.sh
```

#### `quick_start.sh` - Быстрый запуск

**Назначение:** Автоматический запуск с настройками по умолчанию **Время
выполнения:** 3-5 минут **Возможности:**

- Быстрая настройка для localhost
- Автоматическая генерация ключей
- Запуск всех сервисов
- Загрузка базовой модели
- Проверка работоспособности

```bash
./scripts/quick_start.sh
```

---

### 📊 Мониторинг и диагностика

#### `health_check.sh` - Проверка состояния системы

**Назначение:** Комплексная диагностика всех компонентов **Время выполнения:**
30-60 секунд **Проверки:**

- Состояние всех сервисов
- HTTP endpoints
- База данных и Redis
- Модели Ollama
- Использование ресурсов
- Анализ логов на ошибки

```bash
# Обычная проверка
./scripts/health_check.sh

# С генерацией подробного отчета
./scripts/health_check.sh --report
```

**Пример вывода:**

```
✅ auth: работает
✅ openwebui: работает
✅ PostgreSQL: подключение успешно
✅ Redis: подключение успешно
✅ Ollama: 1 моделей загружено
```

---

### 🎮 Управление сервисами

#### `start.sh` - Запуск всех сервисов

```bash
./scripts/start.sh
```

#### `stop.sh` - Остановка всех сервисов

```bash
./scripts/stop.sh
```

#### `restart.sh` - Перезапуск системы

```bash
./scripts/restart.sh
```

#### `status.sh` - Быстрый статус

```bash
./scripts/status.sh
```

#### `logs.sh` - Просмотр логов в реальном времени

```bash
./scripts/logs.sh
```

---

### 💾 Резервное копирование

#### `backup.sh` - Создание бэкапа

**Включает:**

- Дамп базы данных PostgreSQL
- Архив конфигурационных файлов
- Переменные окружения

```bash
./scripts/backup.sh
```

**Структура бэкапа:**

```
backups/YYYYMMDD_HHMMSS/
├── database.sql          # Дамп БД
└── configs.tar.gz        # Конфигурации
```

---

## 🔄 Типичные сценарии использования

### Первое развертывание

```bash
# 1. Клонирование репозитория
git clone https://github.com/DIZ-admin/erni-ki.git
cd erni-ki

# 2. Быстрый запуск
./scripts/quick_start.sh

# 3. Проверка состояния
./scripts/health_check.sh
```

### Ежедневное обслуживание

```bash
# Проверка состояния
./scripts/status.sh

# Просмотр логов
./scripts/logs.sh

# Создание бэкапа
./scripts/backup.sh
```

### Устранение неполадок

```bash
# Полная диагностика
./scripts/health_check.sh --report

# Перезапуск проблемного сервиса
docker compose restart [service_name]

# Просмотр логов конкретного сервиса
docker compose logs -f [service_name]
```

### Обновление системы

```bash
# Остановка сервисов
./scripts/stop.sh

# Создание бэкапа
./scripts/backup.sh

# Обновление кода
git pull

# Пересборка и запуск
npm run docker:build
./scripts/start.sh

# Проверка
./scripts/health_check.sh
```

---

## ⚙️ Настройка скриптов

### Переменные окружения

Скрипты поддерживают следующие переменные:

```bash
# Таймауты
export HEALTH_CHECK_TIMEOUT=30
export SERVICE_START_TIMEOUT=60

# Пути
export BACKUP_DIR="./backups"
export LOG_DIR="./logs"

# Опции
export SKIP_MODEL_DOWNLOAD=false
export VERBOSE_OUTPUT=true
```

### Кастомизация

Для изменения поведения скриптов отредактируйте соответствующие файлы:

```bash
# Добавление новых проверок в health_check.sh
vim scripts/health_check.sh

# Изменение последовательности запуска в start.sh
vim scripts/start.sh
```

---

## 🐛 Troubleshooting

### Скрипт не запускается

```bash
# Проверка прав выполнения
ls -la scripts/
chmod +x scripts/*.sh

# Проверка зависимостей
which docker docker-compose openssl
```

### Ошибки в health_check.sh

```bash
# Проверка доступности Docker
docker ps

# Проверка конфигурации
docker compose config
```

### Проблемы с генерацией ключей

```bash
# Проверка OpenSSL
openssl version

# Ручная генерация
openssl rand -hex 32
```

---

## 📈 Мониторинг производительности

### Автоматический мониторинг

```bash
# Запуск мониторинга в фоне
nohup ./scripts/performance_monitor.sh > performance.log 2>&1 &

# Просмотр метрик
tail -f performance.log
```

### Интеграция с системами мониторинга

```bash
# Экспорт метрик для Prometheus
./scripts/health_check.sh --format=prometheus > metrics.txt

# Отправка алертов
./scripts/health_check.sh --alert-webhook="https://hooks.slack.com/..."
```

---

## 🔒 Безопасность

### Защита секретных данных

- Файл `.secrets_backup` содержит критичные данные
- Никогда не коммитьте файлы `*.env`
- Регулярно меняйте секретные ключи

### Аудит безопасности

```bash
# Проверка прав доступа
find . -name "*.env" -exec ls -la {} \;

# Поиск незащищенных ключей
grep -r "CHANGE_BEFORE_GOING_LIVE" .
```

---

## 📚 Дополнительные ресурсы

- **Основная документация:** [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)
- **Архитектура системы:**
  [docs/service-architecture-diagram.md](../docs/service-architecture-diagram.md)
- **Устранение неполадок:**
  [docs/FIXES-AND-IMPROVEMENTS.md](../docs/FIXES-AND-IMPROVEMENTS.md)

---

## 🤝 Поддержка

При возникновении проблем:

1. Проверьте логи: `./scripts/logs.sh`
2. Запустите диагностику: `./scripts/health_check.sh --report`
3. Создайте issue: https://github.com/DIZ-admin/erni-ki/issues

**Время отклика:** Обычно в течение 24 часов **Поддерживаемые ОС:** Ubuntu
20.04+, Debian 11+, CentOS 8+

---

## ✨ Новые скрипты (2025-08-12)

### 📊 `monitor-rate-limiting.sh` - Мониторинг nginx rate limiting

**Назначение:** Автоматический мониторинг производительности nginx и rate
limiting **Время выполнения:** 10-15 секунд **Возможности:**

- Статистика запросов по endpoints за последние 5 минут
- Процент rate limiting с алертами при превышении 80%
- Топ 10 IP адресов по количеству запросов
- Размеры логов nginx и статус сервиса
- Цветная индикация проблем (красный/желтый/зеленый)

**Использование:**

```bash
# Запуск мониторинга
./scripts/monitor-rate-limiting.sh

# Пример вывода:
# 📊 Статистика запросов к /api/health за последние 5m:
#   Всего запросов: 150
#   Rate limited (429): 0
#   Серверные ошибки (5xx): 0
#   ✅ Rate limiting: 0%
```

**Алерты:**

- 🔴 Rate limiting ≥80% - критический алерт
- 🟡 Rate limiting ≥50% - предупреждение
- 🟢 Rate limiting <50% - норма

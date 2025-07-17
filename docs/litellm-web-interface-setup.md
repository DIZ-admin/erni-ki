# LiteLLM Web Interface Setup Guide

## 📋 Обзор

Данное руководство описывает настройку веб-интерфейса LiteLLM для администрирования Context Engineering Gateway в системе ERNI-KI.

## ✅ Статус конфигурации

**Дата:** 15 июля 2025  
**Статус:** ✅ Настроено и работает  
**Версия:** LiteLLM v1.74.0  

### Доступные интерфейсы

| Интерфейс | URL | Статус | Описание |
|-----------|-----|--------|----------|
| LiteLLM Admin UI | http://localhost:4000/ui/ | ✅ Работает | Веб-интерфейс администрирования |
| LiteLLM API | http://localhost:4000/v1/ | ✅ Работает | REST API для моделей |
| Health Check | http://localhost:4000/health/liveliness | ✅ Работает | Проверка состояния |
| Readiness Check | http://localhost:4000/health/readiness | ✅ Работает | Готовность к работе |

## 🔧 Конфигурация

### 1. Настройки в env/litellm.env

```env
# === UI SETTINGS ===
# Включить веб-интерфейс администрирования
DISABLE_ADMIN_UI=False

# UI аутентификация (опционально)
UI_USERNAME=admin
UI_PASSWORD=erni-ki-admin-2025

# === DATABASE INTEGRATION ===
# PostgreSQL подключение для metadata storage
DATABASE_URL=postgresql://litellm_user:LL_secure_pass_2025!@db:5432/openwebui

# Prisma миграции
USE_PRISMA_MIGRATE=True

# Включить хранение моделей в БД
STORE_MODEL_IN_DB=True
```

### 2. Настройки в conf/litellm/config-simple.yaml

```yaml
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: "postgresql://litellm_user:LL_secure_pass_2025!@db:5432/openwebui"

  # UI Configuration
  ui_access_mode: "all"  # Разрешить доступ всем пользователям
  store_prompts_in_spend_logs: True  # Включить логирование для UI
  
  # Отключить блокировку роботов для UI
  block_robots: False

  # Оптимизация производительности
  database_connection_pool_limit: 10
  database_connection_timeout: 60
  proxy_batch_write_at: 60

  # Безопасность и мониторинг
  disable_spend_logs: False
  disable_error_logs: False
```

## 🚀 Доступ к веб-интерфейсу

### Локальный доступ

1. **Прямой доступ:**
   ```bash
   http://localhost:4000/ui/
   ```

2. **Через nginx (если настроен):**
   ```bash
   http://localhost:8080/api/litellm/ui/
   ```

### Аутентификация

- **Master Key:** `sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb`
- **UI Username:** `admin`
- **UI Password:** `erni-ki-admin-2025`

## 🔍 Функциональность веб-интерфейса

### Основные возможности

1. **Управление моделями:**
   - Просмотр доступных моделей
   - Настройка параметров моделей
   - Мониторинг использования

2. **Управление ключами:**
   - Создание virtual keys
   - Управление правами доступа
   - Мониторинг использования ключей

3. **Мониторинг:**
   - Просмотр логов запросов
   - Статистика использования
   - Производительность системы

4. **Администрирование:**
   - Настройка пользователей
   - Управление командами
   - Конфигурация системы

## 🧪 Тестирование

### API тестирование

```bash
# Проверка доступности API
curl -s http://localhost:4000/health/liveliness

# Получение списка моделей
curl -s -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
  http://localhost:4000/v1/models | jq .

# Проверка готовности системы
curl -s http://localhost:4000/health/readiness | jq .
```

### Веб-интерфейс тестирование

```bash
# Проверка доступности UI
curl -I http://localhost:4000/ui/

# Проверка загрузки страницы
curl -s http://localhost:4000/ui/ | grep "LiteLLM Dashboard"
```

## 🔒 Безопасность

### Настройки безопасности

1. **Master Key защита:**
   - Используется для всех административных операций
   - Хранится в переменных окружения
   - Регулярная ротация рекомендуется

2. **UI аутентификация:**
   - Опциональная базовая аутентификация
   - Можно интегрировать с SSO

3. **Database изоляция:**
   - Отдельный пользователь `litellm_user`
   - Ограниченные права доступа
   - Шифрование соединения

## 🐛 Устранение неполадок

### Частые проблемы

1. **UI недоступен:**
   ```bash
   # Проверить статус сервиса
   docker-compose ps litellm
   
   # Проверить логи
   docker-compose logs litellm
   
   # Перезапустить сервис
   docker-compose restart litellm
   ```

2. **Проблемы с редиректом:**
   - Использовать URL с завершающим слешем: `/ui/`
   - Проверить настройки nginx proxy

3. **Ошибки аутентификации:**
   - Проверить master key в env/litellm.env
   - Убедиться в корректности заголовков Authorization

### Логи и диагностика

```bash
# Просмотр логов LiteLLM
docker-compose logs -f litellm

# Проверка health endpoints
curl http://localhost:4000/health/liveliness
curl http://localhost:4000/health/readiness

# Проверка подключения к БД
docker-compose exec db psql -U litellm_user -d openwebui -c "\dt"
```

## 📈 Мониторинг

### Ключевые метрики

1. **Производительность:**
   - Response time < 2s
   - Database connection pool utilization
   - Memory usage

2. **Доступность:**
   - Health check status
   - UI accessibility
   - API response codes

3. **Использование:**
   - Number of active models
   - Virtual keys created
   - Request volume

## 🔄 Обновления

### Процедура обновления

1. **Backup конфигурации:**
   ```bash
   ./scripts/backup-system.sh
   ```

2. **Обновление образа:**
   ```bash
   docker-compose pull litellm
   docker-compose up -d litellm
   ```

3. **Проверка работоспособности:**
   ```bash
   curl http://localhost:4000/health/readiness
   ```

---

**Примечание:** Данная конфигурация оптимизирована для production использования в системе ERNI-KI с PostgreSQL persistent storage и Context Engineering capabilities.

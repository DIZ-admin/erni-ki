---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# Справочник API

В этом разделе документированы API платформы ERNI-KI.

## Auth Service API

Auth Service обеспечивает валидацию JWT токенов для платформы ERNI-KI.

### Базовые URL

| Окружение              | URL                        |
| ---------------------- | -------------------------- |
| Локальная разработка   | `http://localhost:9090`    |
| Docker внутренняя сеть | `http://auth-service:9090` |

### Эндпоинты

#### GET `/` - Информация о сервисе

Возвращает базовую информацию о сервисе аутентификации.

**Ответ (200 OK):**

```json
{
  "message": "auth-service is running",
  "version": "1.0.0",
  "status": "healthy",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### GET `/health` - Проверка здоровья

Возвращает статус здоровья сервиса аутентификации.

**Ответ (200 OK):**

```json
{
  "status": "healthy",
  "service": "auth-service",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### GET `/validate` - Валидация токена

Валидирует JWT токен, хранящийся в HTTP cookie `token`.

**Параметры:**

| Имя     | Расположение | Обязательный | Описание                 |
| ------- | ------------ | ------------ | ------------------------ |
| `token` | Cookie       | Да           | JWT токен аутентификации |

**Ответ (200 OK):**

```json
{
  "message": "authorized",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Ответ (401 Unauthorized):**

```json
{
  "message": "unauthorized",
  "error": "token missing",
  "request_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Аутентификация

Auth Service использует cookie-based JWT аутентификацию. Токены хранятся в HTTP
cookies и валидируются с помощью переменной окружения `WEBUI_SECRET_KEY`.

### OpenAPI Спецификация

Полная спецификация OpenAPI 3.0.3 доступна в файле
[auth-service-openapi.yaml](auth-service-openapi.yaml).

## Другие API

Документация дополнительных API будет добавлена по мере разработки сервисов:

- **LiteLLM Proxy** - маршрутизация и балансировка нагрузки LLM моделей
- **Webhook Service** - обработка алертов и авто-восстановление
- **Metrics API** - эндпоинты метрик Prometheus

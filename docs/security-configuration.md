# 🔒 Конфигурация безопасности ERNI-KI

## Обзор

Данный документ описывает настройки безопасности системы ERNI-KI, включая сетевую изоляцию, управление секретами, мониторинг безопасности и процедуры обслуживания.

## 🌐 Сетевая архитектура

### Изолированные сети

ERNI-KI использует многоуровневую сетевую архитектуру для обеспечения безопасности:

#### 🔵 Frontend сеть (`erni-ki-frontend`)
- **Подсеть**: 172.20.0.0/16
- **Назначение**: Веб-интерфейсы и внешний доступ
- **Сервисы**: auth, nginx, openwebui, litellm, searxng, docling, tika, edgetts, mcposerver, cloudflared

#### 🔴 Backend сеть (`erni-ki-backend`)
- **Подсеть**: 172.21.0.0/16
- **Изоляция**: `internal: true` - нет доступа к внешнему интернету
- **Назначение**: Критические внутренние сервисы
- **Сервисы**: db, redis, ollama, backrest + мультисетевые сервисы

#### ⚪ Default сеть (`erni-ki_default`)
- **Подсеть**: 172.18.0.0/16
- **Назначение**: Служебные сервисы
- **Сервисы**: watchtower

#### 📊 Monitoring сеть (`erni-ki-monitoring`)
- **Подсеть**: 172.19.0.0/16
- **Назначение**: Система мониторинга
- **Сервисы**: prometheus, grafana, alertmanager, node-exporter, cadvisor, etc.

### Мультисетевые сервисы

Следующие сервисы имеют доступ к нескольким сетям:
- **nginx**: frontend + backend (прокси-сервер)
- **openwebui**: frontend + backend (основной интерфейс)
- **litellm**: frontend + backend (AI gateway)
- **searxng**: frontend + backend (поисковый движок)

## 🔐 Управление секретами

### Docker Secrets

Пароли хранятся в директории `secrets/` с правами доступа 600:

```bash
secrets/
├── postgres_password.txt    # Пароль PostgreSQL
├── redis_password.txt       # Пароль Redis
└── backrest_password.txt    # Пароль Backrest
```

### Конфигурация в compose.yml

```yaml
secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
  redis_password:
    file: ./secrets/redis_password.txt
  backrest_password:
    file: ./secrets/backrest_password.txt
```

### Ротация паролей

Используйте скрипт автоматической ротации:

```bash
# Тестовый запуск
./scripts/rotate-secrets.sh --dry-run

# Ротация всех паролей
./scripts/rotate-secrets.sh

# Ротация конкретного сервиса
./scripts/rotate-secrets.sh --service postgres
```

## 🛡️ Security Headers в Nginx

### Настроенные заголовки

```nginx
# Отключение отображения версии Nginx
server_tokens off;

# Security headers - глобальные настройки безопасности
add_header X-Frame-Options DENY always;
add_header X-Content-Type-Options nosniff always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self';" always;
```

### Rate Limiting

```nginx
# Rate limiting - защита от DDoS и брутфорс атак
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;
limit_req_zone $binary_remote_addr zone=searxng_web:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=searxng_api:10m rate=10r/s;
```

## 📊 Мониторинг безопасности

### Security Alerts

Настроены алерты в `monitoring/security_alerts.yml`:

- **HighErrorRate**: Высокий уровень 5xx ошибок
- **SuspiciousLoginAttempts**: Множественные неудачные попытки входа
- **UnauthorizedAPIAccess**: Неавторизованный доступ к API
- **RateLimitingTriggered**: Частое срабатывание rate limiting
- **HighTrafficVolume**: Необычно высокий объем трафика
- **SSLCertificateExpiring**: Истечение SSL сертификата

### Системные алерты

- **HighCPUUsage**: Высокое использование CPU
- **HighMemoryUsage**: Высокое использование памяти
- **HighNetworkTraffic**: Подозрительная сетевая активность
- **DatabaseConnectionsHigh**: Высокое количество подключений к БД
- **RedisMemoryHigh**: Высокое использование памяти Redis
- **OllamaDown**: Недоступность Ollama сервиса

## ⚙️ Ресурсные ограничения

### Критические сервисы

```yaml
# PostgreSQL
deploy:
  resources:
    limits:
      memory: 4G
      cpus: "2.0"
    reservations:
      memory: 1G
      cpus: "0.5"

# Ollama (GPU)
deploy:
  resources:
    limits:
      memory: 8G
      cpus: "4.0"
    reservations:
      memory: 2G
      cpus: "1.0"
```

### Веб-сервисы

```yaml
# OpenWebUI
deploy:
  resources:
    limits:
      memory: 2G
      cpus: "1.0"
    reservations:
      memory: 512M
      cpus: "0.5"
```

## 🔧 Процедуры обслуживания

### Регулярные проверки

1. **Еженедельно**:
   - Проверка логов безопасности
   - Мониторинг алертов
   - Проверка использования ресурсов

2. **Ежемесячно**:
   - Ротация паролей
   - Обновление SSL сертификатов
   - Аудит сетевых настроек

3. **Ежеквартально**:
   - Полный аудит безопасности
   - Тестирование процедур восстановления
   - Обновление документации

### Команды диагностики

```bash
# Проверка статуса всех сервисов
docker-compose ps

# Проверка сетевых настроек
docker network ls | grep erni-ki

# Проверка логов безопасности
docker-compose logs nginx | grep -E "(40[0-9]|50[0-9])"

# Проверка использования ресурсов
docker stats --no-stream
```

## 🚨 Процедуры реагирования на инциденты

### При обнаружении подозрительной активности

1. **Немедленно**:
   - Проверить логи Nginx и алерты
   - Заблокировать подозрительные IP через rate limiting
   - Уведомить администратора

2. **В течение часа**:
   - Проанализировать масштаб инцидента
   - Применить дополнительные меры защиты
   - Задокументировать инцидент

3. **В течение дня**:
   - Провести полный анализ
   - Обновить правила безопасности
   - Подготовить отчет

### Контакты экстренного реагирования

- **Системный администратор**: [указать контакты]
- **Служба безопасности**: [указать контакты]
- **Техническая поддержка**: [указать контакты]

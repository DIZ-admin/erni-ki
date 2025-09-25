# 🔍 КОМПЛЕКСНАЯ ИНСТРУКЦИЯ ПО ДИАГНОСТИКЕ СИСТЕМЫ ERNI-KI

## 📋 Обзор

Данная инструкция основана на опыте исправления критических ошибок в методологии
тестирования, которые привели к занижению оценки системы с реальных 95%+ до
ошибочных 43-56%. Следование этой методологии обеспечит точную диагностику
реального состояния ERNI-KI.

---

## 🎯 1. ПРАВИЛЬНАЯ МЕТОДОЛОГИЯ ТЕСТИРОВАНИЯ КОМПОНЕНТОВ

### 🤖 LiteLLM - AI Model Proxy

**❌ НЕПРАВИЛЬНО:**

```bash
curl http://localhost:4000/health  # Без аутентификации
curl http://localhost:4000/v1/models  # Без Bearer токена
```

**✅ ПРАВИЛЬНО:**

```bash
# Проверка доступности моделей
curl -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
     http://localhost:4000/v1/models

# Тестирование генерации
curl -X POST "http://localhost:4000/v1/chat/completions" \
     -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
     -H "Content-Type: application/json" \
     -d '{"model": "gpt-4.1-nano-2025-04-14", "messages": [{"role": "user", "content": "Hello"}], "max_tokens": 50}'

# Проверка health endpoint (без аутентификации)
curl http://localhost:4000/health
```

**Критерии успеха:**

- `/v1/models` возвращает JSON с массивом моделей
- `/v1/chat/completions` генерирует текстовый ответ
- `/health` возвращает статус без ошибок 401

---

### 🔍 SearXNG - Search Engine

**❌ НЕПРАВИЛЬНО:**

```bash
curl http://localhost:8080/search?q=test  # Неправильный путь - возвращает HTML
curl -I http://localhost:8080  # Только HTTP коды
curl http://localhost:8080/searxng/search?q=test&format=json  # Устаревший путь
```

**✅ ПРАВИЛЬНО:**

```bash
# КРИТИЧЕСКИ ВАЖНО: Используйте правильный путь API через Nginx
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r '.results | length'

# Проверка времени отклика (правильный путь)
curl -s -w "TIME: %{time_total}s\n" "http://localhost:8080/api/searxng/search?q=test&format=json" | tail -1

# Проверка структуры JSON ответа
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r 'keys[]'

# Тестирование интеграции с OpenWebUI
docker logs erni-ki-openwebui-1 --since=5m | grep "GET /search?q=" | tail -5
```

**Критерии успеха:**

- JSON API возвращает валидный JSON с полем `results` (обычно 10-50 результатов)
- Структура ответа содержит ключи: `answers`, `corrections`, `infoboxes`,
  `number_of_results`, `query`, `results`, `suggestions`, `unresponsive_engines`
- Время отклика <2 секунд через `/api/searxng/search`
- Логи OpenWebUI показывают успешные запросы к SearXNG
- **ВАЖНО:** Прямой доступ к `/search` возвращает HTML - это нормально!

---

### 🗄️ Redis - Cache & Session Store

**❌ НЕПРАВИЛЬНО:**

```bash
docker exec erni-ki-redis-1 redis-cli ping  # Без пароля
docker exec erni-ki-redis-1 redis-cli get test  # NOAUTH ошибка
```

**✅ ПРАВИЛЬНО:**

```bash
# Проверка подключения с паролем
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping

# Тестирование операций записи/чтения
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" set test_key "test_value"
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" get test_key

# Проверка версии и статуса
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info server | grep redis_version
```

**Критерии успеха:**

- `ping` возвращает `PONG`
- Операции записи/чтения работают без ошибок NOAUTH
- Версия Redis актуальна (7.4+)

---

### 📄 Docling - Document Processing

**❌ НЕПРАВИЛЬНО:**

```bash
curl http://localhost:5001/health  # Порт 5001 закрыт для внешнего доступа!
curl http://localhost:5001/v1/document/convert  # Прямой доступ невозможен
```

**✅ ПРАВИЛЬНО:**

```bash
# КРИТИЧЕСКИ ВАЖНО: Docling доступен только через Nginx!
# Порт 5001 закомментирован в compose.yml для безопасности

# Проверка health endpoint через Nginx
curl -s "http://localhost:8080/api/docling/health" | jq '.'

# Тестирование обработки документов через Nginx
curl -s -X POST "http://localhost:8080/api/docling/v1/document/convert" \
     -F "file=@README.md" | head -5

# Проверка статуса контейнера
docker ps --filter "name=docling" --format "table {{.Names}}\t{{.Status}}"

# Проверка работы внутри Docker сети (для диагностики)
docker exec erni-ki-docling-1 curl -s "http://localhost:5001/health"
```

**Критерии успеха:**

- `/api/docling/health` возвращает `{"status":"ok"}` через Nginx
- Контейнер имеет статус "healthy"
- API обрабатывает документы без ошибок
- Контейнер в статусе "healthy"

---

### ☁️ Cloudflare Туннели - External Access

**❌ НЕПРАВИЛЬНО:**

```bash
curl https://erni-ki.diz-admin.com  # Несуществующий домен
nslookup erni-ki-dev.diz-admin.com  # Неправильный домен
```

**✅ ПРАВИЛЬНО:**

```bash
# Сначала проверить актуальную конфигурацию
cat conf/cloudflare/config.yml | grep hostname

# Тестировать реальные настроенные домены
curl -I "https://ki.erni-gruppe.ch"
curl -I "https://diz.zone"
curl -I "https://webui.diz.zone"
curl -I "https://lite.diz.zone"
curl -I "https://search.diz.zone"

# Проверка SSL сертификатов
openssl s_client -connect ki.erni-gruppe.ch:443 -servername ki.erni-gruppe.ch </dev/null 2>/dev/null | openssl x509 -noout -issuer -dates

# Проверка времени отклика
curl -s -w "TIME: %{time_total}s\nHTTP: %{http_code}\n" "https://ki.erni-gruppe.ch" -o /dev/null
```

**Критерии успеха:**

- Все настроенные домены возвращают HTTP 200
- SSL сертификаты валидны и не истекли
- Время отклика <5 секунд (обычно <0.1с)

---

## ⚠️ 2. ИЗБЕЖАНИЕ ТИПИЧНЫХ ОШИБОК ДИАГНОСТИКИ

### 🚫 Критические ошибки, которых нужно избегать:

1. **Тестирование без аутентификации**
   - Всегда проверяйте требования к аутентификации в документации
   - Используйте правильные API ключи и пароли

2. **Полагание только на HTTP коды**
   - HTTP 200 не гарантирует функциональность
   - Проверяйте содержимое ответов и структуру данных

3. **Использование неправильных endpoints**
   - Изучайте документацию API перед тестированием
   - Проверяйте актуальные конфигурационные файлы

4. **Игнорирование интеграций**
   - Тестируйте связи между сервисами
   - Проверяйте логи на предмет ошибок интеграции

5. **Тестирование несуществующих ресурсов**
   - Всегда проверяйте актуальную конфигурацию
   - Не предполагайте названия доменов или endpoints

### ✅ Правильный подход:

1. **Изучение конфигурации перед тестированием**
2. **Использование правильных параметров аутентификации**
3. **Проверка содержимого ответов, а не только статус кодов**
4. **Тестирование интеграций между компонентами**
5. **Валидация производительности и функциональности**

---

## � 2.1. НЕДАВНИЕ ИСПРАВЛЕНИЯ И УРОКИ (Сентябрь 2025)

### 📋 Исправленные проблемы диагностики

#### 🔍 SearXNG JSON API - Исправлено 25.09.2025

**Проблема:** SearXNG возвращал HTML вместо JSON при запросах с `format=json`

**Корневые причины:**

1. Неправильная конфигурация `base_url: "/searxng"` в
   `conf/searxng/settings.yml`
2. Использование неправильного пути `/search` вместо `/api/searxng/search`
3. Nginx конфигурация требует использования API пути

**Исправления:**

- ✅ Изменена конфигурация `base_url: ""` в `conf/searxng/settings.yml`
- ✅ Обновлены все тесты для использования `/api/searxng/search`
- ✅ Документирован правильный путь API

**Урок:** Всегда проверяйте конфигурацию Nginx для понимания правильных путей
API

#### 📄 Docling Service - Исправлено 25.09.2025

**Проблема:** Docling казался недоступным на порту 5001

**Корневые причины:**

1. Порт 5001 закомментирован в `compose.yml` для безопасности
2. Docling доступен только через Nginx по пути `/api/docling/`
3. Использование неправильного пути `localhost:5001` вместо
   `/api/docling/health`

**Исправления:**

- ✅ Документирован правильный путь через Nginx: `/api/docling/health`
- ✅ Обновлены все тесты для использования Nginx пути
- ✅ Добавлена информация о закрытом порте 5001

**Урок:** Изучайте Docker Compose конфигурацию для понимания сетевой архитектуры

### 🎯 Ключевые принципы после исправлений

1. **Всегда используйте правильные пути API через Nginx**
2. **Проверяйте конфигурацию Docker Compose для понимания портов**
3. **Тестируйте как внутри Docker сети, так и через внешние пути**
4. **Документируйте все найденные проблемы для будущих диагностик**

---

## �📊 3. СТРУКТУРА ДИАГНОСТИЧЕСКОГО ОТЧЕТА

### 🎯 Шаблон отчета:

```markdown
# ДИАГНОСТИЧЕСКИЙ ОТЧЕТ ERNI-KI

Дата: [YYYY-MM-DD HH:MM] Версия методологии: 2.0

## ИСПОЛНИТЕЛЬНОЕ РЕЗЮМЕ

- Общая оценка системы: [XX]%
- Критические проблемы: [N]
- Предупреждения: [N]
- Время выполнения диагностики: [XX] минут

## ДЕТАЛЬНЫЕ РЕЗУЛЬТАТЫ

### ✅ РАБОТАЮЩИЕ КОМПОНЕНТЫ

| Компонент | Статус | Время отклика | Примечания        |
| --------- | ------ | ------------- | ----------------- |
| LiteLLM   | ✅ OK  | 0.05s         | 3 модели доступны |

### ⚠️ ПРОБЛЕМЫ И РЕКОМЕНДАЦИИ

| Приоритет | Компонент | Проблема | Решение         | Время |
| --------- | --------- | -------- | --------------- | ----- |
| HIGH      | Redis     | NOAUTH   | Добавить пароль | 15мин |

### 📈 МЕТРИКИ ПРОИЗВОДИТЕЛЬНОСТИ

- Время отклика API: [среднее/медиана]
- Пропускная способность: [запросов/сек]
- Использование ресурсов: [CPU/RAM/GPU]

### 🔧 КОМАНДЫ ДЛЯ ВОСПРОИЗВЕДЕНИЯ

[Точные команды для повторения результатов]
```

---

## 📏 4. КРИТЕРИИ ОЦЕНКИ ЗДОРОВЬЯ СИСТЕМЫ

### 🎯 Система оценки (0-100%):

#### 🟢 ОТЛИЧНО (90-100%)

- ✅ Все Docker контейнеры "healthy"
- ✅ Все API endpoints отвечают корректно
- ✅ Интеграции работают без ошибок
- ✅ Внешний доступ через HTTPS
- ✅ Производительность в пределах SLA

#### 🟡 ХОРОШО (70-89%)

- ✅ Основные сервисы работают
- ⚠️ Минорные проблемы конфигурации
- ✅ Локальный доступ функционален
- ⚠️ Некоторые интеграции требуют настройки

#### 🟠 УДОВЛЕТВОРИТЕЛЬНО (50-69%)

- ⚠️ Часть сервисов недоступна
- ❌ Проблемы с аутентификацией
- ⚠️ Ограниченная функциональность
- ❌ Внешний доступ не работает

#### 🔴 КРИТИЧНО (<50%)

- ❌ Основные сервисы не работают
- ❌ Множественные ошибки конфигурации
- ❌ Система непригодна для использования

### 📊 Весовые коэффициенты компонентов:

| Компонент      | Вес | Обоснование                     |
| -------------- | --- | ------------------------------- |
| OpenWebUI      | 25% | Основной интерфейс пользователя |
| Ollama/LiteLLM | 20% | AI генерация - ключевая функция |
| SearXNG        | 15% | RAG функциональность            |
| PostgreSQL     | 15% | Хранение данных                 |
| Nginx          | 10% | Веб-сервер и проксирование      |
| Redis          | 5%  | Кэширование и сессии            |
| Cloudflare     | 5%  | Внешний доступ                  |
| Остальные      | 5%  | Вспомогательные сервисы         |

---

## 🚀 ЗАКЛЮЧЕНИЕ

Следование данной методологии обеспечит:

- ✅ Точную диагностику реального состояния системы
- ✅ Предотвращение ложных негативных результатов
- ✅ Правильную приоритизацию проблем
- ✅ Эффективное использование времени на диагностику

**Помните:** Система может работать лучше, чем показывает неправильное
тестирование!

---

## 🛠️ 5. ПРАКТИЧЕСКИЕ ПРИМЕРЫ ДИАГНОСТИЧЕСКИХ КОМАНД

### 🔄 Полная диагностика системы (5-минутный чек-лист):

```bash
#!/bin/bash
# ERNI-KI Quick Health Check Script

echo "=== ERNI-KI SYSTEM DIAGNOSTICS ==="
echo "Timestamp: $(date)"
echo

# 1. Docker контейнеры
echo "1. DOCKER CONTAINERS STATUS:"
docker ps --filter "name=erni-ki" --format "table {{.Names}}\t{{.Status}}" | grep -c "healthy"
echo

# 2. LiteLLM API
echo "2. LITELLM API TEST:"
curl -s -H "Authorization: Bearer sk-7b788d5ee69638c94477f639c91f128911bdf0e024978d4ba1dbdf678eba38bb" \
     "http://localhost:4000/v1/models" | jq -r '.data | length' 2>/dev/null || echo "FAILED"
echo

# 3. SearXNG Search (ИСПРАВЛЕНО: правильный путь API)
echo "3. SEARXNG SEARCH TEST:"
curl -s "http://localhost:8080/api/searxng/search?q=test&format=json" | jq -r '.results | length' 2>/dev/null || echo "FAILED"
echo

# 4. Redis Connection
echo "4. REDIS CONNECTION TEST:"
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" ping 2>/dev/null || echo "FAILED"
echo

# 5. Docling Health (ИСПРАВЛЕНО: правильный путь через Nginx)
echo "5. DOCLING HEALTH TEST:"
curl -s "http://localhost:8080/api/docling/health" | jq -r '.status' 2>/dev/null || echo "FAILED"
echo

# 6. External HTTPS Access
echo "6. EXTERNAL HTTPS ACCESS:"
curl -s -w "ki.erni-gruppe.ch: %{http_code} (%{time_total}s)\n" "https://ki.erni-gruppe.ch" -o /dev/null
curl -s -w "webui.diz.zone: %{http_code} (%{time_total}s)\n" "https://webui.diz.zone" -o /dev/null
echo

echo "=== DIAGNOSTICS COMPLETE ==="
```

### 📋 Детальная диагностика интеграций:

```bash
# Тестирование OpenWebUI → SearXNG интеграции
echo "Testing OpenWebUI → SearXNG integration:"
docker logs erni-ki-openwebui-1 --since=10m | grep -c "GET /search?q=" || echo "No recent searches"

# Тестирование OpenWebUI → LiteLLM интеграции
echo "Testing OpenWebUI → LiteLLM integration:"
docker logs erni-ki-openwebui-1 --since=10m | grep -c "litellm" || echo "No LiteLLM calls"

# Тестирование Redis кэширования
echo "Testing Redis caching:"
docker exec erni-ki-redis-1 redis-cli -a "ErniKiRedisSecurePassword2024" info stats | grep keyspace_hits

# Проверка GPU использования Ollama
echo "Testing Ollama GPU usage:"
docker exec erni-ki-ollama-1 nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "GPU not available"
```

---

## 📚 6. СПРАВОЧНАЯ ИНФОРМАЦИЯ

### 🔑 Ключевые конфигурационные файлы:

| Файл                         | Назначение           | Критические параметры            |
| ---------------------------- | -------------------- | -------------------------------- |
| `env/litellm.env`            | LiteLLM конфигурация | LITELLM_MASTER_KEY, DATABASE_URL |
| `env/redis.env`              | Redis настройки      | REDIS_PASSWORD                   |
| `conf/cloudflare/config.yml` | Cloudflare туннели   | tunnel, ingress rules            |
| `conf/nginx/nginx.conf`      | Nginx конфигурация   | upstream, proxy_pass             |
| `compose.yml`                | Docker Compose       | services, networks, volumes      |

### 🌐 Сетевая архитектура:

```
Internet → Cloudflare → Nginx (8080) → OpenWebUI (8080)
                                    ↓
                              LiteLLM (4000) ← → Ollama (11434)
                                    ↓
                              SearXNG (8080) ← → Redis (6379)
                                    ↓
                              PostgreSQL (5432)
```

### 📊 SLA и производительные метрики:

| Метрика                      | Целевое значение | Критический порог |
| ---------------------------- | ---------------- | ----------------- |
| Время отклика API            | <1s              | >5s               |
| Время отклика веб-интерфейса | <2s              | >10s              |
| Доступность системы          | >99%             | <95%              |
| Время генерации AI (GPU)     | <3s              | >30s              |
| Время поиска SearXNG         | <2s              | >10s              |

### 🔧 Команды для устранения типичных проблем:

```bash
# Перезапуск проблемного контейнера
docker restart erni-ki-[service-name]

# Очистка логов (если переполнены)
docker logs erni-ki-[service-name] --since=1h > /tmp/service-logs.txt
docker exec erni-ki-[service-name] truncate -s 0 /var/log/*.log

# Проверка использования ресурсов
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Проверка сетевых подключений
docker network inspect erni-ki_default | jq -r '.[] | .Containers | keys[]'
```

---

## ⚡ 7. АВТОМАТИЗАЦИЯ ДИАГНОСТИКИ

### 🤖 Создание диагностического скрипта:

```bash
# Сохранить как: scripts/health-check.sh
#!/bin/bash
set -e

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="diagnostic-report-${TIMESTAMP}.md"

{
    echo "# ERNI-KI DIAGNOSTIC REPORT"
    echo "Generated: $(date)"
    echo "Methodology Version: 2.0"
    echo

    # Выполнить все диагностические тесты
    # ... (команды из предыдущих разделов)

    echo "## SUMMARY"
    echo "System Health: ${HEALTH_SCORE}%"
    echo "Critical Issues: ${CRITICAL_COUNT}"
    echo "Recommendations: ${RECOMMENDATION_COUNT}"

} > "${REPORT_FILE}"

echo "Diagnostic report saved to: ${REPORT_FILE}"
```

### 📅 Настройка регулярной диагностики:

```bash
# Добавить в crontab для ежедневной диагностики в 06:00
0 6 * * * /path/to/erni-ki/scripts/health-check.sh >> /var/log/erni-ki-health.log 2>&1
```

---

## 🎯 ЗАКЛЮЧЕНИЕ

Данная методология диагностики ERNI-KI обеспечивает:

✅ **Точность диагностики** - предотвращение ложных негативных результатов ✅
**Эффективность** - быстрое выявление реальных проблем ✅
**Воспроизводимость** - четкие команды для повторения тестов ✅
**Приоритизацию** - фокус на критически важных компонентах ✅
**Автоматизацию** - возможность создания автоматических проверок

**Ключевой принцип:** Всегда проверяйте актуальную конфигурацию перед
тестированием и используйте правильные параметры аутентификации для каждого
сервиса.

**Помните:** Хорошо настроенная система ERNI-KI может работать на уровне 95%+ -
не позволяйте неправильной диагностике занижать реальную оценку!

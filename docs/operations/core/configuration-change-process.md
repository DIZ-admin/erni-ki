---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Процесс изменения конфигураций ERNI-KI

[TOC]

**Версия:** 1.0 **Дата создания:** 2025-09-25 **Последнее обновление:**
2025-09-25 **Ответственный:** Tech Lead

---

## ОБЩИЕ ПРИНЦИПЫ

### **Обязательные требования для ВСЕХ изменений:**

1. **Backup ПЕРЕД изменением** - всегда создавать резервную копию
2. **Тестирование** - проверять изменения в безопасной среде
3. **Документирование** - фиксировать все изменения с обоснованием
4. **Rollback план** - готовить план отката на случай проблем
5. **Мониторинг** - отслеживать систему после изменений

### **Классификация изменений:**

- ** КРИТИЧЕСКИЕ** - влияют на доступность системы (требуют maintenance window)
- **[WARNING] ВАЖНЫЕ** - влияют на производительность (требуют уведомления)
- **[OK] МИНОРНЫЕ** - не влияют на пользователей (можно выполнять в рабочее
  время)

---

## СТАНДАРТНЫЙ ПРОЦЕСС ИЗМЕНЕНИЙ

### **ЭТАП 1: ПЛАНИРОВАНИЕ**

#### **1.1 Анализ изменения**

```bash
# Определить тип изменения
echo "Тип изменения: [КРИТИЧЕСКОЕ/ВАЖНОЕ/МИНОРНОЕ]"
echo "Затрагиваемые сервисы: [список сервисов]"
echo "Ожидаемое время простоя: [минуты]"
echo "Rollback время: [минуты]"
```

## **1.2 Создание Change Request**

```markdown
## Change Request #CR-YYYYMMDD-XXX

**Дата:** YYYY-MM-DD **Инициатор:** [Имя] **Тип:** [КРИТИЧЕСКОЕ/ВАЖНОЕ/МИНОРНОЕ]

### Описание изменения:

[Подробное описание что и зачем изменяется]

### Затрагиваемые компоненты:

- [ ] Docker Compose (compose.yml)
- [ ] Environment файлы (env/\*)
- [ ] Конфигурации сервисов (conf/\*)
- [ ] Nginx настройки
- [ ] Prometheus/Grafana
- [ ] Другое: [указать]

### Риски и митигация:

[Описание рисков и способов их снижения]

### План тестирования:

[Как будет проверяться изменение]

### Rollback план:

[Как откатить изменение в случае проблем]
```

### **ЭТАП 2: ПОДГОТОВКА**

#### **2.1 Создание backup**

```bash
# Создать timestamped backup
BACKUP_DIR=".config-backup/change-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup конфигураций
sudo cp -r env/ "$BACKUP_DIR/"
sudo cp -r conf/ "$BACKUP_DIR/"
cp compose.yml "$BACKUP_DIR/"

# Backup базы данных (для критических изменений)
docker exec erni-ki-db-1 pg_dump -U postgres openwebui > "$BACKUP_DIR/database-backup.sql"

# Зафиксировать текущее состояние
docker compose ps > "$BACKUP_DIR/services-status-before.txt"
docker compose config > "$BACKUP_DIR/compose-config-before.yml"

echo "Backup создан в: $BACKUP_DIR"
```

## **2.2 Подготовка rollback скрипта**

```bash
# Создать rollback.sh
cat > rollback.sh << 'EOF'
# !/bin/bash
set -e

BACKUP_DIR="$1"
if [ -z "$BACKUP_DIR" ]; then
 echo "Usage: $0 <backup_directory>"
 exit 1
fi

echo " Начинаем rollback из $BACKUP_DIR"

# Остановить сервисы
docker compose down

# Восстановить конфигурации
sudo cp -r "$BACKUP_DIR/env/" ./
sudo cp -r "$BACKUP_DIR/conf/" ./
cp "$BACKUP_DIR/compose.yml" ./

# Запустить сервисы
docker compose up -d

echo " Rollback завершен"
EOF

chmod +x rollback.sh
```

## **ЭТАП 3: ВЫПОЛНЕНИЕ ИЗМЕНЕНИЙ**

### **3.1 Для КРИТИЧЕСКИХ изменений**

```bash
# 1. Уведомить пользователей
echo " MAINTENANCE WINDOW: $(date) - Плановое обслуживание системы"

# 2. Создать maintenance страницу (опционально)
docker run -d --name maintenance -p 80:80 nginx:alpine
docker exec maintenance sh -c 'echo "<h1>Система на обслуживании</h1><p>Ожидаемое время восстановления: 30 минут</p>" > /usr/share/nginx/html/index.html'

# 3. Остановить основные сервисы
docker compose stop openwebui nginx

# 4. Выполнить изменения
[выполнить конкретные изменения]

# 5. Запустить сервисы
docker compose up -d

# 6. Убрать maintenance страницу
docker stop maintenance && docker rm maintenance
```

## **3.2 Для ВАЖНЫХ изменений**

```bash
# 1. Уведомить о возможных кратковременных перебоях
echo "ℹ Выполняются плановые изменения конфигурации"

# 2. Выполнить изменения с минимальным простоем
[выполнить конкретные изменения]

# 3. Перезапустить только затронутые сервисы
docker compose restart [список_сервисов]
```

## **3.3 Для МИНОРНЫХ изменений**

```bash
# 1. Выполнить изменения без остановки сервисов
[выполнить конкретные изменения]

# 2. Применить изменения (если требуется)
docker compose up -d --no-recreate
```

## **ЭТАП 4: ТЕСТИРОВАНИЕ**

### **4.1 Базовые проверки (для всех изменений)**

```bash
# Проверка статуса сервисов
docker compose ps

# Проверка основных endpoints
curl -f http://localhost/health && echo " OpenWebUI работает" || echo " OpenWebUI недоступен"
curl -f http://localhost:11434/api/tags && echo " Ollama работает" || echo " Ollama недоступен"

# Проверка внешнего доступа
curl -s -I https://ki.erni-gruppe.ch/health | head -1 && echo " Внешний доступ работает" || echo " Внешний доступ недоступен"

# Проверка логов на ошибки
docker compose logs --since 5m | grep -i error | tail -10
```

## **4.2 Расширенные проверки (для критических изменений)**

```bash
# Функциональное тестирование
# 1. Тест авторизации
curl -X POST http://localhost/api/v1/auths/signin \
 -H "Content-Type: application/json" \
 -d '{"email":"test@example.com","password":"test"}' # pragma: allowlist secret

# 2. Тест AI функций
curl -X POST http://localhost:11434/api/generate \
 -H "Content-Type: application/json" \
 -d '{"model":"llama2","prompt":"Hello","stream":false}'

# 3. Тест поиска (SearXNG)
curl -f "http://localhost:8080/search?q=test&format=json"

# 4. Тест мониторинга
curl -f http://localhost:9090/api/v1/query?query=up
```

## **ЭТАП 5: МОНИТОРИНГ И ВАЛИДАЦИЯ**

### **5.1 Краткосрочный мониторинг (первые 30 минут)**

```bash
# Мониторинг каждые 5 минут
for i in {1..6}; do
 echo "=== Проверка #$i ($(date)) ==="
 docker compose ps | grep -v "Up" # Показать проблемные сервисы
 docker compose logs --since 5m | grep -i error | wc -l # Количество ошибок
 sleep 300
done
```

## **5.2 Долгосрочный мониторинг (первые 24 часа)**

```bash
# Создать мониторинг скрипт
cat > monitor-changes.sh << 'EOF'
# !/bin/bash
LOG_FILE="change-monitoring-$(date +%Y%m%d).log"

while true; do
 echo "$(date): Checking system health" >> $LOG_FILE

 # Проверка доступности
 curl -f http://localhost/health >> $LOG_FILE 2>&1 || echo "$(date): OpenWebUI DOWN" >> $LOG_FILE

 # Проверка ошибок
 ERROR_COUNT=$(docker compose logs --since 1h | grep -i error | wc -l)
 echo "$(date): Errors in last hour: $ERROR_COUNT" >> $LOG_FILE

 # Проверка ресурсов
 echo "$(date): Memory usage: $(free -h | grep Mem | awk '{print $3}')" >> $LOG_FILE

 sleep 3600 # Проверка каждый час
done
EOF

chmod +x monitor-changes.sh
nohup ./monitor-changes.sh &
```

---

## ТИПОВЫЕ ИЗМЕНЕНИЯ

### ** Изменение переменных окружения**

```bash
# 1. Backup
cp env/service.env env/service.env.backup-$(date +%Y%m%d-%H%M%S)

# 2. Изменение
sed -i 's/OLD_VALUE/NEW_VALUE/g' env/service.env

# 3. Применение
docker compose up -d service --no-recreate

# 4. Проверка
docker compose logs service --tail=20
```

## ** Обновление Docker образа**

```bash
# 1. Backup текущей конфигурации
docker compose config > compose-backup-$(date +%Y%m%d-%H%M%S).yml

# 2. Изменение версии в compose.yml
sed -i 's/service:old-version/service:new-version/g' compose.yml

# 3. Применение
docker compose pull service
docker compose up -d service

# 4. Проверка
docker compose ps service
docker compose logs service --tail=20
```

## ** Изменение конфигурации Nginx**

```bash
# 1. Backup
cp conf/nginx/conf.d/default.conf conf/nginx/conf.d/default.conf.backup-$(date +%Y%m%d-%H%M%S)

# 2. Изменение конфигурации
[редактировать файл]

# 3. Проверка синтаксиса
docker exec erni-ki-nginx-1 nginx -t

# 4. Применение
docker exec erni-ki-nginx-1 nginx -s reload

# 5. Проверка
curl -I http://localhost
```

## ** Изменение конфигурации Prometheus**

```bash
# 1. Backup
cp conf/prometheus/prometheus.yml conf/prometheus/prometheus.yml.backup-$(date +%Y%m%d-%H%M%S)

# 2. Изменение конфигурации
[редактировать файл]

# 3. Проверка синтаксиса
docker exec erni-ki-prometheus promtool check config /etc/prometheus/prometheus.yml

# 4. Применение
docker exec erni-ki-prometheus kill -HUP 1

# 5. Проверка
curl -f http://localhost:9090/api/v1/targets
```

---

## ЭКСТРЕННЫЕ ПРОЦЕДУРЫ

### **Немедленный rollback**

```bash
# Если что-то пошло не так
./rollback.sh .config-backup/change-YYYYMMDD-HHMMSS

# Проверка восстановления
docker compose ps
curl -f http://localhost/health
```

## **Частичный rollback**

```bash
# Откат только конкретного сервиса
docker compose stop service
cp backup/env/service.env env/
docker compose up -d service
```

---

## ОТЧЕТНОСТЬ

### **Post-Change Report Template**

```markdown
## Post-Change Report #CR-YYYYMMDD-XXX

**Дата выполнения:** YYYY-MM-DD HH:MM **Исполнитель:** [Имя] **Статус:**
[УСПЕШНО/ОТКАЧЕНО/ЧАСТИЧНО]

### Выполненные изменения:

[Список фактически выполненных изменений]

### Время простоя:

**Плановое:** X минут **Фактическое:** Y минут

### Проблемы и их решение:

[Описание возникших проблем и способов решения]

### Результаты тестирования:

- [ ] Базовые проверки пройдены
- [ ] Функциональные тесты пройдены
- [ ] Производительность в норме
- [ ] Мониторинг показывает стабильность

### Уроки и рекомендации:

[Что можно улучшить в следующий раз]
```

---

## СВЯЗАННЫЕ ДОКУМЕНТЫ

- [Service Restart Procedures](../maintenance/service-restart-procedures.md)
- [Troubleshooting Guide](../troubleshooting/troubleshooting-guide.md)
- [Backup Restore Procedures](../maintenance/backup-restore-procedures.md)
- [System Architecture](../../architecture/architecture.md)

---

_Документ создан в рамках оптимизации конфигураций ERNI-KI 2025-09-25_

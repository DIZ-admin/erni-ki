# План тестирования интеграции Backrest в ERNI-KI

## 🎯 Цели тестирования

1. **Функциональное тестирование** - проверка корректности работы всех компонентов
2. **Интеграционное тестирование** - проверка взаимодействия Backrest с существующими сервисами
3. **Тестирование восстановления** - проверка процедур disaster recovery
4. **Нагрузочное тестирование** - проверка производительности при больших объемах данных
5. **Безопасность** - проверка защиты данных и доступа

## 📋 Этапы тестирования

### Этап 1: Подготовка тестовой среды

#### 1.1 Развертывание тестового окружения
- [ ] Клонирование production конфигурации
- [ ] Создание изолированной тестовой среды
- [ ] Настройка тестовых данных
- [ ] Проверка доступности всех сервисов

#### 1.2 Установка Backrest
- [ ] Выполнение `scripts/backrest-setup.sh`
- [ ] Проверка создания всех директорий
- [ ] Валидация конфигурационных файлов
- [ ] Проверка генерации секретных ключей

### Этап 2: Функциональное тестирование

#### 2.1 Базовая функциональность
- [ ] Запуск Backrest контейнера
- [ ] Доступность веб-интерфейса (http://localhost:9898)
- [ ] Аутентификация в системе
- [ ] Создание первого репозитория

#### 2.2 Конфигурация планов бэкапов
- [ ] Создание плана для критических данных
- [ ] Настройка расписания бэкапов
- [ ] Конфигурация retention policy
- [ ] Настройка уведомлений

#### 2.3 Интеграция с Nginx
- [ ] Доступность через `/backrest` маршрут
- [ ] Проверка аутентификации через auth сервис
- [ ] Корректность проксирования WebSocket соединений
- [ ] Проверка таймаутов для длительных операций

### Этап 3: Тестирование бэкапов

#### 3.1 Создание бэкапов
- [ ] Ручное создание бэкапа критических данных
- [ ] Автоматический бэкап по расписанию
- [ ] Бэкап PostgreSQL данных
- [ ] Бэкап Ollama моделей
- [ ] Бэкап конфигурационных файлов

#### 3.2 Проверка целостности
- [ ] Валидация созданных снапшотов
- [ ] Проверка дедупликации данных
- [ ] Контроль размера бэкапов
- [ ] Проверка шифрования данных

#### 3.3 Мониторинг и логирование
- [ ] Проверка логов бэкапов
- [ ] Мониторинг использования ресурсов
- [ ] Уведомления об успешных/неудачных бэкапах
- [ ] Интеграция с системой мониторинга

### Этап 4: Тестирование восстановления

#### 4.1 Частичное восстановление
- [ ] Восстановление отдельных файлов
- [ ] Восстановление директорий
- [ ] Восстановление в альтернативное местоположение
- [ ] Проверка корректности восстановленных данных

#### 4.2 Полное восстановление системы
- [ ] Остановка всех сервисов ERNI-KI
- [ ] Очистка данных (симуляция катастрофы)
- [ ] Восстановление PostgreSQL базы данных
- [ ] Восстановление Ollama моделей
- [ ] Восстановление конфигураций
- [ ] Запуск и проверка работоспособности системы

#### 4.3 Point-in-time восстановление
- [ ] Восстановление данных на определенную дату
- [ ] Проверка консистентности данных
- [ ] Валидация временных меток

### Этап 5: Тестирование производительности

#### 5.1 Нагрузочное тестирование
- [ ] Бэкап больших объемов данных (>10GB)
- [ ] Параллельные операции бэкапа
- [ ] Влияние на производительность основных сервисов
- [ ] Тестирование при ограниченных ресурсах

#### 5.2 Оптимизация
- [ ] Настройка параметров сжатия
- [ ] Оптимизация расписания бэкапов
- [ ] Балансировка нагрузки на диск
- [ ] Настройка retention policy

### Этап 6: Тестирование безопасности

#### 6.1 Аутентификация и авторизация
- [ ] Проверка защиты веб-интерфейса
- [ ] Валидация интеграции с auth сервисом
- [ ] Тестирование различных ролей пользователей
- [ ] Проверка защиты API endpoints

#### 6.2 Шифрование и защита данных
- [ ] Проверка шифрования бэкапов
- [ ] Защита секретных ключей
- [ ] Безопасность передачи данных
- [ ] Аудит доступа к данным

### Этап 7: Disaster Recovery тестирование

#### 7.1 Сценарии катастроф
- [ ] Полная потеря сервера
- [ ] Повреждение файловой системы
- [ ] Потеря базы данных
- [ ] Компрометация системы

#### 7.2 Процедуры восстановления
- [ ] Документирование процедур
- [ ] Тестирование RTO (Recovery Time Objective)
- [ ] Проверка RPO (Recovery Point Objective)
- [ ] Валидация backup retention

## 🧪 Тестовые сценарии

### Сценарий 1: Ежедневный бэкап
```bash
# 1. Создание тестовых данных
echo "Test data $(date)" > data/openwebui/test-file.txt

# 2. Запуск ручного бэкапа
./scripts/backrest-management.sh backup critical-data-daily

# 3. Проверка создания снапшота
./scripts/backrest-management.sh status

# 4. Удаление тестового файла
rm data/openwebui/test-file.txt

# 5. Восстановление из бэкапа
./scripts/backrest-management.sh restore <snapshot-id> ./test-restore

# 6. Проверка восстановленных данных
ls -la ./test-restore/
```

### Сценарий 2: Восстановление базы данных
```bash
# 1. Создание дампа текущей БД
docker-compose exec db pg_dump -U postgres openwebui > test-db-backup.sql

# 2. Создание бэкапа через Backrest
./scripts/backrest-management.sh backup critical-data-daily

# 3. Симуляция потери данных
docker-compose exec db psql -U postgres -c "DROP DATABASE openwebui;"

# 4. Восстановление из Backrest
# (через веб-интерфейс или API)

# 5. Проверка целостности данных
docker-compose exec db psql -U postgres -d openwebui -c "SELECT COUNT(*) FROM users;"
```

### Сценарий 3: Тестирование производительности
```bash
# 1. Создание больших тестовых файлов
dd if=/dev/zero of=data/test-large-file.bin bs=1M count=1000

# 2. Измерение времени бэкапа
time ./scripts/backrest-management.sh backup critical-data-daily

# 3. Мониторинг ресурсов
./scripts/backrest-management.sh monitor

# 4. Очистка тестовых данных
rm data/test-large-file.bin
```

## 📊 Критерии успеха

### Функциональные критерии
- ✅ Все планы бэкапов выполняются успешно
- ✅ Восстановление данных работает корректно
- ✅ Веб-интерфейс доступен и функционален
- ✅ Интеграция с существующими сервисами работает

### Производительные критерии
- ✅ Время создания бэкапа < 30 минут для критических данных
- ✅ Влияние на производительность основных сервисов < 10%
- ✅ RTO (время восстановления) < 2 часа
- ✅ RPO (потеря данных) < 24 часа

### Безопасность
- ✅ Все данные зашифрованы
- ✅ Доступ защищен аутентификацией
- ✅ Секретные ключи защищены
- ✅ Аудит операций ведется

## 📝 Документация результатов

### Отчет о тестировании
- Дата и время проведения тестов
- Результаты каждого тестового сценария
- Выявленные проблемы и их решения
- Рекомендации по оптимизации
- План дальнейшего мониторинга

### Процедуры восстановления
- Пошаговые инструкции для различных сценариев
- Контактная информация ответственных лиц
- Чек-листы для проверки восстановления
- Планы коммуникации при инцидентах

## 🔄 Регулярное тестирование

### Еженедельно
- Проверка статуса бэкапов
- Тестирование восстановления отдельных файлов
- Мониторинг использования дискового пространства

### Ежемесячно
- Полное тестирование disaster recovery
- Проверка retention policy
- Обновление документации процедур

### Ежеквартально
- Нагрузочное тестирование
- Аудит безопасности
- Обзор и оптимизация конфигурации

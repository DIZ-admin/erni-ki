# ⚡ Быстрое руководство по оптимизации Docling

## 🎯 Краткое резюме
Сервис Docling работает корректно, но требует оптимизации конфигурации для устранения ошибок OCR и улучшения производительности.

## 🚀 Быстрое применение (5 минут)

### 1. Автоматическое применение
```bash
# Запуск скрипта автоматической оптимизации
./scripts/apply-docling-optimizations.sh
```

### 2. Ручное применение

#### Обновить конфигурацию
Файл `env/docling.env` уже содержит оптимизированные настройки:
```bash
# Основные настройки Docling
DOCLING_SERVE_ENABLE_UI=true

# Производительность и оптимизация  
DOCLING_SERVE_MAX_WORKERS=4
DOCLING_SERVE_TIMEOUT=300

# OCR настройки (отключение OSD для избежания ошибок)
DOCLING_OCR_ENGINE=easyocr
DOCLING_DISABLE_OSD=true

# Логирование
DOCLING_LOG_LEVEL=INFO

# Безопасность
DOCLING_SERVE_MAX_FILE_SIZE=100MB
```

#### Перезапустить сервис
```bash
docker-compose restart docling
```

#### Проверить статус
```bash
# Проверка здоровья
curl http://localhost:5001/health

# Проверка логов
docker-compose logs docling --tail 20
```

## ✅ Критерии успеха
- [ ] Сервис отвечает на `/health` за < 0.1s
- [ ] Нет ошибок Tesseract в логах
- [ ] Конвертация документов работает
- [ ] OpenWebUI может подключиться к Docling

## 🔍 Проверка результата
```bash
# Тест API
curl -X POST "http://localhost:5001/v1alpha/convert/file" \
  -H "Content-Type: multipart/form-data" \
  -F "files=@test.html" \
  -F "output_format=markdown"

# Проверка интеграции с OpenWebUI
docker exec erni-ki-openwebui-1 curl -s http://docling:5001/health
```

## 📋 Что исправлено
- ✅ Устранены ошибки Tesseract OCR
- ✅ Оптимизирована производительность (4 воркера)
- ✅ Увеличен таймаут до 300 секунд
- ✅ Ограничен размер файлов до 100MB
- ✅ Переключение на более стабильный EasyOCR

## 📊 Мониторинг
```bash
# Непрерывный мониторинг логов
docker-compose logs -f docling

# Проверка статуса контейнера
docker ps --filter "name=docling"

# Тест производительности
time curl -s http://localhost:5001/health
```

## 🆘 Откат изменений
Если что-то пошло не так:
```bash
# Восстановление из резервной копии
cp .config-backup-*/docling.env env/
docker-compose restart docling
```

## 📞 Поддержка
- **Полный отчет:** `docs/docling-diagnostic-report.md`
- **Архитектура:** Диаграмма Mermaid в отчете
- **Логи:** `docker-compose logs docling`

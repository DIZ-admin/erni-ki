# 🛠️ Скрипты автоматизации ERNI-KI v8.0

Реорганизованная коллекция скриптов для развертывания, управления и мониторинга
AI платформы ERNI-KI.

> **Обновлено:** 29 августа 2025 **Статус:** Production Ready (33/33 контейнера
> Healthy) **Backup:** `.config-backup/scripts-cleanup-20250829_112007/`

---

## 📁 Структура директорий

### 🏗️ **core/** - Основные операции системы

- **deployment/** - Развертывание и настройка
- **maintenance/** - Обслуживание и обновления
- **diagnostics/** - Диагностика и устранение неполадок

### 🔧 **infrastructure/** - Инфраструктурные сервисы

- **monitoring/** - Мониторинг и производительность
- **backup/** - Резервное копирование
- **security/** - Безопасность и SSL

### 🎯 **services/** - Сервис-специфичные скрипты

- **nginx/** - Веб-сервер и прокси
- **ollama/** - AI модели и GPU
- **openwebui/** - Пользовательский интерфейс

### 🛠️ **utilities/** - Вспомогательные инструменты

- **testing/** - Тестирование и нагрузочные тесты
- **reporting/** - Отчеты и аналитика

---

## 🚀 Быстрый старт

### Для новых пользователей

```bash
# Быстрый запуск системы
./scripts/core/deployment/quick-start.sh

# Полная настройка с GPU поддержкой
./scripts/core/deployment/setup.sh
```

### Для администраторов

```bash
# Проверка состояния системы
./scripts/core/diagnostics/health-check.sh

# Мониторинг производительности
./scripts/infrastructure/monitoring/system-health-monitor.sh
```

---

## 📋 Каталог скриптов по категориям

### 🏗️ **CORE - Основные операции**

#### **deployment/** - Развертывание системы

- `quick-start.sh` - Быстрый запуск за 5 минут
- `setup.sh` - Полная интерактивная настройка
- `gpu-setup.sh` - Настройка GPU ускорения
- `create-networks.sh` - Создание Docker сетей
- `deploy-monitoring-system.sh` - Развертывание мониторинга

#### **maintenance/** - Обслуживание системы

- `health-check.sh` - Комплексная диагностика (30-60 сек)
- `graceful-restart.sh` - Безопасный перезапуск
- `system-restart-report.sh` - Отчет о перезапуске
- `check-container-updates.sh` - Проверка обновлений
- `update-critical-containers.sh` - Критические обновления
- `comprehensive-audit.sh` - Полный аудит системы
- `quick-audit.sh` - Быстрая проверка

#### **diagnostics/** - Диагностика и устранение неполадок

- `automated-recovery.sh` - Автоматическое восстановление
- `dependency-checker.sh` - Проверка зависимостей сервисов
- `fix-critical-issues.sh` - Исправление критических проблем
- `network-diagnostics.sh` - Диагностика сети
- `container-compatibility-test.sh` - Тест совместимости
- `test-mcp-integration.sh` - Тест MCP интеграции
- `sql/` - SQL скрипты для анализа базы данных

### 🔧 **INFRASTRUCTURE - Инфраструктура**

#### **monitoring/** - Мониторинг и производительность

- `system-health-monitor.sh` - Мониторинг состояния системы
- `gpu-monitor.sh` - Мониторинг GPU
- `backrest-health-monitor.sh` - Мониторинг резервных копий
- `log-volume-analysis.sh` - Анализ объема логов
- `monitor-rate-limiting.sh` - Мониторинг rate limiting
- `watchtower-performance-monitor.sh` - Мониторинг Watchtower

#### **backup/** - Резервное копирование

- `backrest-management.sh` - Управление Backrest
- `backrest-setup.sh` - Настройка резервного копирования
- `check-local-backup.sh` - Проверка локальных бэкапов
- `complete-backup-setup.sh` - Полная настройка бэкапов

#### **security/** - Безопасность и SSL

- `security-hardening.sh` - Усиление безопасности
- `security-monitor.sh` - Мониторинг безопасности
- `rotate-secrets.sh` - Ротация секретов
- `setup-letsencrypt.sh` - Настройка Let's Encrypt
- `monitor-certificates.sh` - Мониторинг сертификатов

### 🎯 **SERVICES - Сервисы**

#### **nginx/** - Веб-сервер и прокси

- `nginx-monitor.sh` - Мониторинг nginx
- `nginx-optimization-fixes.sh` - Оптимизация nginx
- `production-setup.sh` - Production настройка

#### **ollama/** - AI модели и GPU

- `gpu-performance-test.sh` - Тест производительности GPU

#### **openwebui/** - Пользовательский интерфейс

- `test-openwebui-performance.sh` - Тест производительности OpenWebUI

### 🛠️ **UTILITIES - Утилиты**

#### **testing/** - Тестирование

- `rag-document-test.sh` - Тест RAG с документами
- `rag-performance-test.sh` - Тест производительности RAG
- `load-testing.sh` - Нагрузочное тестирование
- `quick-performance-test.sh` - Быстрый тест производительности

#### **reporting/** - Отчеты и аналитика

- `logging-reports.sh` - Отчеты по логированию

---

## 🎯 Примеры использования

### Быстрый старт новой системы

```bash
# 1. Развертывание
./scripts/core/deployment/quick-start.sh

# 2. Проверка состояния
./scripts/core/diagnostics/health-check.sh

# 3. Настройка мониторинга
./scripts/infrastructure/monitoring/system-health-monitor.sh
```

### Обслуживание работающей системы

```bash
# Проверка обновлений
./scripts/core/maintenance/check-container-updates.sh

# Создание резервной копии
./scripts/infrastructure/backup/backrest-management.sh

# Мониторинг производительности
./scripts/infrastructure/monitoring/gpu-monitor.sh
```

### Диагностика проблем

```bash
# Автоматическое восстановление
./scripts/core/diagnostics/automated-recovery.sh

# Проверка зависимостей
./scripts/core/diagnostics/dependency-checker.sh

# Диагностика сети
./scripts/core/diagnostics/network-diagnostics.sh
```

---

## 🔧 Настройка прав доступа

```bash
# Установка прав выполнения для всех скриптов
find scripts/ -name "*.sh" -exec chmod +x {} \;

# Проверка прав
find scripts/ -name "*.sh" -exec ls -la {} \;
```

---

## 📊 Статистика очистки

**Удаленные скрипты (устаревшие):**

- Elasticsearch/Kibana интеграции (4 скрипта)
- Image description функции (5 скриптов)
- Azure/OneDrive интеграции (4 скрипта)
- Дублирующиеся мониторинг скрипты (2 скрипта)

**Реорганизованные скрипты:** 60+ скриптов перемещены в логические категории

**Backup:** Все удаленные скрипты сохранены в
`.config-backup/scripts-cleanup-20250829_112007/`

---

## 🆘 Поддержка

При возникновении проблем:

1. Проверьте права выполнения: `chmod +x scripts/**/*.sh`
2. Запустите диагностику: `./scripts/core/diagnostics/health-check.sh`
3. Создайте issue: [GitHub Issues](https://github.com/DIZ-admin/erni-ki/issues)

**Время отклика:** Обычно в течение 24 часов **Поддерживаемые ОС:** Ubuntu
20.04+, Debian 11+, CentOS 8+

---

**⭐ Если проект оказался полезным, поставьте звезду на GitHub!**

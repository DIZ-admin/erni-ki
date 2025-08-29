#!/bin/bash
# ERNI-KI Log Rotation Setup Script
# Настройка автоматической ротации логов с 7-дневным retention

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGROTATE_CONFIG="$PROJECT_ROOT/conf/logrotate/erni-ki"

echo "🔄 Настройка автоматической ротации логов ERNI-KI..."

# Проверка прав доступа
if [ "$EUID" -eq 0 ]; then
    echo "⚠️  Не запускайте этот скрипт от root. Используйте sudo только для установки конфигурации."
    exit 1
fi

# Создание необходимых директорий
echo "📁 Создание директорий для логов..."
mkdir -p "$PROJECT_ROOT/logs"
mkdir -p "$PROJECT_ROOT/.config-backup/logs"
mkdir -p "$PROJECT_ROOT/monitoring/logs/critical"

# Проверка существования logrotate конфигурации
if [ ! -f "$LOGROTATE_CONFIG" ]; then
    echo "❌ Конфигурация logrotate не найдена: $LOGROTATE_CONFIG"
    exit 1
fi

# Тестирование конфигурации logrotate
echo "🧪 Тестирование конфигурации logrotate..."
if ! logrotate -d "$LOGROTATE_CONFIG" >/dev/null 2>&1; then
    echo "❌ Ошибка в конфигурации logrotate"
    logrotate -d "$LOGROTATE_CONFIG"
    exit 1
fi

# Установка конфигурации в систему (требует sudo)
echo "⚙️  Установка конфигурации logrotate в систему..."
if sudo cp "$LOGROTATE_CONFIG" /etc/logrotate.d/erni-ki; then
    echo "✅ Конфигурация logrotate установлена в /etc/logrotate.d/erni-ki"
else
    echo "❌ Ошибка установки конфигурации logrotate"
    exit 1
fi

# Проверка синтаксиса установленной конфигурации
echo "🔍 Проверка установленной конфигурации..."
if sudo logrotate -d /etc/logrotate.d/erni-ki >/dev/null 2>&1; then
    echo "✅ Конфигурация logrotate корректна"
else
    echo "❌ Ошибка в установленной конфигурации"
    sudo logrotate -d /etc/logrotate.d/erni-ki
    exit 1
fi

# Создание тестового лога для проверки
echo "📝 Создание тестового лога..."
echo "$(date): Test log entry for rotation" >> "$PROJECT_ROOT/logs/test-rotation.log"

# Тестовый запуск ротации
echo "🔄 Тестовый запуск ротации..."
if sudo logrotate -f /etc/logrotate.d/erni-ki; then
    echo "✅ Тестовая ротация выполнена успешно"
else
    echo "⚠️  Предупреждения при тестовой ротации (это нормально для первого запуска)"
fi

# Проверка cron задачи для logrotate
echo "⏰ Проверка cron задачи для logrotate..."
if crontab -l 2>/dev/null | grep -q logrotate; then
    echo "✅ Cron задача для logrotate уже настроена"
else
    echo "ℹ️  Logrotate будет запускаться через системный cron (/etc/cron.daily/logrotate)"
fi

echo ""
echo "🎉 Настройка автоматической ротации логов завершена!"
echo ""
echo "📊 Конфигурация:"
echo "   • Ежедневная ротация логов"
echo "   • 7 дней хранения обычных логов"
echo "   • 30 дней хранения критических логов"
echo "   • Сжатие старых логов"
echo "   • Автоматическое создание новых файлов"
echo ""
echo "📁 Директории логов:"
echo "   • Основные логи: $PROJECT_ROOT/logs/"
echo "   • Логи бэкапов: $PROJECT_ROOT/.config-backup/logs/"
echo "   • Критические логи: $PROJECT_ROOT/monitoring/logs/critical/"
echo ""
echo "🔧 Управление:"
echo "   • Ручная ротация: sudo logrotate -f /etc/logrotate.d/erni-ki"
echo "   • Проверка конфигурации: sudo logrotate -d /etc/logrotate.d/erni-ki"
echo "   • Просмотр статуса: sudo cat /var/lib/logrotate/status"

# Pre-commit Hooks для ERNI-KI

## Обзор

Pre-commit hooks автоматически проверяют качество кода перед каждым коммитом,
предотвращая попадание ошибок в репозиторий и CI/CD pipeline.

## Установка

### Автоматическая установка

```bash
npm run pre-commit:install
```

### Ручная установка

```bash
# Создать виртуальное окружение Python
python3 -m venv .venv

# Активировать окружение
source .venv/bin/activate

# Установить pre-commit
pip install pre-commit detect-secrets

# Установить hooks
pre-commit install
pre-commit install --hook-type commit-msg
```

## Настроенные проверки

### 🔍 Базовые проверки файлов

- **Trailing whitespace** - удаление лишних пробелов в конце строк
- **End-of-file** - добавление переноса строки в конце файлов
- **Large files** - предотвращение коммита файлов >500KB
- **Merge conflicts** - проверка на неразрешенные конфликты
- **Case conflicts** - проверка конфликтов регистра имен файлов

### 📝 Валидация форматов

- **YAML** - проверка синтаксиса YAML файлов
- **JSON** - проверка синтаксиса JSON файлов
- **TOML** - проверка синтаксиса TOML файлов

### 🎨 Форматирование кода

- **Prettier** - автоматическое форматирование:
  - Markdown файлы
  - YAML/JSON конфигурации
  - JavaScript/TypeScript код

### 🔧 Проверки кода

- **ESLint** - проверка JavaScript/TypeScript:
  - Качество кода
  - Безопасность (security plugin)
  - Node.js best practices
  - Promise handling

### 🔐 Безопасность

- **Detect Secrets** - поиск секретов в коде:
  - API ключи
  - Пароли
  - Токены
  - Сертификаты

### 📋 Коммиты

- **Commitlint** - проверка формата сообщений коммитов:
  - Conventional Commits стандарт
  - Правильная структура сообщений

### 🐹 Go код

- **gofmt** - форматирование Go кода
- **goimports** - организация импортов

### 🐳 Docker

- **Docker Compose** - валидация compose.yml

## Исключенные файлы

Следующие файлы исключены из проверок для безопасности:

```
.env*                    # Переменные окружения
conf/litellm/config.yaml # API ключи
conf/**/*.conf           # Конфигурации сервисов
*.key, *.pem, *.crt     # SSL сертификаты
secrets/                 # Директория секретов
data/                    # Данные сервисов
logs/                    # Логи
.config-backup/          # Backup файлы
```

## Использование

### Автоматический запуск

Pre-commit hooks запускаются автоматически при выполнении `git commit`.

### Ручной запуск

```bash
# Запуск всех проверок
npm run pre-commit:run

# Или через виртуальное окружение
source .venv/bin/activate
pre-commit run --all-files

# Запуск конкретной проверки
pre-commit run prettier --all-files
pre-commit run eslint --all-files
```

### Обновление hooks

```bash
npm run pre-commit:update

# Или
source .venv/bin/activate
pre-commit autoupdate
```

### Пропуск проверок (не рекомендуется)

```bash
git commit --no-verify -m "сообщение коммита"
```

## Интеграция с существующими инструментами

Pre-commit hooks интегрированы с:

- **ESLint** - использует `eslint.config.js`
- **Prettier** - использует `.prettierrc`
- **Commitlint** - использует `commitlint.config.cjs`
- **Husky** - работает параллельно с существующими hooks

## Устранение проблем

### Ошибки форматирования

```bash
# Автоматическое исправление
npm run format
npm run lint:fix
```

### Проблемы с секретами

```bash
# Обновление baseline
source .venv/bin/activate
detect-secrets scan --baseline .secrets.baseline
```

### Очистка кэша

```bash
source .venv/bin/activate
pre-commit clean
pre-commit install --install-hooks
```

## Производительность

- **Первый запуск**: 2-3 минуты (установка окружений)
- **Последующие запуски**: 10-30 секунд
- **Кэширование**: Результаты кэшируются для ускорения

## Совместимость

- **Python**: 3.12+
- **Node.js**: 20.18.0+
- **Git**: 2.0+
- **Docker**: для проверки compose файлов
- **Go**: для форматирования Go кода

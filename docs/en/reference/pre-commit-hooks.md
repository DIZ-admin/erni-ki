---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Pre-commit Hooks для ERNI-KI

[TOC]

## Обзор

Pre-commit hooks автоматически проверяют качество кода перед каждым коммитом,
предотвращая попадание ошибок в репозиторий и CI/CD pipeline.

## Установка

### Автоматическая установка

```bash
bun run pre-commit:install
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

### Базовые проверки файлов

-**Trailing whitespace**- удаление лишних пробелов в конце
строк -**End-of-file**- добавление переноса строки в конце файлов -**Large
files**- предотвращение коммита файлов >500KB -**Merge conflicts**- проверка на
неразрешенные конфликты -**Case conflicts**- проверка конфликтов регистра имен
файлов

### Валидация форматов

-**YAML**- проверка синтаксиса YAML файлов -**JSON**- проверка синтаксиса JSON
файлов -**TOML**- проверка синтаксиса TOML файлов

### Форматирование кода

-**Prettier**- автоматическое форматирование:

- Markdown файлы
- YAML/JSON конфигурации
- JavaScript/TypeScript код

### Проверки кода

-**ESLint**- проверка JavaScript/TypeScript:

- Качество кода
- Безопасность (security plugin)
- Node.js best practices
- Promise handling

### Безопасность

-**Detect Secrets**- поиск секретов в коде:

- API ключи
- Пароли
- Токены
- Сертификаты

### Коммиты

-**Commitlint**- проверка формата сообщений коммитов:

- Conventional Commits стандарт
- Правильная структура сообщений

### Go код

-**gofmt**- форматирование Go кода -**goimports**- организация импортов

### Docker

-**Docker Compose**- валидация compose.yml

### Cleanup & Documentation

-**Temporary files check**- предотвращение коммита временных файлов:

- `.tmp` файлы
- Файлы резервных копий (`*~`, `*.bak`)
- Системные файлы (`.DS_Store`) -**Рабочее дерево**- для локальной очистки
  артефактов используйте `scripts/utilities/git-clean-safe.sh` (удаляет
  `.DS_Store`, резервные копии, временные файлы и кэши через `git clean -fdX`,
  но не трогает `.git/hooks`). -**Status snippets**- проверка актуальности
  статусных сниппетов в документации -**Archive README**- проверка наличия
  README в архивных директориях

## Исключенные файлы

Следующие файлы исключены из проверок для безопасности:

```
.env* # Переменные окружения
conf/litellm/config.yaml # API ключи
conf/**/*.conf # Конфигурации сервисов
*.key, *.pem, *.crt # SSL сертификаты
secrets/ # Директория секретов
data/ # Данные сервисов
logs/ # Логи
.config-backup/ # Backup файлы
```

## Использование

### Автоматический запуск

Pre-commit hooks запускаются автоматически при выполнении `git commit`.

### Ручной запуск

```bash
# Запуск всех проверок
bun run pre-commit:run

# Или через виртуальное окружение
source .venv/bin/activate
pre-commit run --all-files

# Запуск конкретной проверки
pre-commit run prettier --all-files
pre-commit run eslint --all-files
```

## Обновление hooks

```bash
bun run pre-commit:update

# Или
source .venv/bin/activate
pre-commit autoupdate
```

## Пропуск проверок (не рекомендуется)

```bash
git commit --no-verify -m "сообщение коммита"
```

## Интеграция с существующими инструментами

Pre-commit hooks интегрированы с:

-**ESLint**- использует `eslint.config.js` -**Ruff**- использует `ruff.toml`
(установить `requirements-dev.txt`) -**Prettier**- использует
`.prettierrc` -**Commitlint**- использует `commitlint.config.cjs` -**Husky**-
работает параллельно с существующими hooks

## Устранение проблем

### Ошибки форматирования

```bash
# Автоматическое исправление
bun run format
bun run format:py
bun run lint:fix
```

## Проблемы с секретами

```bash
# Обновление baseline
source .venv/bin/activate
detect-secrets scan --baseline .secrets.baseline
```

## Обнаружены временные файлы

```bash
# Найти все временные файлы
find . -type f \( -name "*.tmp" -o -name "*~" -o -name "*.bak" \) ! -path "*/node_modules/*" ! -path "*/.git/*"

# Удалить все временные файлы
find . -type f \( -name "*.tmp" -o -name "*~" -o -name "*.bak" \) ! -path "*/node_modules/*" ! -path "*/.git/*" -delete

# Удалить .DS_Store файлы (macOS)
find . -name ".DS_Store" -delete
```

## Очистка кэша

```bash
source .venv/bin/activate
pre-commit clean
pre-commit install --install-hooks
```

## Производительность

-**Первый запуск**: 2-3 минуты (установка окружений) -**Последующие запуски**:
10-30 секунд -**Кэширование**: Результаты кэшируются для ускорения

## Совместимость

-**Python**: 3.12+ -**Node.js**: 20.18.0+ -**Git**: 2.0+ -**Docker**: для
проверки compose файлов -**Go**: для форматирования Go кода

# Настройка линтеров ERNI-KI

## Установленные линтеры

### JavaScript/TypeScript

- **ESLint** v9.15.0 (Flat Config)
- **TypeScript** v5.7.2
- **Prettier** v3.6.2

Конфигурация: `eslint.config.js`, `.prettierrc.json`

### Python

- **Ruff** v0.14.6 (lint + format)

Конфигурация: `ruff.toml`

### Go

- **gofmt** - форматирование
- **goimports** - организация импортов
- **golangci-lint** - линтинг

### Другое

- **Pre-commit hooks** - 26 проверок перед коммитом
- **Detect-secrets** - поиск секретов в коде
- **Prettier** - форматирование YAML/JSON/Markdown

## Быстрые команды

```bash
# Полная проверка
npm run lint              # JS/TS + Python
npm run type-check        # TypeScript

# Автоисправление
npm run lint:fix          # все линтеры
npm run format            # форматирование

# По языкам
npm run lint:js           # только JavaScript/TypeScript
npm run lint:py           # только Python
npm run format:py         # форматирование Python

# Pre-commit
npm run pre-commit:run    # вручную
git commit                # автоматически
```

## VSCode настройки

Активированы в `.vscode/settings.json`:
- Format on save для всех файлов
- ESLint auto-fix on save
- Ruff как formatter для Python
- Organize imports on save

## Рекомендуемые расширения

Установить через `.vscode/extensions.json`:
- ESLint (dbaeumer.vscode-eslint)
- Prettier (esbenp.prettier-vscode)
- Ruff (charliermarsh.ruff)
- Python (ms-python.python)
- Go (golang.go)

## Конфигурационные файлы

| Файл | Назначение |
|------|------------|
| `eslint.config.js` | ESLint правила (Flat Config) |
| `ruff.toml` | Ruff настройки (Python) |
| `.prettierrc.json` | Prettier форматирование |
| `.pre-commit-config.yaml` | Pre-commit хуки |
| `tsconfig.json` | TypeScript компилятор |
| `.vscode/settings.json` | VSCode интеграция |

## Troubleshooting

### Python линтер не работает

```bash
source .venv/bin/activate
pip install -r requirements-dev.txt
```

### Pre-commit хуки не запускаются

```bash
npm run pre-commit:install
```

### ESLint не находит конфигурацию

Убедитесь, что используется Flat Config (`eslint.config.js`)
и в VSCode настроен `"eslint.useFlatConfig": true"

---
Обновлено: 2025-11-24

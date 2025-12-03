---
language: ru
translation_status: complete
doc_version: '2025.12'
last_updated: '2025-12-03'
---

# Руководство по миграции на Bun

## Зачем

- 3-4x быстрее установка зависимостей по сравнению с npm.
- Нативное выполнение TypeScript без отдельного ts-node.
- Простые вызовы CLI: `bun run` для скриптов, `bunx` вместо npx.

## Требования

- Bun >= 1.3.3 (`bun --version`).
- Docker для сервисов, Python 3.11+ для скриптов.

## Установка Bun

macOS (Homebrew):

```bash
brew install bun
```

Linux/WSL2:

```bash
curl -fsSL https://bun.sh/install | bash
```

Убедитесь, что `~/.bun/bin` в PATH.

## Повседневные команды

```bash
# Установка зависимостей
bun install

# Скрипты
bun run test           # unit + e2e:mock
bun run lint           # eslint + ruff
bun run lint:language  # проверка языка
bun run type-check     # tsc --noEmit

# Playwright браузеры (однократно после fresh install)
bunx playwright install --with-deps chromium
```

## Замены npm → Bun

- `npm run <script>` → `bun run <script>`
- `npx <tool>` → `bunx <tool>`
- `npm audit` → `bun audit`

## Совместимость и заметки

- Lockfile: `bun.lock` (binary формат по умолчанию).
- Git hooks: Husky запускает `bun run lint:language`, `bunx lint-staged`,
  `bunx --bun commitlint`.
- Если браузеры Playwright не скачаны, тесты упадут с подсказкой; выполняйте
  команду из блока выше.

## Частые проблемы

- **Нет браузеров Playwright:** `bunx playwright install --with-deps chromium`.
- **Долгий eslint по node_modules.backup:** запускайте линт на tracked
  исходниках или используйте `eslint . --ext ... --ignore-path .gitignore`.

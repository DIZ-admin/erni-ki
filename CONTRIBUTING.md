# Руководство по участию в проекте ERNI-KI

Спасибо за интерес к участию в развитии ERNI-KI! Мы ценим любой вклад в проект.

## Содержание

- [Как помочь проекту](#как-помочь-проекту)
- [Сообщение об ошибках](#сообщение-об-ошибках)
- [Предложение улучшений](#предложение-улучшений)
- [Разработка](#разработка)
- [Стандарты кодирования](#стандарты-кодирования)
- [Тестирование](#тестирование)
- [Документация](#документация)

## Как помочь проекту

### Сообщение об ошибках

- Проверьте, что ошибка еще не была зарегистрирована в
  [Issues](https://github.com/DIZ-admin/erni-ki/issues)
- Используйте шаблон для сообщения об ошибках
- Предоставьте максимально подробную информацию

### Предложение новых функций

- Обсудите идею в
  [Discussions](https://github.com/DIZ-admin/erni-ki/discussions)
- Создайте Feature Request с детальным описанием
- Объясните, как это улучшит проект

### Улучшение документации

- Исправление опечаток и грамматических ошибок
- Добавление примеров использования
- Перевод документации на другие языки
- Создание туториалов и гайдов
- При обновлении статусных метрик редактируйте только
  `docs/reference/status.yml`, затем выполняйте
  `scripts/docs/update_status_snippet.py` — он синхронизирует `README.md`,
  `docs/index.md` и `docs/overview.md`.
- Для новых файлов код и конфигурация (включая комментарии) должны быть на
  английском.
- Документация — в `docs/ru/`, `docs/de/` или `docs/en/`.
- Проверка запускается командой `npm run lint:language`.
- Линтеры кода: `pip install -r requirements-dev.txt && npm run lint` (ESLint +
  Ruff).
- Подробные правила описаны в `docs/reference/language-policy.md`.
- Стандарты метаданных (frontmatter) — в `docs/reference/metadata-standards.md`.

### Тестирование

- Тестирование новых функций
- Написание unit и integration тестов
- Тестирование на различных платформах
- Нагрузочное тестирование

## Быстрые команды pre-commit

- Запустить хуки только для изменённых файлов: `pre-commit run`
- Запустить для конкретного файла: `pre-commit run --files path/to/file.md`
- Пропустить тяжёлые хуки (например, link-check/type-check) при локальной
  проверке:
  `SKIP="visuals-and-links-check,docs-validate-metadata,docs-validate-status-snippets,typescript-type-check,eslint,docker-compose-check" pre-commit run --files path/to/file`
- Проверить всё (медленно): `pre-commit run --all-files`
- Удалить мусор/дубликаты перед коммитом: `git clean -fdX` (предварительно
  сохраните нужные файлы)

## Сообщение об ошибках

### Перед созданием Issue

1. **Поиск существующих Issues** - возможно, проблема уже известна
2. **Проверка документации** - убедитесь, что это действительно ошибка
3. **Воспроизведение** - убедитесь, что ошибка воспроизводится стабильно

### Шаблон сообщения об ошибке

```markdown
## Описание ошибки

Краткое и четкое описание проблемы.

## Шаги для воспроизведения

1. Перейти к '...'
2. Нажать на '...'
3. Прокрутить до '...'
4. Увидеть ошибку

## Ожидаемое поведение

Описание того, что должно было произойти.

## Скриншоты

Если применимо, добавьте скриншоты для объяснения проблемы.

## Информация о системе

- ОС: [например, Ubuntu 22.04]
- Docker версия: [например, 24.0.7]
- Версия ERNI-KI: [например, 2.0.0]
- GPU: [например, NVIDIA RTX 4060]

## Логи
```

Вставьте соответствующие логи здесь

```

## Дополнительный контекст
Любая другая информация о проблеме.
```

## Предложение улучшений

### Шаблон Feature Request

```markdown
## Описание функции

Четкое и краткое описание желаемой функции.

## Проблема, которую решает

Объясните проблему, которую вы пытаетесь решить.

## Предлагаемое решение

Детальное описание того, как должна работать функция.

## Альтернативы

Описание альтернативных решений, которые вы рассматривали.

## Дополнительный контекст

Скриншоты, макеты, или другие материалы.
```

## Разработка

### Правила веток и merge

- Основные ветки: `main` (prod), `develop` (integration). Ветки `release/*` и
  `hotfix/*` — только по необходимости и удаляются после слияния.
- Новые работы: `feature/<тема>`, `fix/<тема>`, `docs/<тема>`, `ci/<тема>`,
  `hotfix/<issue>` (от `main`, затем back-merge в `develop`).
- База PR: всё, кроме hotfix, мержится в `develop`; hotfix — в `main` с обратным
  мержем в `develop`. Предпочтительный merge — squash (чистая история), удалять
  ветку после merge.
- Требования к PR: все проверки зелёные (CI, mypy, линтеры, покрытие), ветка
  синхронизирована с базовой (`rebase`/`update branch`), нет локальных
  TODO/FIXME без задач.
- Гигиена: не держать ветки >4 недель без движения; регулярно удалять слитые
  ветки (`git fetch --prune` локально, автоудаление веток в настройках
  репозитория).

### Требования к PR и проверкам

- Все статус-проверки зелёные: линтеры (ESLint/Ruff), mypy, тесты
  (Python/Go/JS), покрытие (целевое ≥80% после повышения фактического),
  security-сканы (CodeQL + дополнительные).
- Ветка синхронизирована с базовой, конфликты и TODO/FIXME без задач
  отсутствуют.
- Merge: предпочтительно squash, удалять ветку после merge.

### Минимальные версии инструментов

- Node.js: 22.14.0 (`nvm use` по `.nvmrc`).
- Python: 3.11 (venv обязателен перед установкой зависимостей).
- Go: версия из `auth/go.mod`; `gofmt`/`goimports` ставятся `go install`.
- pre-commit: ≥3.5.0; установка:
  `pre-commit install && pre-commit install --hook-type commit-msg`.

### Процесс релиза (кратко)

- Поток: `feature/*` → PR в `develop`; hotfix от `main` с back-merge в
  `develop`; release/\_ только при подготовке релиза.
- Перед релизом: все проверки зелёные, покрытие соответствует целевому, Codecov
  статус успешен.
- После релиза: удалить release/hotfix ветку, убедиться в обратном merge в
  `develop`.

### Настройка среды разработки

1. **Fork репозитория**

```bash
# Клонируйте ваш fork
git clone https://github.com/your-username/erni-ki.git
cd erni-ki

# Добавьте upstream remote
git remote add upstream https://github.com/DIZ-admin/erni-ki.git
```

2. **Установка зависимостей**

```bash
# Node.js зависимости
npm install

# Go зависимости для auth сервиса
cd auth
go mod download
cd ..

# Python зависимости для сборки документации (MkDocs + i18n)
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install mkdocs mkdocs-material mkdocs-static-i18n

# Копирование конфигураций
cp compose.yml.example compose.yml
for file in env/*.example; do
 cp "$file" "${file%.example}"
done
```

3. **Запуск в режиме разработки**

```bash
# Запуск всех сервисов
docker compose up -d

# Просмотр логов
docker compose logs -f
```

### Процесс разработки

1. **Создание ветки**

```bash
git checkout -b feature/amazing-feature
```

2. **Внесение изменений**

- Следуйте стандартам кодирования
- Добавьте тесты для новой функциональности
- Обновите документацию при необходимости

3. **Коммиты**

```bash
# Используйте conventional commits
git commit -m "feat: добавить поддержку новых языковых моделей"
git commit -m "fix: исправить ошибку аутентификации"
git commit -m "docs: обновить API документацию"
```

4. **Push и Pull Request**

```bash
git push origin feature/amazing-feature
```

## Стандарты кодирования

### TypeScript/JavaScript

```typescript
// Используйте строгую типизацию
interface ChatMessage {
  id: string;
  content: string;
  role: 'user' | 'assistant';
  timestamp: Date;
}

// Предпочитайте async/await
async function sendMessage(message: ChatMessage): Promise<Response> {
  try {
    const response = await fetch('/api/v1/messages', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(message),
    });
    return response;
  } catch (error) {
    console.error('Failed to send message:', error);
    throw error;
  }
}
```

### Go

```go
// Используйте четкие имена и обработку ошибок
func ValidateJWT(tokenString string) (*Claims, error) {
 token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
 if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
 return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
 }
 return []byte(os.Getenv("JWT_SECRET")), nil
 })

 if err != nil {
 return nil, fmt.Errorf("failed to parse token: %w", err)
 }

 if claims, ok := token.Claims.(*Claims); ok && token.Valid {
 return claims, nil
 }

 return nil, fmt.Errorf("invalid token")
}
```

### Conventional Commits

Используйте следующие префиксы:

- `feat:` - новая функция
- `fix:` - исправление ошибки
- `docs:` - изменения в документации
- `style:` - форматирование кода
- `refactor:` - рефакторинг кода
- `test:` - добавление тестов
- `chore:` - обновление зависимостей, конфигураций

## Тестирование

### Запуск тестов

```bash
# Все тесты
npm test

# Unit тесты
npm run test:unit

# Integration тесты
npm run test:integration

# Тесты с покрытием
npm run test:coverage

# Go тесты
cd auth && go test -v ./...
```

### Написание тестов

```typescript
// tests/unit/auth.test.ts
import { describe, it, expect } from 'vitest';
import { validateJWT } from '../src/utils/auth';

describe('Auth Utils', () => {
  it('should validate correct JWT token', () => {
    const token = 'valid-jwt-token';
    const result = validateJWT(token);
    expect(result.valid).toBe(true);
  });

  it('should reject invalid JWT token', () => {
    const token = 'invalid-token';
    const result = validateJWT(token);
    expect(result.valid).toBe(false);
  });
});
```

## Документация

### Обновление документации

- Все изменения API должны быть отражены в `docs/reference/api-reference.md`
- Новые функции требуют обновления `docs/getting-started/user-guide.md`
- Изменения в архитектуре - обновление `docs/architecture/architecture.md`

### Стиль документации

- Используйте четкие заголовки и структуру
- Добавляйте примеры кода
- Включайте скриншоты для UI изменений
- Пишите на русском языке для основной документации

## Code Review

### Что проверяем

- Код соответствует стандартам проекта
- Все тесты проходят
- Документация обновлена
- Нет breaking changes без major version bump
- Безопасность кода

### Процесс Review

1. Автоматические проверки CI/CD должны пройти
2. Минимум 1 approval от maintainer
3. Все комментарии должны быть разрешены
4. Squash merge для feature веток

## Релизы

### Версионирование

Проект использует [Semantic Versioning](https://semver.org/):

- **MAJOR** - несовместимые изменения API
- **MINOR** - новая функциональность с обратной совместимостью
- **PATCH** - исправления ошибок

### Процесс релиза

1. Обновление `CHANGELOG.md`
2. Создание release branch
3. Тестирование релиза
4. Создание Git tag
5. Публикация release notes

## Связь

- **GitHub Issues** - для багов и feature requests
- **GitHub Discussions** - для общих вопросов
- **Email** - для приватных вопросов

---

**Спасибо за участие в развитии ERNI-KI!**

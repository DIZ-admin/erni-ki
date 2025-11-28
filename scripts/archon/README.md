# Archon API Helper Scripts

Набор скриптов для работы с Archon API через REST интерфейс.

## Доступные скрипты

### get-tasks.sh

Получение списка задач с фильтрацией по статусу.

**Использование:**

```bash
# Все задачи
./scripts/archon/get-tasks.sh

# Только TODO задачи
./scripts/archon/get-tasks.sh todo

# Только DOING задачи
./scripts/archon/get-tasks.sh doing

# Только DONE задачи
./scripts/archon/get-tasks.sh done
```

### get-projects.sh

Получение списка всех проектов.

**Использование:**

```bash
./scripts/archon/get-projects.sh
```

### search-kb.sh

Поиск в knowledge base Archon.

**Использование:**

```bash
./scripts/archon/search-kb.sh "query text"

# Примеры
./scripts/archon/search-kb.sh "authentication JWT"
./scripts/archon/search-kb.sh "docker compose"
./scripts/archon/search-kb.sh "postgres setup"
```

## Прямой доступ к API

### Endpoints

| Endpoint                                     | Метод | Описание          |
| -------------------------------------------- | ----- | ----------------- |
| `http://localhost:8181/api/health`           | GET   | Health check      |
| `http://localhost:8181/api/tasks`            | GET   | Список всех задач |
| `http://localhost:8181/api/projects`         | GET   | Список проектов   |
| `http://localhost:8181/api/knowledge/search` | POST  | Поиск в KB        |

### Примеры

```bash
# Health check
curl -s http://localhost:8181/api/health | jq .

# Все задачи
curl -s http://localhost:8181/api/tasks | jq .

# TODO задачи
curl -s http://localhost:8181/api/tasks | \
  jq '.tasks[] | select(.status == "todo")'

# Поиск в KB
curl -s -X POST http://localhost:8181/api/knowledge/search \
  -H "Content-Type: application/json" \
  -d '{"query": "docker", "limit": 5}' | jq .
```

## Требования

- `curl` - для HTTP запросов
- `jq` - для обработки JSON (опционально, но рекомендуется)

## Archon UI

Web интерфейс доступен по адресу: http://localhost:3737

## Статус сервисов

Проверить статус Archon контейнеров:

```bash
docker ps | grep archon
```

Должны быть запущены:

- `archon-mcp` (порт 8051)
- `archon-server` (порт 8181)
- `archon-ui` (порт 3737)
- `archon-agent-work-orders` (порт 8053)

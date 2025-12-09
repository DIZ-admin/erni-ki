# Archon API Helper Scripts

A set of scripts for working with Archon API via REST interface.

## Available Scripts

### get-tasks.sh

Get task list with status filtering.

**Usage:**

```bash
# All tasks
./scripts/archon/get-tasks.sh

# Only TODO tasks
./scripts/archon/get-tasks.sh todo

# Only DOING tasks
./scripts/archon/get-tasks.sh doing

# Only DONE tasks
./scripts/archon/get-tasks.sh done
```

### get-projects.sh

Get list of all projects.

**Usage:**

```bash
./scripts/archon/get-projects.sh
```

### search-kb.sh

Search in Archon knowledge base.

**Usage:**

```bash
./scripts/archon/search-kb.sh "query text"

# Examples
./scripts/archon/search-kb.sh "authentication JWT"
./scripts/archon/search-kb.sh "docker compose"
./scripts/archon/search-kb.sh "postgres setup"
```

## Direct API Access

### Endpoints

| Endpoint                                     | Method | Description    |
| -------------------------------------------- | ------ | -------------- |
| `http://localhost:8181/api/health`           | GET    | Health check   |
| `http://localhost:8181/api/tasks`            | GET    | List all tasks |
| `http://localhost:8181/api/projects`         | GET    | List projects  |
| `http://localhost:8181/api/knowledge/search` | POST   | Search in KB   |

### Examples

```bash
# Health check
curl -s http://localhost:8181/api/health | jq .

# All tasks
curl -s http://localhost:8181/api/tasks | jq .

# TODO tasks
curl -s http://localhost:8181/api/tasks | \
  jq '.tasks[] | select(.status == "todo")'

# Search in KB
curl -s -X POST http://localhost:8181/api/knowledge/search \
  -H "Content-Type: application/json" \
  -d '{"query": "docker", "limit": 5}' | jq .
```

## Requirements

- `curl` - for HTTP requests
- `jq` - for JSON processing (optional but recommended)

## Archon UI

Web interface is available at: http://localhost:3737

## Service Status

Check Archon container status:

```bash
docker ps | grep archon
```

Should be running:

- `archon-mcp` (port 8051)
- `archon-server` (port 8181)
- `archon-ui` (port 3737)
- `archon-agent-work-orders` (port 8053)

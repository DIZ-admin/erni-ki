# SQL Scripts for ERNI-KI Diagnostics

A collection of SQL scripts for analysis and diagnostics of the ERNI-KI
PostgreSQL database.

## Available Scripts

### `analyze-openwebui-config.sql`

**Purpose:** Analyze OpenWebUI settings in PostgreSQL database **Usage:**

```bash
# Connect to database and execute script
docker exec -i erni-ki-db-1 psql -U postgres -d openwebui -f /path/to/analyze-openwebui-config.sql

# Or via psql client
psql -h localhost -U postgres -d openwebui -f scripts/core/diagnostics/sql/analyze-openwebui-config.sql
```

**What it analyzes:**

- All settings from config table
- RAG and embedding settings
- Model settings
- User and authentication settings
- Integration settings (SearXNG, Ollama)

**Example output:**

```
=== OPENWEBUI SETTINGS ===
 setting_key | setting_value | created_at | updated_at
-------------+---------------+------------+------------
 rag.enabled | true | 2025-08-29 | 2025-08-29
```

## How to Use

### Preparation

1. Make sure PostgreSQL container is running
2. Check database availability:

```bash
docker exec erni-ki-db-1 psql -U postgres -d openwebui -c "SELECT version();"
```

### Executing Scripts

```bash
# Method 1: Via docker exec
docker exec -i erni-ki-db-1 psql -U postgres -d openwebui < scripts/core/diagnostics/sql/analyze-openwebui-config.sql

# Method 2: Via psql client (if installed locally)
PGPASSWORD=your_password psql -h localhost -p 5432 -U postgres -d openwebui -f scripts/core/diagnostics/sql/analyze-openwebui-config.sql

# Method 3: Interactive mode
docker exec -it erni-ki-db-1 psql -U postgres -d openwebui
\i /path/to/analyze-openwebui-config.sql
```

## Interpreting Results

### RAG Settings

- `rag.enabled` - whether RAG is enabled
- `rag.template` - template for RAG queries
- `embedding.model` - embedding model

### Model Settings

- `models.default` - default model
- `models.available` - available models

### Integration Settings

- `searxng.url` - SearXNG service URL
- `ollama.url` - Ollama API URL

## Security

**Warning:** SQL scripts may contain sensitive information from the database.

- Do not run scripts on production without understanding their contents
- Results may contain passwords and API keys
- Use only for diagnostics and debugging

## Adding New Scripts

When adding new SQL scripts:

1. Place the file in this directory
2. Add description to this README.md
3. Use comments in SQL to explain logic
4. Test on a test database

### New Script Template:

```sql
-- Script description
-- Author: Author name
-- Date: YYYY-MM-DD

\echo '=== ANALYSIS TITLE ==='
SELECT
 column1,
 column2
FROM table_name
WHERE condition
ORDER BY column1;
```

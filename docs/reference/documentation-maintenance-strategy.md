---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-25'
---

# Стратегия поддержания актуальности документации

## Executive Summary

Документация должна быть живым артефактом, синхронизированным с кодом и
инфраструктурой. Эта стратегия определяет процессы, инструменты и практики для
автоматического и полуавтоматического поддержания документации в актуальном
состоянии.

**Ключевые принципы:**

- Documentation as Code
- Автоматизация извлечения данных из системы
- Интеграция с CI/CD
- Метрики качества документации
- Четкая ответственность (ownership)

---

## 1. Автоматическое извлечение данных из системы

### 1.1 Динамические данные из compose.yml

**Проблема:**Версии сервисов, количество контейнеров, конфигурация часто
меняются.

**Решение:**Автоматическое извлечение и обновление.

#### Скрипт: `scripts/docs/sync-system-info.py`

```python
# !/usr/bin/env python3
"""
Sync system information from compose.yml to documentation.
Run automatically in pre-commit or CI/CD.
"""

import yaml
import re
from pathlib import Path
from datetime import datetime

def extract_service_info(compose_file='compose.yml'):
    """Extract service information from docker-compose."""
    with open(compose_file) as f:
        compose = yaml.safe_load(f)

    services = compose.get('services', {})

    info = {
        'total_services': len(services),
        'services_by_category': {},
        'versions': {},
        'ports': {},
        'updated': datetime.now().strftime('%Y-%m-%d')
    }

    # Категоризация сервисов
    categories = {
        'ai': ['ollama', 'openwebui', 'litellm', 'mcp-server'],
        'monitoring': ['prometheus', 'grafana', 'loki', 'alertmanager', 'fluent-bit'],
        'data': ['postgres', 'redis', 'pgvector'],
        'infrastructure': ['nginx', 'watchtower'],
        'rag': ['searxng', 'docling', 'tika', 'edgetts'],
        'exporters': [s for s in services if 'exporter' in s]
    }

    for category, patterns in categories.items():
        matched = []
        for service in services:
            if any(p in service.lower() for p in patterns):
                matched.append(service)
                # Извлечь версию из image
                image = services[service].get('image', '')
                if ':' in image:
                    version = image.split(':')[1]
                    info['versions'][service] = version
        info['services_by_category'][category] = matched

    return info

def update_status_snippet(info):
    """Update status snippet with current system info."""
    template = f"""
>**Статус системы ({info['updated']}) — Production Ready**
>
> - Контейнеры: {info['total_services']} services
> - AI: {', '.join(info['services_by_category'].get('ai', []))}
> - Мониторинг: {', '.join(info['services_by_category'].get('monitoring', []))}
> - Данные: {', '.join(info['services_by_category'].get('data', []))}
    """

    # Обновить в README.md, docs/index.md, etc.
    files_to_update = [
        'README.md',
        'docs/index.md',
        'docs/de/index.md',
        'docs/en/index.md'
    ]

    for file_path in files_to_update:
        if Path(file_path).exists():
            content = Path(file_path).read_text()
            # Заменить между маркерами
            pattern = r'<!-- STATUS_SNIPPET_START -->.*?<!-- STATUS_SNIPPET_END -->'
            replacement = f'<!-- STATUS_SNIPPET_START -->\n{template}\n<!-- STATUS_SNIPPET_END -->'
            updated = re.sub(pattern, replacement, content, flags=re.DOTALL)
            Path(file_path).write_text(updated)
            print(f"Updated {file_path}")

def update_service_inventory(info):
    """Update service inventory documentation."""
    inventory_file = 'docs/architecture/service-inventory.md'

    # Читаем template
    template = Path('docs/templates/service-inventory.template.md').read_text()

    # Заполняем данными
    services_table = "| Сервис | Версия | Категория | Порты |\n|--------|--------|-----------|-------|\n"

    for category, services in info['services_by_category'].items():
        for service in services:
            version = info['versions'].get(service, 'latest')
            services_table += f"| {service} | {version} | {category} | - |\n"

    content = template.replace('{{SERVICES_TABLE}}', services_table)
    content = content.replace('{{UPDATED}}', info['updated'])

    Path(inventory_file).write_text(content)
    print(f"Updated {inventory_file}")

if __name__== '__main__':
    print("Syncing system information from compose.yml...")
    info = extract_service_info()
    update_status_snippet(info)
    update_service_inventory(info)
    print("Done!")
```

#### Автоматизация

```yaml
# .github/workflows/sync-docs.yml
name: Sync Documentation

on:
  push:
    paths:
      - 'compose.yml'
      - 'env/**'
      - 'conf/**'
    branches:
      - main
      - develop

jobs:
  sync-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Sync system info
        run: python3 scripts/docs/sync-system-info.py

      - name: Check for changes
        id: changes
        run: |
          git diff --quiet || echo "has_changes=true" >> $GITHUB_OUTPUT

      - name: Create PR
        if: steps.changes.outputs.has_changes == 'true'
        uses: peter-evans/create-pull-request@v5
        with:
          title: 'docs: auto-sync system info from compose.yml'
          body: |
            Автоматическое обновление документации на основе изменений в:
            - compose.yml
            - Конфигурационных файлах

            Изменения:
            - Обновлены версии сервисов
            - Обновлен service inventory
            - Обновлены status snippets
          branch: docs/auto-sync
          delete-branch: true
```

### 1.2 Мониторинг метрик из Prometheus

**Цель:**Автоматически обновлять статистику в документации.

#### Скрипт: `scripts/docs/update-metrics.py`

```python
# !/usr/bin/env python3
"""Extract current metrics from Prometheus and update docs."""

import requests
from datetime import datetime

def get_prometheus_metrics(prometheus_url='http://localhost:9090'):
    """Query Prometheus for current system metrics."""
    queries = {
        'targets_up': 'count(up == 1)',
        'targets_total': 'count(up)',
        'containers_running': 'count(container_last_seen)',
        'memory_usage': 'sum(container_memory_usage_bytes) / 1024^3',
        'disk_usage': '100 - (node_filesystem_avail_bytes / node_filesystem_size_bytes * 100)',
    }

    metrics = {}
    for name, query in queries.items():
        try:
            response = requests.get(
                f'{prometheus_url}/api/v1/query',
                params={'query': query},
                timeout=5
            )
            result = response.json()
            if result['status'] == 'success':
                metrics[name] = result['data']['result'][0]['value'][1]
        except Exception as e:
            print(f"Warning: Failed to get {name}: {e}")
            metrics[name] = 'N/A'

    return metrics

def update_operations_docs(metrics):
    """Update operations documentation with current metrics."""
    doc_file = 'docs/operations/core/status-page.md'

    # Обновить метрики в документации
    # Использовать шаблоны или маркеры для замены
    pass

if __name__== '__main__':
    metrics = get_prometheus_metrics()
    update_operations_docs(metrics)
```

---

## 2. Процессы и Workflows

### 2.1 Definition of Done для изменений

**Любое изменение кода/инфраструктуры должно включать:**

```markdown
## Documentation Checklist (обязательно)

- [ ] README.md обновлен (если изменился setup)
- [ ] API Reference обновлен (если изменился API)
- [ ] Configuration Guide обновлен (если новые env переменные)
- [ ] Architecture docs обновлены (если изменилась структура)
- [ ] CHANGELOG.md обновлен
- [ ] Migration guide создан (если breaking changes)
```

#### PR Template с проверкой документации

```markdown
<!-- .github/pull_request_template.md -->

## Changes

Brief description of changes...

## Documentation Impact

**Тип изменения:**

- [ ] New Feature → требует обновления User Guide + API Reference
- [ ] Bug Fix → требует обновления Troubleshooting Guide
- [ ] Infrastructure Change → требует обновления Architecture docs
- [ ] Configuration Change → требует обновления Configuration Guide
- [ ] No documentation impact

**Документация обновлена:**

- [ ] docs/path/to/updated/file.md
- [ ] CHANGELOG.md

**Если не обновлена, объясните почему:**

## Testing

- [ ] Документация проверена локально (mkdocs serve)
- [ ] Все ссылки работают
- [ ] Скриншоты/диаграммы актуальны
```

### 2.2 Автоматическая проверка в CI

```yaml
# .github/workflows/docs-quality.yml
name: Documentation Quality

on: [pull_request]

jobs:
  check-docs-updated:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Check if docs updated with code
        run: |
          # Проверить, изменились ли код файлы
          CODE_CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -E '\.(py|ts|go|yml)$' || true)

          # Проверить, изменилась ли документация
          DOCS_CHANGED=$(git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -E '^docs/.*\.md$' || true)

          if [ -n "$CODE_CHANGED" ] && [ -z "$DOCS_CHANGED" ]; then
            echo "::warning::Code changed but no documentation updates found"
            echo "Consider updating relevant documentation"
          fi

      - name: Check CHANGELOG updated
        run: |
          if ! git diff --name-only origin/${{ github.base_ref }}...HEAD | grep -q CHANGELOG.md; then
            echo "::warning::CHANGELOG.md not updated"
          fi

      - name: Verify no broken links
        run: |
          npm install -g markdown-link-check
          find docs -name "*.md" -exec markdown-link-check {} \;

      - name: Check documentation freshness
        run: python3 scripts/docs/check-freshness.py
```

### 2.3 Scheduled Reviews

```yaml
# .github/workflows/docs-review.yml
name: Quarterly Docs Review

on:
  schedule:
    # Каждый первый понедельник квартала в 9:00
    - cron: '0 9 1 1,4,7,10 1'
  workflow_dispatch:

jobs:
  create-review-issue:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Generate documentation report
        run: python3 scripts/docs/generate-review-report.py > report.md

      - name: Create review issue
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const report = fs.readFileSync('report.md', 'utf8');

            github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Quarterly Documentation Review - ' + new Date().toISOString().slice(0,7),
              body: report,
              labels: ['documentation', 'review', 'quarterly']
            });
```

---

## 3. Метрики и мониторинг документации

### 3.1 Метрики качества

#### Скрипт: `scripts/docs/check-freshness.py`

````python
# !/usr/bin/env python3
"""Check documentation freshness and quality metrics."""

import re
from pathlib import Path
from datetime import datetime, timedelta
import yaml

def check_doc_freshness():
    """Check how old documentation files are."""
    docs_dir = Path('docs')
    now = datetime.now()

    metrics = {
        'total_docs': 0,
        'stale_docs': [],  # > 90 days
        'very_stale_docs': [],  # > 180 days
        'outdated_docs': [],  # > 365 days
        'missing_last_updated': []
    }

    for md_file in docs_dir.rglob('*.md'):
        if 'archive' in str(md_file):
            continue

        metrics['total_docs'] += 1

        content = md_file.read_text()
        match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)

        if not match:
            metrics['missing_last_updated'].append(str(md_file))
            continue

        frontmatter = yaml.safe_load(match.group(1))
        last_updated = frontmatter.get('last_updated')

        if not last_updated:
            metrics['missing_last_updated'].append(str(md_file))
            continue

        # Парсинг даты
        updated_date = datetime.strptime(last_updated, '%Y-%m-%d')
        age_days = (now - updated_date).days

        if age_days > 365:
            metrics['outdated_docs'].append((str(md_file), age_days))
        elif age_days > 180:
            metrics['very_stale_docs'].append((str(md_file), age_days))
        elif age_days > 90:
            metrics['stale_docs'].append((str(md_file), age_days))

    return metrics

def check_doc_quality():
    """Check documentation quality indicators."""
    docs_dir = Path('docs')

    quality = {
        'docs_without_examples': [],
        'short_docs': [],  # < 100 words
        'docs_without_links': [],
        'docs_with_todos': []
    }

    for md_file in docs_dir.rglob('*.md'):
        if 'archive' in str(md_file):
            continue

        content = md_file.read_text()

        # Убрать frontmatter
        content_no_fm = re.sub(r'^---.*?---\s*', '', content, flags=re.DOTALL)

        # Подсчет слов
        word_count = len(content_no_fm.split())
        if word_count < 100:
            quality['short_docs'].append((str(md_file), word_count))

        # Проверка на примеры кода
        if '```' not in content:
            # Если это не howto/tutorial, это может быть ок
            if 'howto' in str(md_file) or 'tutorial' in str(md_file):
                quality['docs_without_examples'].append(str(md_file))

        # Проверка на внутренние ссылки
        if not re.search(r'\[.+?\]\(.+?\.md.*?\)', content):
            quality['docs_without_links'].append(str(md_file))

        # Проверка на TODO/FIXME
        if re.search(r'\bTODO\b|\bFIXME\b', content):
            quality['docs_with_todos'].append(str(md_file))

    return quality

def generate_report():
    """Generate comprehensive documentation quality report."""
    freshness = check_doc_freshness()
    quality = check_doc_quality()

    report = f"""
# Documentation Quality Report
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}

## Freshness Metrics

- Total documents: {freshness['total_docs']}
- Stale (>90 days): {len(freshness['stale_docs'])}
- Very stale (>180 days): {len(freshness['very_stale_docs'])}
- Outdated (>365 days): {len(freshness['outdated_docs'])}
- Missing last_updated: {len(freshness['missing_last_updated'])}

### Action Required

**Outdated docs (>1 year):**
"""
    for doc, age in sorted(freshness['outdated_docs'], key=lambda x: x[1], reverse=True)[:10]:
        report += f"\n- {doc} ({age} days old)"

    report += f"""

## Quality Metrics

- Short docs (<100 words): {len(quality['short_docs'])}
- Docs without code examples: {len(quality['docs_without_examples'])}
- Docs without links: {len(quality['docs_without_links'])}
- Docs with TODOs: {len(quality['docs_with_todos'])}

### Recommendations

**Expand these short docs:**
"""
    for doc, words in sorted(quality['short_docs'], key=lambda x: x[1])[:5]:
        report += f"\n- {doc} ({words} words)"

    return report

if __name__== '__main__':
    report = generate_report()
    print(report)

    # Exit with error if critical issues
    freshness = check_doc_freshness()
    if len(freshness['outdated_docs']) > 10:
        print("\nERROR: Too many outdated docs (>10)")
        exit(1)
````

### 3.2 Dashboard метрик документации

Интеграция с Grafana для отслеживания:

```json
{
  "dashboard": {
    "title": "Documentation Quality",
    "panels": [
      {
        "title": "Documentation Freshness",
        "targets": [{ "expr": "docs_age_days", "legendFormat": "{{file}}" }]
      },
      {
        "title": "Coverage by Language",
        "targets": [
          {
            "expr": "docs_coverage_percent{lang='en'}",
            "legendFormat": "English"
          },
          {
            "expr": "docs_coverage_percent{lang='de'}",
            "legendFormat": "Deutsch"
          }
        ]
      }
    ]
  }
}
```

Экспортер метрик:

```python
# scripts/monitoring/docs-exporter.py
from prometheus_client import Gauge, start_http_server
import time

# Метрики
docs_total = Gauge('docs_total_count', 'Total documentation files')
docs_stale = Gauge('docs_stale_count', 'Stale documentation files')
docs_coverage = Gauge('docs_coverage_percent', 'Documentation coverage', ['lang'])

def collect_metrics():
    """Collect and expose documentation metrics."""
    freshness = check_doc_freshness()

    docs_total.set(freshness['total_docs'])
    docs_stale.set(len(freshness['stale_docs']))

    # Coverage по языкам
    docs_coverage.labels(lang='en').set(calculate_coverage('en'))
    docs_coverage.labels(lang='de').set(calculate_coverage('de'))

if __name__== '__main__':
    start_http_server(9101)
    while True:
        collect_metrics()
        time.sleep(3600)  # Update every hour
```

---

## 4. Ownership и ответственность

### 4.1 CODEOWNERS для документации

```
# .github/CODEOWNERS

# Documentation
/docs/**@docs-team
/docs/reference/**@docs-team @dev-team
/docs/architecture/**@architects
/docs/operations/**@ops-team
/docs/security/**@security-team
/docs/academy/**@product-team

# Auto-generated docs - require automation approval
/docs/architecture/service-inventory.md    @automation
```

### 4.2 Ротация ответственности

```markdown
## Documentation Rotation Schedule

| Quarter | Primary | Secondary | Focus Area         |
| ------- | ------- | --------- | ------------------ |
| Q1 2026 | Alice   | Bob       | Architecture docs  |
| Q2 2026 | Bob     | Charlie   | Operations guides  |
| Q3 2026 | Charlie | Alice     | User documentation |
| Q4 2026 | Alice   | Bob       | Security docs      |

**Responsibilities:**

- Weekly: Review и merge docs PRs
- Monthly: Freshness check
- Quarterly: Comprehensive audit
```

---

## 5. Инструменты и автоматизация

### 5.1 Pre-commit hooks расширенные

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    # Проверка актуальности документации
    - id: check-docs-sync
      name: 'Docs: check if system info is synced'
      entry: python3 scripts/docs/check-sync.py
      language: python
      pass_filenames: false
      files: compose\.yml

    # Проверка свежести документации
    - id: check-docs-freshness
      name: 'Docs: warn about stale docs'
      entry: python3 scripts/docs/check-freshness.py
      language: python
      pass_filenames: false

    # Проверка полноты документации
    - id: check-docs-completeness
      name: 'Docs: check completeness'
      entry: python3 scripts/docs/check-completeness.py
      language: python
      files: ^docs/.*\.md$
```

### 5.2 Шаблоны документов

````markdown
## <!-- docs/templates/service-doc.template.md -->

language: ru translation_status: pending doc_version: '2025.11' last_updated:
'YYYY-MM-DD' service_name: 'SERVICE_NAME' service_version: 'VERSION'

---

# Сервис: {{SERVICE_NAME}}

## Обзор

**Версия:**{{VERSION}}**Статус:**{{STATUS}}**Категория:**{{CATEGORY}}

## Конфигурация

### Environment Variables

| Переменная   | Описание        | По умолчанию | Обязательна  |
| ------------ | --------------- | ------------ | ------------ |
| {{VAR_NAME}} | {{DESCRIPTION}} | {{DEFAULT}}  | {{REQUIRED}} |

### Ports

| Порт     | Протокол     | Описание        |
| -------- | ------------ | --------------- |
| {{PORT}} | {{PROTOCOL}} | {{DESCRIPTION}} |

## Мониторинг

### Metrics

- `{{METRIC_NAME}}`: {{DESCRIPTION}}

### Health Checks

- Endpoint: `{{HEALTH_ENDPOINT}}`
- Expected: `{{EXPECTED_RESPONSE}}`

## Troubleshooting

### Типичные проблемы

#### {{PROBLEM_TITLE}}

**Симптомы:**

- {{SYMPTOM}}

**Решение:**

```bash
{{SOLUTION_COMMANDS}}
```
````

## См. также

- [Architecture Overview](../architecture/architecture.md)
- [Monitoring Guide](../operations/monitoring/monitoring-guide.md)

````

### 5.3 Автогенерация из кода

```python
# scripts/docs/generate-api-docs.py
"""Auto-generate API documentation from OpenAPI specs."""

import yaml
from pathlib import Path

def generate_api_docs(openapi_file):
    """Generate markdown docs from OpenAPI specification."""
    with open(openapi_file) as f:
        spec = yaml.safe_load(f)

    docs = f"""---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '{datetime.now().strftime("%Y-%m-%d")}'
auto_generated: true
source: '{openapi_file}'
---

# API Reference: {spec['info']['title']}

**Version:**{spec['info']['version']}
**Base URL:**{spec['servers'][0]['url']}

## Endpoints

"""

    for path, methods in spec['paths'].items():
        for method, details in methods.items():
            docs += f"\n### {method.upper()} {path}\n\n"
            docs += f"{details.get('summary', '')}\n\n"
            docs += f"**Description:**{details.get('description', '')}\n\n"

            # Parameters
            if 'parameters' in details:
                docs += "**Parameters:**\n\n"
                docs += "| Name | Type | Required | Description |\n"
                docs += "|------|------|----------|-------------|\n"
                for param in details['parameters']:
                    docs += f"| {param['name']} | {param.get('schema', {}).get('type', 'string')} | {param.get('required', False)} | {param.get('description', '')} |\n"

    return docs

if __name__== '__main__':
    # Auto-generate API docs
    api_specs = Path('docs/api').glob('*.yaml')
    for spec in api_specs:
        docs = generate_api_docs(spec)
        output_file = spec.with_suffix('.md')
        output_file.write_text(docs)
        print(f"Generated {output_file}")
````

---

## 6. Версионирование документации

### 6.1 Стратегия версий

```
docs/
  current/          # Текущая версия (main branch)
  v12.0/           # Stable release
  v11.0/           # Previous stable
  next/            # Development (develop branch)
```

### 6.2 Mike для версионирования MkDocs

```yaml
# mkdocs.yml
extra:
  version:
    provider: mike
    default: stable
# Деплой версий
# mike deploy v12.0 stable --update-aliases
# mike deploy v13.0 latest --update-aliases
# mike set-default stable
```

```bash
# scripts/docs/deploy-versioned.sh
# !/bin/bash
# Deploy versioned documentation

VERSION=$(grep "system_version:" docs/VERSION.md | cut -d"'" -f2)

# Deploy new version
mike deploy "v${VERSION}" latest --update-aliases --push

# Set as stable if release
if [[ $GITHUB_REF == refs/tags/v* ]]; then
  mike deploy "v${VERSION}" stable --update-aliases --push
  mike set-default stable --push
fi
```

---

## 7. Интеграция с Development Workflow

### 7.1 Feature Development

```
1. Developer создает feature branch
2. Пишет код + обновляет документацию
3. Pre-commit проверяет:
   - Синхронизацию версий
   - Наличие обновлений в docs/
   - Broken links
4. CI проверяет:
   - Build документации
   - Freshness warnings
   - Coverage
5. Review включает проверку документации
6. Merge → автоматически деплоится в docs/next/
```

### 7.2 Release Process

```
1. Release branch создается
2. Автоматически:
   - Обновляются версии из compose.yml
   - Генерируется CHANGELOG
   - Обновляется service inventory
3. Manual review:
   - Migration guides
   - Breaking changes docs
   - Обновление примеров
4. Tag создается → docs деплоятся как stable version
```

---

## 8. Метрики успеха

### 8.1 KPI документации

| Метрика          | Текущее | Цель               | Измерение     |
| ---------------- | ------- | ------------------ | ------------- |
| Freshness        | -       | >90% docs <90 days | Автоматически |
| Coverage EN      | 25%     | 80%                | Автоматически |
| Coverage DE      | 88%     | 95%                | Автоматически |
| Broken links     | 57      | 0                  | CI/CD         |
| Auto-sync        | 0%      | 80%                | Script count  |
| Review frequency | ?       | Quarterly          | Calendar      |

### 8.2 Качественные метрики

-**Time to find info**: Время, за которое новый разработчик находит нужную
информацию -**Documentation usefulness**: Опросы команды (quarterly) -**Outdated
reports**: Количество issues о неактуальной документации -**PR docs
compliance**: % PR с обновленной документацией

---

## 9. Continuous Improvement

### 9.1 Feedback Loop

```markdown
## Documentation Feedback Process

1.**Collect:**

- GitHub Issues с label `documentation`
- Survey after onboarding
- PR comments о документации

  2.**Analyze:**

- Monthly review of feedback
- Identify patterns
- Prioritize improvements

  3.**Act:**

- Update documentation
- Improve processes
- Enhance automation

  4.**Measure:**

- Track metrics
- Compare before/after
- Report improvements
```

### 9.2 Retrospectives

```markdown
## Quarterly Documentation Retrospective

**Agenda:**

1. Review metrics (30 min)
   - Freshness, coverage, quality
   - CI/CD effectiveness
   - Automation gaps

2. Team feedback (30 min)
   - What's working well?
   - What's painful?
   - What's missing?

3. Action items (30 min)
   - Top 3 improvements
   - Assign owners
   - Set deadlines

**Output:**

- Updated strategy (if needed)
- Backlog of improvements
- Updated automation
```

---

## 10. Приложения

### A. Checklist для нового сервиса

```markdown
## Documentation Checklist for New Service

При добавлении нового сервиса в compose.yml:

- [ ] Создать docs/services/{{SERVICE_NAME}}.md
- [ ] Обновить docs/architecture/service-inventory.md
- [ ] Обновить docs/architecture/architecture.md (диаграмма)
- [ ] Добавить в соответствующий раздел (AI/Monitoring/Data)
- [ ] Документировать env переменные
- [ ] Документировать ports
- [ ] Добавить monitoring/health checks
- [ ] Добавить troubleshooting секцию
- [ ] Обновить docker-compose setup guide
- [ ] Запустить scripts/docs/sync-system-info.py
```

### B. Checklist для breaking change

```markdown
## Breaking Change Documentation Checklist

- [ ] Создать migration guide: docs/migrations/v{{VERSION}}.md
- [ ] Обновить CHANGELOG.md с BREAKING CHANGE секцией
- [ ] Обновить все affected guides
- [ ] Добавить deprecation warnings в старые docs
- [ ] Создать comparison table (old vs new)
- [ ] Обновить примеры кода
- [ ] Record video walkthrough (опционально)
- [ ] Notify team в Slack #announcements
```

### C. Monthly Documentation Tasks

```markdown
## Monthly Documentation Maintenance

**Week 1:**

- [ ] Run freshness check
- [ ] Update top 5 stale docs
- [ ] Review и merge pending docs PRs

**Week 2:**

- [ ] Verify auto-sync working
- [ ] Check metrics dashboard
- [ ] Address documentation issues

**Week 3:**

- [ ] Review translation status
- [ ] Update service inventory
- [ ] Check broken links

**Week 4:**

- [ ] Generate monthly report
- [ ] Plan next month
- [ ] Update automation scripts
```

---

## Заключение

Эта стратегия обеспечивает:

1.**Автоматизацию**: 80% обновлений происходят автоматически 2.**Качество**:
Continuous monitoring и metrics 3.**Ownership**: Четкая
ответственность 4.**Процесс**: Интегрировано в development
workflow 5.**Масштабируемость**: Растет вместе с проектом

**Следующие шаги:**

1. Внедрить базовые скрипты (sync-system-info, check-freshness)
2. Настроить CI/CD workflows
3. Обучить команду новым процессам
4. Запустить метрики и dashboard
5. Провести первый quarterly review

---

**Версия стратегии:**1.0**Дата:**2025-11-25**Следующий review:**2026-02-25

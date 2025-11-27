---
language: ru
translation_status: original
doc_version: '2025.11'
last_updated: '2025-11-27'
category: operations
priority: critical
---

# Security Action Plan - ERNI-KI

**Дата создания:** 2025-11-27 **Статус:** ACTIVE **Приоритет:** CRITICAL
**Основание:**
[Comprehensive System Audit 2025-11-27](../reports/comprehensive-system-audit-2025-11-27.md)

---

## Executive Summary

Выявлены **критические уязвимости безопасности** (CVSS 6.5-10.0), требующие
немедленного устранения. Данный план определяет приоритетные действия и
ответственных.

**Статус блокировки production:** BLOCKED (до выполнения Phase 1)

---

## Phase 1: Критические фиксы (1-3 дня)

### Task 1.1: Удалить секреты из Git (CVSS 10.0)

**Приоритет:** P0 - CRITICAL **Сроки:** 1 день **Ответственный:** DevOps Lead
**Статус:** ⚠️ TO DO

**Проблема:**

```bash
secrets/
├── postgres_password.txt      # PLAIN TEXT В GIT!
├── litellm_api_key.txt        # PLAIN TEXT В GIT!
├── openai_api_key.txt         # PLAIN TEXT В GIT!
└── grafana_admin_password.txt # Weak: "admin"
```

**Действия:**

1. **Установить git-filter-repo**

```bash
pip install git-filter-repo
```

2. **Удалить секреты из истории Git**

```bash
# Бэкап репозитория
cp -r .git .git.backup

# Удалить secrets/ и env/ из истории
git filter-repo --invert-paths \
  --path secrets/ \
  --path env/ \
  --force

# Проверить результат
git log --all --full-history -- secrets/
```

3. **Force push (КООРДИНИРОВАТЬ С КОМАНДОЙ!)**

```bash
# Уведомить всех разработчиков
# Затем:
git push --force --all
git push --force --tags
```

4. **Ротация ВСЕХ скомпрометированных секретов**

```bash
# PostgreSQL
psql -U postgres -c "ALTER USER postgres PASSWORD '$(openssl rand -base64 32)';"

# Redis
redis-cli CONFIG SET requirepass "$(openssl rand -base64 32)"

# LiteLLM, OpenAI - регенерация API keys в консолях
```

5. **Создать .example файлы**

```bash
for file in secrets/*.txt; do
  echo "PLACEHOLDER_$(basename $file)" > "$file.example"
done

git add secrets/*.example
git commit -m "security: add secret templates"
```

6. **Обновить .gitignore**

```bash
echo "secrets/*.txt" >> .gitignore
echo "env/*.env" >> .gitignore
git add .gitignore
git commit -m "security: ignore secrets and env files"
```

**Критерии завершения:**

- [ ] История Git не содержит secrets/
- [ ] Все секреты ротированы
- [ ] .example файлы созданы
- [ ] .gitignore обновлен
- [ ] Команда уведомлена

---

### Task 1.2: Закрыть Uptime Kuma (CVSS 6.5)

**Приоритет:** P0 - CRITICAL **Сроки:** 1 час **Ответственный:** DevOps Engineer
**Статус:** ⚠️ TO DO

**Проблема:**

```yaml
uptime-kuma:
  ports:
    - '3001:3001' # Открыт для всей сети!
```

**Действие:**

```yaml
uptime-kuma:
  ports:
    - '127.0.0.1:3001:3001' # Localhost only
```

**Шаги:**

1. Редактировать compose.yml
2. `docker compose up -d uptime-kuma`
3. Проверить доступность только с localhost

**Критерии завершения:**

- [ ] порт bind к 127.0.0.1
- [ ] `curl http://localhost:3001` - ОК
- [ ] `curl http://192.168.x.x:3001` - FAIL

---

### Task 1.3: Исправить Watchtower user (CVSS 7.8)

**Приоритет:** P0 - CRITICAL **Сроки:** 1 час **Ответственный:** DevOps Engineer
**Статус:** ⚠️ TO DO

**Проблема:**

```yaml
watchtower:
  user: '0' # root UID
```

**Действие:**

```yaml
watchtower:
  user: '${DOCKER_GID:-999}:${DOCKER_GID:-999}'
```

**Шаги:**

1. Получить GID группы docker

```bash
getent group docker | cut -d: -f3
# Добавить в .env: DOCKER_GID=999
```

2. Обновить compose.yml
3. `docker compose up -d watchtower`
4. Проверить, что Watchtower работает

**Критерии завершения:**

- [ ] user не root
- [ ] Watchtower успешно обновляет контейнеры
- [ ] Логи не содержат permission denied

---

### Task 1.4: Добавить ShellCheck в CI (P1)

**Приоритет:** P1 - HIGH **Сроки:** 1 день **Ответственный:** DevOps Engineer
**Статус:** ⚠️ TO DO

**Проблема:** 110 shell скриптов без статического анализа

**Действия:**

1. **Добавить в .pre-commit-config.yaml**

```yaml
- repo: https://github.com/koalaman/shellcheck-precommit
  rev: v0.9.0
  hooks:
    - id: shellcheck
      args: ['--severity=warning']
```

2. **Добавить в CI**

```yaml
# .github/workflows/ci.yml
- name: ShellCheck
  run: |
    find . -name "*.sh" -not -path "./node_modules/*" | xargs shellcheck
```

3. **Исправить критические issues**

```bash
shellcheck scripts/**/*.sh conf/**/*.sh | grep "error:"
```

**Критерии завершения:**

- [ ] ShellCheck в pre-commit
- [ ] ShellCheck в CI
- [ ] 0 critical issues

---

## Phase 2: Высокоприоритетные (1-2 недели)

### Task 2.1: Network Segmentation (P1)

**Приоритет:** P1 - HIGH **Сроки:** 1 неделя **Ответственный:** DevOps Lead
**Статус:** ⚠️ TO DO

**Цель:** Изолировать сервисы по функциональным слоям

**Дизайн:**

```yaml
networks:
  frontend:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
  backend:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.21.0.0/24
  data:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.22.0.0/24
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/24
```

**Маппинг сервисов:**

```yaml
# Frontend (public-facing)
- nginx: [frontend]
- cloudflared: [frontend]

# AI Layer
- openwebui: [frontend, backend]
- litellm: [backend]
- ollama: [backend]

# Data Layer
- postgres: [data]
- redis: [data]
- backrest: [data]

# Monitoring
- prometheus: [monitoring, backend]
- grafana: [monitoring]
- exporters: [monitoring, backend/data]
```

**Критерии завершения:**

- [ ] 4 сети созданы
- [ ] Все сервисы назначены
- [ ] internal: true для backend/data
- [ ] Тестирование connectivity

---

### Task 2.2: Модуляризация compose.yml (P1)

**Приоритет:** P1 - HIGH **Сроки:** 2 недели **Ответственный:** DevOps Engineer
**Статус:** ⚠️ TO DO

**Цель:** Разделить 1276-строчный монолит

**Структура:**

```
compose/
├── base.yml           # Networks, volumes, logging anchors
├── ai-services.yml    # OpenWebUI, Ollama, LiteLLM, Docling
├── data-services.yml  # PostgreSQL, Redis, Backrest
├── monitoring.yml     # Prometheus, Grafana, Loki, exporters
├── infrastructure.yml # Nginx, Cloudflared, Auth, Watchtower
└── production.yml     # Production overrides
```

**Миграция:**

```bash
# Создать директорию
mkdir compose

# Разделить файл
# 1. base.yml - первые 50 строк + x-logging
# 2. ai-services.yml - openwebui, ollama, litellm, docling
# ...

# Тестировать
docker compose -f compose/base.yml \
               -f compose/ai-services.yml \
               -f compose/data-services.yml \
               -f compose/monitoring.yml \
               -f compose/infrastructure.yml \
               -f compose/production.yml \
               config > test-compose.yml

# Сравнить с оригиналом
diff <(yq eval-all 'sort_keys(..)' compose.yml) \
     <(yq eval-all 'sort_keys(..)' test-compose.yml)
```

**Критерии завершения:**

- [ ] 6 модулей созданы
- [ ] `docker compose config` работает
- [ ] Нет различий с оригиналом
- [ ] README обновлен

---

### Task 2.3: Integration Tests (P2)

**Приоритет:** P2 - MEDIUM **Сроки:** 2 недели **Ответственный:** QA Engineer
**Статус:** ⚠️ TO DO

**Цель:** Покрыть критические integration flows

**Test cases:**

1. **OpenWebUI → LiteLLM → Ollama flow**

```typescript
// tests/integration/ai-pipeline.test.ts
describe('AI Pipeline Integration', () => {
  it('should handle chat request end-to-end', async () => {
    const response = await fetch('http://openwebui:8080/api/chat', {
      method: 'POST',
      body: JSON.stringify({
        model: 'llama3',
        messages: [{ role: 'user', content: 'test' }],
      }),
    });
    expect(response.ok).toBe(true);
    expect(await response.json()).toMatchObject({
      message: { content: expect.any(String) },
    });
  });
});
```

2. **Auth service JWT validation**
3. **Prometheus scraping all targets**
4. **Fluent Bit → Loki log ingestion**

**Критерии завершения:**

- [ ] 10+ integration tests
- [ ] CI pipeline интеграция
- [ ] Coverage report

---

## Phase 3: Среднеприоритетные (1 месяц)

### Task 3.1: SOPS для секретов (P2)

**Приоритет:** P2 - MEDIUM **Сроки:** 1 месяц **Ответственный:** DevOps Lead
**Статус:** ⚠️ TO DO

**Цель:** Шифрование секретов at rest

**Внедрение:**

1. **Установить SOPS**

```bash
brew install sops  # или apt-get install sops
```

2. **Создать GPG ключ для команды**

```bash
gpg --batch --generate-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: ERNI-KI DevOps
Name-Email: devops@erni-gruppe.ch
Expire-Date: 2y
EOF

# Экспорт публичного ключа
gpg --export --armor "ERNI-KI DevOps" > .sops.pub
```

3. **Конфигурация SOPS**

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.txt$
    pgp: >-
      FBC7B9E2A4F9289AC0C1D4843D16CEE4A27381B4
```

4. **Зашифровать секреты**

```bash
for file in secrets/*.txt; do
  sops -e "$file" > "$file.enc"
  rm "$file"
done

git add secrets/*.enc
git commit -m "security: encrypt secrets with SOPS"
```

5. **Entrypoint wrapper**

```bash
#!/usr/bin/env bash
# scripts/entrypoints/sops-wrapper.sh
for secret_file in /run/secrets-encrypted/*; do
  secret_name=$(basename "$secret_file" .enc)
  sops -d "$secret_file" > "/run/secrets/$secret_name"
done

exec "$@"
```

**Критерии завершения:**

- [ ] SOPS настроен
- [ ] Все секреты зашифрованы
- [ ] Entrypoint работает
- [ ] Документация обновлена

---

### Task 3.2: JWT Rotation (P2)

**Приоритет:** P2 - MEDIUM **Сроки:** 1 месяц **Ответственный:** Backend
Developer **Статус:** ⚠️ TO DO

**Цель:** Автоматическая ротация JWT signing keys

**Дизайн:**

```go
// pkg/jwt/rotation.go
type KeyRotator struct {
  current  []byte
  previous []byte
  next     []byte
  mutex    sync.RWMutex
}

func (r *KeyRotator) Rotate() error {
  r.mutex.Lock()
  defer r.mutex.Unlock()

  r.previous = r.current
  r.current = r.next
  r.next = generateSecureKey()

  return r.persistKeys()
}

func (r *KeyRotator) Verify(token string) (Claims, error) {
  // Попытка верификации с current key
  claims, err := jwt.Parse(token, r.current)
  if err == nil {
    return claims, nil
  }

  // Fallback на previous key
  return jwt.Parse(token, r.previous)
}
```

**Критерии завершения:**

- [ ] KeyRotator реализован
- [ ] Ротация каждые 7 дней
- [ ] Поддержка 2 валидных ключей
- [ ] Unit tests
- [ ] Документация

---

### Task 3.3: Load Tests (P2)

**Приоритет:** P2 - MEDIUM **Сроки:** 1 месяц **Ответственный:** QA Engineer
**Статус:** ⚠️ TO DO

**Цель:** Определить capacity и bottlenecks

**Scenarios:**

1. **Chat completions load**

```javascript
// tests/load/chat.k6.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Warm-up
    { duration: '5m', target: 50 }, // Load
    { duration: '2m', target: 100 }, // Stress
    { duration: '5m', target: 0 }, // Cool-down
  ],
  thresholds: {
    http_req_duration: ['p(99)<2000'], // 99% < 2s
    http_req_failed: ['rate<0.01'], // Error rate < 1%
  },
};

export default function () {
  const res = http.post(
    'https://ki.erni-gruppe.ch/api/chat',
    JSON.stringify({
      model: 'llama3',
      messages: [{ role: 'user', content: 'Hello' }],
    }),
    {
      headers: { 'Content-Type': 'application/json' },
    },
  );

  check(res, {
    'status is 200': r => r.status === 200,
    'response time < 2s': r => r.timings.duration < 2000,
  });
}
```

2. **RAG pipeline load**
3. **Prometheus query load**

**Критерии завершения:**

- [ ] 3 k6 scenarios
- [ ] Baseline metrics собраны
- [ ] Bottlenecks идентифицированы
- [ ] Performance report

---

## Phase 4: Долгосрочные (3-6 месяцев)

### Task 4.1: SLI/SLO Definition (P3)

**Приоритет:** P3 - LOW **Сроки:** 1 месяц **Ответственный:** SRE **Статус:** ⚠️
BACKLOG

**Цель:** Формализовать service level objectives

**SLI Definition:**

```yaml
# docs/operations/sli-slo.yml
slos:
  - name: API Availability
    sli: ratio of successful requests to total requests
    formula:
      (count(http_requests_total{code=~"2.."}) / count(http_requests_total)) *
      100
    target: 99.9%
    window: 30d
    error_budget: 43m per month

  - name: API Latency
    sli: p99 response time
    formula: histogram_quantile(0.99, http_request_duration_seconds_bucket)
    target: <1000ms
    window: 30d

  - name: Error Rate
    sli: ratio of 5xx responses
    formula:
      (sum(rate(http_requests_total{code=~"5.."}[5m])) /
      sum(rate(http_requests_total[5m]))) * 100
    target: <0.1%
    window: 30d
```

**Критерии завершения:**

- [ ] SLI defined для всех критических сервисов
- [ ] Prometheus rules созданы
- [ ] Grafana dashboard
- [ ] Runbooks

---

### Task 4.2: Kubernetes Migration (P4)

**Приоритет:** P4 - BACKLOG **Сроки:** 6 месяцев **Ответственный:** DevOps Lead
**Статус:** ⚠️ BACKLOG

**Цель:** Миграция с Docker Compose на Kubernetes

**Benefits:**

- Network Policies для изоляции
- HPA для автоскейлинга
- Rolling updates с zero downtime
- External Secrets Operator
- Service mesh (Istio)

**Этапы:**

1. **Proof of Concept (1 месяц)**
2. **Helm charts разработка (2 месяца)**
3. **Staging migration (1 месяц)**
4. **Production migration (2 месяца)**

**Критерии завершения:**

- [ ] POC успешен
- [ ] Helm charts готовы
- [ ] Staging работает
- [ ] Production мигрирован

---

## Tracking

### Overall Progress

- Phase 1: 0/4 (0%)
- Phase 2: 0/3 (0%)
- Phase 3: 0/3 (0%)
- Phase 4: 0/2 (0%)

**TOTAL: 0/12 (0%)**

### Milestones

- [ ] **Milestone 1:** Критические фиксы (Week 1)
- [ ] **Milestone 2:** Production unblocked (Week 2)
- [ ] **Milestone 3:** Network segmentation (Week 4)
- [ ] **Milestone 4:** SOPS + JWT rotation (Month 2)
- [ ] **Milestone 5:** Load tests + SLI/SLO (Month 3)

---

## Ответственные

| Роль              | Имя | Задачи             |
| ----------------- | --- | ------------------ |
| DevOps Lead       | TBD | 1.1, 2.1, 3.1      |
| DevOps Engineer   | TBD | 1.2, 1.3, 1.4, 2.2 |
| Backend Developer | TBD | 3.2                |
| QA Engineer       | TBD | 2.3, 3.3           |
| SRE               | TBD | 4.1                |

---

## Коммуникация

### Weekly Status Updates

- Каждый понедельник в 10:00
- Slack: #erni-ki-security
- Формат: Task ID, Status, Blockers

### Escalation Path

- P0 issues: Немедленно в Slack + email DevOps Lead
- P1 issues: Daily standup
- P2+ issues: Weekly status update

---

## Ссылки

- [Comprehensive System Audit](../reports/comprehensive-system-audit-2025-11-27.md)
- [Security Checklist](../security/security-checklist.md)
- [Runbooks](core/runbooks-summary.md)

---

**Статус:** ACTIVE **Следующий review:** 2025-12-04

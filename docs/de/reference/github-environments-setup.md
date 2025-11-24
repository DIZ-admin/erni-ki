---
language: de
translation_status: in_progress
doc_version: '2025.11'
---

# GitHub Environments Setup (Kurzfassung)

## Zweck

Sichere Deployments über GitHub Environments mit Secrets/Approvals.

## Basis-Konzept

- **Environments**: z.B. `dev`, `staging`, `prod`
- **Secrets/Vars**: pro Environment hinterlegt (nicht im Repo)
- **Branch Protection**: nur bestimmte Branches dürfen deployen
- **Approvals**: manuelle Freigabe vor Prod-Deploys

## Einrichtung

1. **Environment anlegen**
   - GitHub → Settings → Environments → New environment (`staging`, `prod`)

2. **Secrets & Vars hinterlegen** (Beispiele)
   - `PROD_LITELLM_API_KEY`
   - `PROD_MCP_TOKEN`
   - `PROD_OLLAМА_URL`
   - `PROD_DOMAIN`

3. **Branch Protection / Rules**
   - Nur `main`/`release/*` dürfen auf `prod`
   - Reviewer erforderlich (2+) für `prod`

4. **Workflow anpassen** (`.github/workflows/deploy-environments.yml`)
   - `environment: prod`
   - `secrets: inherit`
   - Stufen: build → test → deploy

## Deployment-Flow (Beispiel)

```
on:
  workflow_dispatch:
  push:
    branches: [main]

jobs:
  deploy-prod:
    environment: prod
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build
      - name: Deploy
        run: ./scripts/deploy.sh
```

## Best Practices

- Secrets immer als Environment-Secrets, nicht als Repo-Secrets
- Prod-Deploy nur nach Tests/Approvals
- Logs/Artifacts für Audits aufbewahren
- Für Self-Hosted Runner: Netzwerkzugriff und Tokens hart absichern

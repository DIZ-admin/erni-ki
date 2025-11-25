# Configuration Directory

Most configuration files under `conf/` are intentionally gitignored to avoid
committing secrets or environment-specific settings.

## How to work with configs

- Check for provided templates/examples (`*.example`, `*.template`, `*.sample`)
  and copy them locally:

```bash
cp conf/<path>/<file>.example conf/<path>/<file>
```

- If you add a new config, commit only the template (`.example/.template`) and
  update `.gitignore` to keep real secrets out of git.
- Env-specific values should live in `env/*.env` (also gitignored) or GitHub
  Actions secrets.

## Quick sanity checks

- List missing real configs you need to create locally:

```bash
find conf -type f \( -name '*.example' -o -name '*.template' -o -name '*.sample' \)
```

- Ensure you never commit real keys/certs: `.gitignore` already excludes
  `conf/**/*.conf|*.yml|*.json`, SSL certs, etc.

If you need a template added for a missing service, add the template file (no
secrets) and update `.gitignore` accordingly.

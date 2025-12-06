# Documentation Audit Scripts

Automated tools for validating and auditing documentation quality.

## Purpose

These scripts ensure documentation consistency, quality, and synchronization
across languages. They match the checks run in GitHub Actions CI workflows.

## Available Scripts

### 1. Full Local Audit

**Script**: `run-local-audit.sh`

Runs comprehensive documentation audit matching CI workflows:

```bash
bash scripts/docs/run-local-audit.sh
```

**Checks performed**:

- Frontmatter validation (required fields, format)
- Markdown linting (style, formatting)
- YAML frontmatter validation
- Broken link detection
- Stale document detection (>90 days)
- Translation synchronization (RU/DE/EN)
- MkDocs build verification

**Output**: Results saved to `docs/reports/audit-2025-12/`

### 2. Quick Pre-commit Check

**Script**: `run-quick-check.sh`

Fast validation for staged changes:

```bash
bash scripts/docs/run-quick-check.sh
```

**Checks performed**:

- Frontmatter presence in modified files
- Markdown lint on modified files only
- Common mistakes (hardcoded localhost, TODO without pragma)

**Use case**: Run before `git commit` for quick feedback

### 3. Frontmatter Validation

**Script**: `validate-frontmatter.py`

Validates YAML frontmatter in all documentation files:

```bash
python3 scripts/docs/validate-frontmatter.py \
 --docs-dir docs \
 --output docs/reports/audit-2025-12/frontmatter.json
```

**Options**:

- `--docs-dir PATH` - Documentation directory (default: `docs`)
- `--output PATH` - JSON output file (optional)
- `--strict` - Fail on warnings (files without frontmatter)

**Required frontmatter fields**:

```yaml
---
title: Document Title
language: ru|de|en
page_id: unique-kebab-case-id
doc_version: 'YYYY.MM'
translation_status: original|translated|outdated|in_progress
---
```

### 4. Stale Documents Check

**Script**: `check-stale-docs.sh`

Finds documentation not updated in N days:

```bash
bash scripts/docs/check-stale-docs.sh docs 90
```

**Arguments**:

1. Documentation directory (default: `docs`)
2. Stale threshold in days (default: `90`)

**Exit codes**:

- `0` - No stale files or <5% stale
- `1` - >5% of files are stale

### 5. Translation Sync Check

**Script**: `translation-sync-check.sh`

Checks synchronization between RU/DE/EN documentation:

```bash
bash scripts/docs/translation-sync-check.sh docs
```

**Checks**:

- Missing translations (files in RU not in DE/EN)
- Outdated translations (DE/EN modified before RU source)
- Coverage percentage per language

**Targets**:

- German (DE): 80% coverage
- English (EN): 70% coverage

## Configuration Files

### Markdown Linter

**File**: `.markdownlint.json`

Matches CI workflow markdown linting rules:

```bash
markdownlint 'docs/**/*.md' \
 --config .markdownlint.json \
 --ignore 'docs/node_modules/**' \
 --ignore 'docs/site/**'
```

### YAML Linter

**File**: `.yamllint.yml`

Validates YAML frontmatter:

```bash
python3 -m yamllint docs/ -f parsable -c .yamllint.yml
```

### Link Checker Exclusions

Excluded domains (matches CI):

- `localhost`, `127.0.0.1`
- `example.com`
- `www.conventionalcommits.org`
- `docs.pact.io`

## Quick Start

### First-time Setup

```bash
# Install tools (macOS)
brew install lychee
bun add -g markdownlint-cli
python3 -m pip install pyyaml yamllint

# Verify installation
lychee --version
markdownlint --version
python3 -m yamllint --version
```

### Run Full Audit

```bash
# From project root
bash scripts/docs/run-local-audit.sh

# View detailed results
cat docs/reports/audit-2025-12/frontmatter.json | jq '.errors'
```

### Fix Common Issues

```bash
# Auto-fix markdown linting issues
markdownlint --fix 'docs/**/*.md' --config .markdownlint.json

# Check specific file
python3 scripts/docs/validate-frontmatter.py --docs-dir docs/getting-started
```

## CI Integration

### GitHub Actions Workflows

**docs-quality.yml** - Runs on PR/push to docs:

- Validates all documentation
- Uploads frontmatter report as artifact
- Creates summary in PR checks

**nightly-audit.yml** - Runs daily at 2 AM UTC:

- Full documentation build
- Link checking (stricter, fails on errors)
- Metadata validation

**Key difference**: Local scripts allow failures (warnings), CI enforces
stricter rules on `main`/`develop` branches.

## Best Practices

### Before Committing

```bash
# Quick check
bash scripts/docs/run-quick-check.sh

# Fix auto-fixable issues
markdownlint --fix 'docs/**/*.md'
```

### Before PR

```bash
# Full audit
bash scripts/docs/run-local-audit.sh

# Check results
less docs/reports/audit-2025-12/frontmatter.json
```

### Weekly Maintenance

```bash
# Find stale docs
bash scripts/docs/check-stale-docs.sh docs 90

# Check translation status
bash scripts/docs/translation-sync-check.sh docs
```

## Troubleshooting

### "Command not found: lychee"

```bash
brew install lychee
```

### "Command not found: markdownlint"

```bash
bun add -g markdownlint-cli
# or
npm install -g markdownlint-cli
```

### "No module named 'yaml'"

```bash
python3 -m pip install pyyaml
```

### Frontmatter validation fails

Check that frontmatter has all required fields:

```yaml
---
title: My Document # Required
language: ru # Required: ru, de, or en
page_id: my-document # Required: kebab-case
doc_version: '2025.11' # Required: YYYY.MM
translation_status: original # Required: original, translated, outdated, in_progress
---
```

### Link checker too slow

Exclude more domains in local run:

```bash
lychee --exclude 'example\\.com' --exclude 'localhost' 'docs/**/*.md'
```

## Output Files

All audit outputs are saved to `docs/reports/audit-2025-12/`:

- `frontmatter.json` - Frontmatter validation results
- `broken-links.md` - Broken link report (if generated)
- `markdown-lint.txt` - Markdown lint issues (if generated)
- `stale-docs.txt` - List of stale documents (if generated)
- `translations.txt` - Translation sync status (if generated)

## Related Documentation

- [Documentation Revision Plan](../../docs/development/documentation-revision-plan-2025-12.md)
- [Metadata Standards](../../docs/reference/metadata-standards.md)
- [Style Guide](../../docs/reference/style-guide.md)
- [CI Workflows](../../.github/workflows/)

## Support

For issues or questions:

1. Check [Troubleshooting](#-troubleshooting) section
2. Review
 [Documentation Revision Plan](../../docs/development/documentation-revision-plan-2025-12.md)
3. Open GitHub issue with `documentation` label

---

**Last Updated**: 2025-12-06 **Maintained By**: Documentation Team

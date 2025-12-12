---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
title: 'Documentation Monitoring and Metrics'
description: 'Automated documentation quality monitoring system'
---

# Documentation Monitoring and Metrics

This document describes the automated documentation quality monitoring system
that tracks and reports on documentation health metrics.

## Overview

The documentation monitoring system provides:

- **Automated weekly metrics collection** - runs every Sunday at 3 AM UTC
- **Quality score calculation** - overall health metric (0-100)
- **Threshold-based alerts** - creates GitHub issues when quality drops
- **Metrics tracking** - stale docs, broken links, translations, frontmatter
  coverage

## System Components

### 1. Metrics Collection Script

**Location:** `scripts/docs/docs_metrics.py`

This Python script collects comprehensive documentation metrics:

```bash
# Generate metrics JSON to stdout
python scripts/docs/docs_metrics.py

# Save to file
python scripts/docs/docs_metrics.py --output metrics.json

# Exit with code 1 if thresholds exceeded
python scripts/docs/docs_metrics.py --threshold-check

# Include lychee broken links data
python scripts/docs/docs_metrics.py --lychee-output lychee-output.txt
```

**Metrics collected:**

- `total_docs`: Total markdown files count
- `stale_docs_count`: Files with `last_updated` > 90 days old
- `broken_links_count` / `broken_links_percentage`: From lychee link checker
- `translation_sync`: Translation status for DE and EN
  (complete/partial/missing)
- `frontmatter_coverage`: Percentage of files with valid frontmatter
- `quality_score`: Overall score (0-100)

### 2. Weekly Metrics Workflow

**Location:** `.github/workflows/docs-weekly-metrics.yml`

**Schedule:** Every Sunday at 3 AM UTC (can also be triggered manually)

**Workflow steps:**

1. Checkout code and setup Python
2. Run lychee link checker (continues on error)
3. Collect metrics using `docs_metrics.py`
4. Upload metrics as artifacts (retained for 90 days)
5. Generate workflow summary
6. Create/update GitHub issue if thresholds exceeded

### 3. Related Workflows

- **Nightly Audit** (`.github/workflows/nightly-audit.yml`) - runs daily at 2 AM
  UTC
  - Validates frontmatter metadata
  - Builds MkDocs site
  - Checks links with lychee
- **Documentation Deploy** (`.github/workflows/docs-deploy.yml`) - on main
  branch pushes
  - Builds and deploys documentation site

## Quality Score Calculation

The quality score (0-100) is calculated from multiple components:

### Score Components

1. **Frontmatter Coverage** (30 points)
   - Percentage of files with valid frontmatter
   - Formula: `(files_with_frontmatter / total_files) * 30`

2. **Stale Docs Penalty** (up to -20 points)
   - Based on number of stale documents (90+ days old)
   - Max penalty at 50 stale docs
   - Formula: `min(20, (stale_count / 50) * 20)`

3. **Broken Links Penalty** (up to -30 points)
   - Based on percentage of broken links
   - Max penalty at 10% broken links
   - Formula: `min(30, (broken_percentage / 10) * 30)`

4. **Translation Completeness** (40 points total)
   - 20 points per language (DE, EN)
   - Complete translations: 100%, partial: 50%
   - Formula per language: `((complete + partial * 0.5) / total_ru) * 20`

### Example Score Calculation

For a project with:

- 100% frontmatter coverage → 30 points
- 5 stale docs → -2 points
- 2% broken links → -6 points
- DE: 80% complete, 10% partial → 17 points
- EN: 60% complete, 20% partial → 14 points

**Total:** 30 - 2 - 6 + 17 + 14 = **53/100**

## Alert Thresholds

Alerts are triggered when any threshold is exceeded:

| Metric               | Threshold  | Severity |
| -------------------- | ---------- | -------- |
| Stale documents      | > 20 files | Warning  |
| Broken links         | > 5%       | Warning  |
| Frontmatter coverage | < 95%      | Warning  |
| Quality score        | < 80/100   | Warning  |

When thresholds are exceeded, the workflow:

1. Creates a GitHub issue with label `documentation`, `metrics`, `automated`
2. Or updates existing open metrics issue with new data
3. Includes actionable checklist for remediation
4. Shows sample of problematic files

## Interpreting Metrics

### Stale Documents

**Definition:** Files with `last_updated` field older than 90 days

**Action items:**

- Review stale documents for accuracy
- Update content if needed
- Update `last_updated` frontmatter field
- Archive obsolete documentation

### Broken Links

**Source:** Lychee link checker output

**Common causes:**

- External sites changed/moved
- Internal reorganization
- Typos in URLs

**Action items:**

- Check lychee output for specific broken links
- Update or remove broken links
- Consider using Internet Archive for historical references

### Translation Sync

**Tracks:** DE and EN translations vs RU canonical files

**Statuses:**

- `complete`: Translation is complete and up-to-date
- `partial`: Translation exists but may be incomplete
- `missing`: File has no translation

**Action items:**

- Prioritize missing translations for high-traffic pages
- Update partial translations
- Use `scripts/docs/translation_report.py` for detailed analysis

### Frontmatter Coverage

**Definition:** Percentage of files with valid YAML frontmatter

**Required fields:**

- `language`
- `translation_status`
- `doc_version`

**Action items:**

- Run `scripts/docs/validate_metadata.py` to identify files
- Add missing frontmatter
- See [Metadata Validation](#metadata-validation) below

## Using the Metrics Locally

### Check Current Metrics

```bash
# View metrics JSON
python scripts/docs/docs_metrics.py | jq '.'

# Save to file
python scripts/docs/docs_metrics.py --output metrics.json

# Check if thresholds exceeded (exits with code 1 if yes)
python scripts/docs/docs_metrics.py --threshold-check
```

### Include Link Check Data

```bash
# Run lychee first
lychee 'docs/**/*.md' --output lychee-output.txt

# Then collect metrics with link data
python scripts/docs/docs_metrics.py --lychee-output lychee-output.txt
```

### Example Output

```json
{
  "timestamp": "2025-12-10T03:00:00.000000",
  "total_docs": 462,
  "stale_docs_count": 15,
  "broken_links_percentage": 2.5,
  "frontmatter_coverage": 98.5,
  "quality_score": 85.3,
  "translation_sync": {
    "de": {
      "complete": 120,
      "partial": 10,
      "missing": 50,
      "total_ru_files": 180
    },
    "en": {
      "complete": 100,
      "partial": 20,
      "missing": 60,
      "total_ru_files": 180
    }
  },
  "threshold_violations": [],
  "thresholds_exceeded": false
}
```

## Related Scripts

### Metadata Validation

```bash
# Validate all frontmatter
python scripts/docs/validate_metadata.py
```

Checks for:

- Missing frontmatter
- Missing required fields
- Deprecated fields
- Unknown fields
- Incorrect `doc_version`

### Comprehensive Audit

```bash
# Run full documentation audit
python scripts/docs/audit-documentation.py
```

Generates detailed report including:

- Overall statistics
- Language and category distribution
- Metadata issues
- Files with dates in names
- Missing index files
- Emoji policy violations
- Overall assessment score

### Translation Report

```bash
# Check translation coverage
python scripts/docs/translation_report.py

# Specific locales
python scripts/docs/translation_report.py --locales de en

# Custom root directory
python scripts/docs/translation_report.py --root docs/
```

## Viewing Historical Metrics

Metrics are stored as GitHub Actions artifacts for 90 days:

1. Go to [Actions](https://github.com/DIZ-admin/erni-ki/actions) → "Weekly Documentation Metrics"
2. Select a workflow run
3. Download `docs-metrics-{run_number}` artifact
4. Extract and view `metrics.json`

## Improving Documentation Quality

### Quick Wins

1. **Add missing frontmatter** - use `validate_metadata.py` to find files
2. **Fix broken links** - check lychee output in nightly audit
3. **Update stale docs** - review files not updated in 90+ days
4. **Complete partial translations** - use `translation_report.py`

### Best Practices

- **Update `last_updated`** when making content changes
- **Run link checker locally** before committing large changes
- **Keep translations synced** with RU canonical files
- **Use consistent frontmatter** across all files
- **Archive obsolete docs** instead of deleting

### Pre-commit Checks

The project's pre-commit hooks automatically check:

- Metadata validation (`validate_metadata.py`)
- No emoji in documentation
- Markdown linting
- Link validation (visual/TOC checks)

Run locally:

```bash
pre-commit run --all-files
```

## Troubleshooting

### Script Fails to Run

**Check dependencies:**

```bash
pip install -r requirements-docs.txt
```

**Required packages:**

- `pyyaml` - YAML parsing
- `mkdocs` - Documentation building

### Quality Score Too Low

1. **Check threshold violations** in metrics output
2. **Prioritize by impact:**
   - Frontmatter coverage (30 points)
   - Translation completeness (40 points)
   - Broken links penalty (up to -30 points)
3. **Use related scripts** to identify specific issues
4. **Create improvement plan** with measurable goals

### False Positive Stale Docs

Not all old documentation is actually stale. Review each file:

- **Still accurate?** Update `last_updated` to current date
- **Historical reference?** Move to `docs/archive/`
- **Truly outdated?** Update content and date

## Configuration

### Adjusting Thresholds

Edit thresholds in `scripts/docs/docs_metrics.py`:

```python
THRESHOLDS = {
    "stale_docs_count": 20,           # Max stale documents
    "broken_links_percentage": 5.0,   # Max % broken links
    "frontmatter_coverage": 95.0,     # Min % frontmatter coverage
    "quality_score": 80.0,            # Min overall score
}
```

### Changing Stale Days

Edit `STALE_DAYS` constant:

```python
STALE_DAYS = 90  # Days before doc is considered stale
```

### Workflow Schedule

Edit cron schedule in `.github/workflows/docs-weekly-metrics.yml`:

```yaml
on:
  schedule:
    - cron: '0 3 * * 0' # Sunday 3 AM UTC
```

## Future Enhancements

Potential improvements to the monitoring system:

- **Trend tracking** - track metrics over time, show graphs
- **Per-category scores** - quality scores by documentation section
- **Auto-remediation** - automatically update stale dates for trivial changes
- **Translation coverage goals** - per-language completion targets
- **Integration with PR checks** - block PRs that degrade quality score
- **Slack/email notifications** - alert team channels on threshold violations

## Support

For issues or questions:

1. Check [GitHub Issues](https://github.com/DIZ-admin/erni-ki/issues) for existing reports
2. Review workflow run logs in [Actions](https://github.com/DIZ-admin/erni-ki/actions)
3. Test locally using scripts in `scripts/docs/`
4. Create a new issue with `documentation` label

## References

- [MkDocs Documentation](https://www.mkdocs.org/) - Site generator
- [Lychee Link Checker](https://github.com/lycheeverse/lychee) - Link validation
- [Setup Guide](./setup-guide.md) - Local environment setup

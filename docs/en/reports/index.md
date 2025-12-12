---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
---

# Project Reports and Audits

This directory contains permanent reference documentation about project audits,
analyses, and ongoing documentation maintenance.

## Permanent Documentation

### Configuration and Planning

Reports are maintained in the archive:

- [Budget Analysis 2025-11](../archive/reports/budget-analysis-2025-11.md)
- [SearXNG Redis Issue 2025-10](../archive/reports/searxng-redis-issue-2025-10.md)

## Historical Reports

All dated analysis reports and one-time audits are in the archive under
`archive/reports/`.

For security-related reports, see
[Security Action Plan](../operations/security-action-plan.md).

## Audit Frequency

According to
[Documentation Maintenance Strategy](../reference/documentation-maintenance-strategy.md):

- **Comprehensive audits:** Quarterly (every 3 months)
- **Quick audits:** Monthly (automated via scripts)
- **CI/CD checks:** On every PR

## Last Audit

**Last system analysis date:** 2025-12-02 **Next audit:** As per maintenance
strategy or on request

## Audit Tools

Documentation audit scripts are located in `scripts/docs/`:

- `scripts/docs/audit-documentation.py` - Automated documentation audit
- `scripts/remove-all-emoji.py` - Emoji removal tool
- `scripts/validate-no-emoji.py` - No-emoji policy validation

## Related Documentation

- [Documentation Maintenance Strategy](../reference/documentation-maintenance-strategy.md)
- [NO-EMOJI Policy](../reference/NO-EMOJI-POLICY.md)
- [Style Guide](../reference/style-guide.md)
- [Metadata Standards](../reference/metadata-standards.md)

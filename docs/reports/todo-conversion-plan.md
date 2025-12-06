---
title: TODO/FIXME to GitHub Issues Conversion Plan
language: ru
page_id: todo-conversion-plan-2025-12-06
doc_version: '2025.11'
translation_status: original
---

# TODO/FIXME to GitHub Issues Conversion Plan

**Date**: 2025-12-06
**Status**: In Progress

## Summary

- **Total Real TODO/FIXME**: 72 items (after filtering false positives)
- **Distribution**:
- Code: 37 items
- Configuration: 6 items
- Documentation: 17 items
- Other: 12 items

## Strategy

### Phase 1: Immediate Actions [DONE]

1. **Pre-commit Hook Update** - Block new TODO/FIXME without issue links
2. **Documentation** - Add guidelines for TODO management
3. **Script** - Tool to extract and categorize TODOs

### Phase 2: Cleanup (Manual Review Required)

Many detected "TODOs" are false positives:

- **Code patterns**: Variable names like `TodoItem`, `extract_todos`
- **Workflow mentions**: "todo → doing → review → done" in Archon docs
- **Documentation examples**: Code samples showing TODO usage

**Recommendation**: Manual triage required to identify REAL actionable TODOs.

### Phase 3: GitHub Issue Creation (Future)

Once real TODOs are identified:

1. Create GitHub issue template for TODO conversion
2. Batch create issues with labels:

- `technical-debt`
- Priority: `P0`, `P1`, `P2`
- Area: `devx`, `security`, `documentation`, etc.

3. Link issues back to code (replace `TODO: description` with `TODO(#123): description`)

## Current TODO Categories

### High-Value TODOs to Address

**Configuration** (6 items):

- `.pre-commit-config.yaml`: Pre-commit grep patterns

**Documentation** (needs manual review):

- Translation TODOs in `docs/academy/`
- Documentation maintenance strategies

### Low-Priority / False Positives

**Scripts** (40 items):

- Most are in `extract_todos.py` itself (variable names, patterns)
- `scripts/archon/README.md` - workflow status mentions

**General** (15 items):

- `CLAUDE.md`, `AGENTS.md` - Archon workflow documentation
- Mostly instructional, not actionable

## Pre-commit Hook

New rule added to `.pre-commit-config.yaml`:

```yaml
- id: check-todo-fixme
 name: 'Code Quality: no inline task markers'
 entry: bash
 args:
 - -c
 - |
 matches=$(rg --no-heading --line-number \
 --glob '*.{py,js,ts,go,yml,yaml}' \
 --iglob '!node_modules/**' \
 --iglob '!.venv/**' \
 "TODO|FIXME" || true)
 matches=$(echo "$matches" | grep -v "pragma: allowlist todo")
 if [[ -n "$matches" ]]; then
 echo " Inline tasks detected"
 echo "$matches"
 exit 1
 fi
```

## Guidelines

### Creating TODOs (Discouraged)

All tasks should be tracked in:

1. **GitHub Issues** - For code/bugs/features
2. **Archon MCP Server** - For development tasks

### Exception: Temporary TODOs

If absolutely necessary, use pragma allowlist:

```python
# TODO: refactor this function # pragma: allowlist todo
```

### Preferred Workflow

Instead of:

```python
# TODO: Add error handling
def process_data():
 pass
```

Do:

```python
# See GitHub issue #123 for planned error handling improvements
def process_data():
 pass
```

## Next Steps

1. [DONE] Create extraction script - `scripts/maintenance/extract_todos.py`
2. [DONE] Generate analysis report - `docs/reports/todo-analysis.md`
3. [DONE] Update pre-commit hook - Already configured in `.pre-commit-config.yaml`
4. [PENDING] Manual review - Identify real actionable TODOs (requires human judgment)
5. [PENDING] Create GitHub issues - Batch create for validated TODOs
6. [PENDING] Update code - Replace TODOs with issue references

## Tools

- **Extraction**: `python scripts/maintenance/extract_todos.py`
- **Pre-commit check**: Runs automatically on commit
- **Manual override**: Use `# pragma: allowlist todo` suffix

## References

- Pre-commit guide: `docs/development/pre-commit-guide.md`
- Archon workflow: `CLAUDE.md`, `AGENTS.md`
- TODO analysis: `docs/reports/todo-analysis.md`

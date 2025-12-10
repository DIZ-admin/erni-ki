---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-12-10'
title: 'i18n Architecture Decision'
description: 'Documentation internationalization structure decision record'
---

# i18n Architecture Decision

**Status:** Approved **Date:** 2025-12-10 **Decision:** Full Localization
(Variant C)

## Context

The documentation currently has an inconsistent i18n structure:

- Root `docs/` contains mixed content: ~97 EN files + ~69 RU files
- `docs/ru/` contains 242 RU files (duplicating some root content)
- `docs/de/` contains 105 DE files
- `docs/en/` contains only 1 file
- `mkdocs.yml` declares EN as default, but academy/ is mostly RU

This creates confusion about canonical sources and complicates maintenance.

## Decision

Adopt **full localization structure** where all content lives in
language-specific folders:

```
docs/
+-- index.md              # Landing page with language selector only
+-- ru/                   # ALL Russian content (canonical source)
|   +-- index.md
|   +-- academy/
|   +-- operations/
|   +-- security/
|   +-- ...
+-- en/                   # ALL English translations
|   +-- index.md
|   +-- academy/
|   +-- operations/
|   +-- ...
+-- de/                   # ALL German translations
    +-- index.md
    +-- academy/
    +-- ...
```

## Rationale

### Why full localization over mixed root?

1. **Clarity**: No ambiguity about which language a file belongs to
2. **Maintainability**: Easy to track translation coverage per locale
3. **Scalability**: Adding new languages requires only a new folder
4. **Independence**: Each locale can have different structure if needed
5. **Tooling**: Simpler scripts for translation sync and validation

### Why RU as canonical source?

- RU has the most complete content (242 files)
- Target audience: ERNI Schweiz (DE/RU speakers primarily)
- Most academy content was originally written in RU
- EN/DE are translations, not originals

## Migration Plan

### Phase 1: Prepare structure

1. Create `docs/en/` mirror structure from current root EN files
2. Move all EN-language files from root to `docs/en/`
3. Verify `docs/ru/` has complete content (merge from root if needed)
4. Create landing `docs/index.md` with language selector

### Phase 2: Cleanup root

1. Remove all `.md` files from root except `index.md`
2. Keep shared assets: `javascripts/`, `stylesheets/`, `versions.json`
3. Move `archive/` to `docs/ru/archive/` (RU canonical)
4. Update all internal links

### Phase 3: Update configuration

1. Modify `mkdocs.yml` i18n plugin:

   ```yaml
   plugins:
     - i18n:
         docs_structure: folder
         languages:
           - locale: ru
             default: true
             name: 'Русский'
           - locale: en
             name: 'English'
           - locale: de
             name: 'Deutsch'
   ```

2. Update navigation to reference locale-prefixed paths
3. Test build with `mkdocs build --strict`

### Phase 4: Validation

1. Run link checker (lychee) on all locales
2. Verify translation_status frontmatter accuracy
3. Update docs_metrics.py for new structure
4. Document new contribution workflow

## File Movement Summary

| Source                        | Destination                    | Count |
| ----------------------------- | ------------------------------ | ----- |
| `docs/*.md` (EN)              | `docs/en/*.md`                 | ~5    |
| `docs/academy/*` (EN)         | `docs/en/academy/*`            | ~30   |
| `docs/operations/*` (EN)      | `docs/en/operations/*`         | ~40   |
| `docs/security/*` (EN)        | `docs/en/security/*`           | ~7    |
| `docs/getting-started/*` (EN) | `docs/en/getting-started/*`    | ~8    |
| `docs/academy/*` (RU)         | `docs/ru/academy/*`            | merge |
| `docs/archive/*`              | `docs/ru/archive/*`            | ~63   |
| `docs/reports/*`              | `docs/ru/reports/*` or archive | ~7    |

## Impact on Workflows

### Content creation

- New content goes to `docs/ru/` first (canonical)
- Translations created in `docs/en/` and `docs/de/`
- Use `translation_status` frontmatter to track sync

### CI/CD

- Update `nightly-audit.yml` paths
- Update `docs-weekly-metrics.yml` for new structure
- Lychee excludes may need adjustment

### Local development

```bash
# Build specific locale
mkdocs build --strict

# Serve with live reload
mkdocs serve
```

## Risks and Mitigations

| Risk                     | Mitigation                                  |
| ------------------------ | ------------------------------------------- |
| Broken internal links    | Run lychee before/after migration           |
| SEO impact (URL changes) | Add redirects in nginx or mkdocs            |
| Contributor confusion    | Update CONTRIBUTING.md with new workflow    |
| Build time increase      | Monitor, consider separate builds if needed |

## Success Criteria

- [ ] All content in language-specific folders
- [ ] Zero files with wrong language in wrong folder
- [ ] `mkdocs build --strict` passes for all locales
- [ ] Lychee reports zero broken links
- [ ] Audit score >= 9.5/10
- [ ] Clear documentation for contributors

## References

- [MkDocs i18n plugin](https://github.com/ultrabug/mkdocs-static-i18n)
- [Material for MkDocs - Setting up site language](https://squidfunk.github.io/mkdocs-material/setup/changing-the-language/)

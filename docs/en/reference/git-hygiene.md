---
title: Git Hygiene
language: en
description:
  Keeps develop clean, enforces Conventional Commits, and offloads generated
  artefacts.
status: complete
translation_status: source
doc_version: '2025.11'
last_updated: '2025-12-13'
---

# Git Hygiene and Artefact Handling

## 1. Keep `develop` pristine

- Treat `develop` as the integration branch; only merge polished feature or fix
  branches via PRs.
- Fetch/rebase regularly: `git fetch origin && git rebase origin/develop` keeps
  history linear and avoids surprise conflicts.
- Before switching branches, run `git status`, `git stash`/`git clean` as
  needed, and ensure there are no deleted or generated files left uncommitted.
- Periodically prune local branches that are merged or inactive for >30 days.

## 2. Conventional commits and templates

- We enforce Conventional Commits via `commitlint.config.cjs`. The allowed types
  include `chore`, `docs`, `feat`, `fix`, `perf`, `refactor`, `ci`, `test`,
  `build`, `style`, `release`, and `batch` if needed.
- Use the provided template (`.gitmessage.txt`) so every commit starts with
  `<type>(<optional-scope>): short summary` and includes the motivation/footers.

  ```bash
  git config commit.template .gitmessage.txt
  ```

- Run `bunx eslint .`, `ruff check .`, `mypy --config-file mypy.ini`,
  `bunx vitest`, etc., locally before pushing and mention the results in the PR
  checklist.

## 3. Branch and PR policies

- Name user branches `feature/*`, `fix/*`, `devin/*`, etc., and avoid working
  directly on `develop` or `main`.
- Protect `develop` with required PR reviews, green CI status, and lint/test
  gates so it cannot be fast-forwarded with dirty trees.
- Before creating a PR, run `scripts/git-hygiene/check-artifacts.sh` to confirm
  no large generated files are tracked and the working tree is clean.
- Close stale branches that are fully merged or have not been touched for a
  sprint (30+ days). Keep `git branch -vv` tidy and remove `chore/`, `fix/`, or
  `feat/` branches once merged upstream.

## 4. Artefact management

- Generated data (monitoring alerts, WAL files, temporary backrest backups, docs
  archives) should not be committed. For example:
  - `compose/data/` currently holds monitoring state and WAL snapshots. Upload
    archived versions to an artifact bucket (S3, GCS) or keep them as downloads
    in a release asset rather than stuffing Git history.
  - `docs/ru/archive/reports/` keeps archived uploads; if the files are
    generated, bundle them into a `.zip`/`.tar.gz` and push the archive
    alongside release notes instead of the raw directory.
- The helper script below reports directory sizes and warns if artefacts are
  tracked:

  ```bash
  scripts/git-hygiene/check-artifacts.sh
  ```

- If the script reports tracked files, remove them with `git rm --cached` and
  add the directory to `.gitignore`, then upload the preserved copy to your
  artifact store and document the location.

## 5. Enforcement steps

1. Run `git status` + `scripts/git-hygiene/check-artifacts.sh` before switching
   branches.
2. Configure commit template and lint hooks:
   `git config commit.template .gitmessage.txt` and `npm install` (if needed) to
   share commitlint with your editor.
3. Document any deviation (bulk imports, large data) in the PR description so
   reviewers can deliberate on whether to keep it in the repo or move it
   elsewhere.

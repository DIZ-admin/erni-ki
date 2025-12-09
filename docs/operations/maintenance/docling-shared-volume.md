---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Docling Shared Volume Access and Cleanup Policy

[TOC]

Shared volume `./data/docling/shared` is used by Docling and OpenWebUI services
for exchanging files that undergo OCR/extraction. The volume may contain PII,
therefore formalized access control and retention strategy is required.

## 1. Data Categories

| Directory     | Source                   | Content                                          | Default Retention      |
| ------------- | ------------------------ | ------------------------------------------------ | ---------------------- |
| `uploads/`    | OpenWebUI (user uploads) | Original documents, pdfs, images.                | 2 days                 |
| `processed/`  | Docling pipeline         | Normalized chunks, JSON, intermediate artifacts. | 14 days                |
| `exports/`    | Docling/OpenWebUI        | Ready responses, zips, reports.                  | 30 days                |
| `quarantine/` | Docling                  | Files with errors/suspicions of malware/PII.     | 60 days, manual review |
| `tmp/`        | Both services            | Short-lived temporary files, dumps.              | 1 day                  |

> Structure is created automatically by the script
> `scripts/maintenance/docling-shared-cleanup.sh`. If directory doesn't exist,
> it will be created with correct permissions.

## 2. RBAC and Host Permissions

- Base owner: system user under which docker compose runs (`$USER`).
- Create group `docling-data` (one-time): `sudo groupadd -f docling-data`.
- Assign directory owner: `sudo chgrp -R docling-data ./data/docling/shared`.
- Permissions on root and subdirectories:
  `chmod 770 ./data/docling/shared{,/uploads,/processed,/exports,/quarantine,/tmp}`.
- Include AI-platform admins and service accounts in `docling-data` group, who
  should read/write files from the host.
- For read-only auditors, create `docling-readonly` group and grant `chmod 750`
  on `exports/`.

> Automation: execute `./scripts/maintenance/enforce-docling-shared-policy.sh`
> (if necessary set `DOC_SHARED_OWNER`, `DOC_SHARED_GROUP`,
> `DOC_SHARED_READONLY_GROUP`). Script creates groups, aligns owner and sets ACL
> for `exports/`.

Docling/OpenWebUI containers access the same directory by UID 1000 (by default).
If stricter separation is needed, use ACL:

```bash
sudo setfacl -m g:docling-readonly:rx ./data/docling/shared/exports
sudo setfacl -m g:docling-data:rwx ./data/docling/shared
```

## 3. Cleanup and Volume Control

Script `scripts/maintenance/docling-shared-cleanup.sh` implements retention.
Behavior is configured by variables:

| Variable                               | Default Value           | Purpose                         |
| -------------------------------------- | ----------------------- | ------------------------------- |
| `DOC_SHARED_ROOT`                      | `./data/docling/shared` | Path to volume                  |
| `DOC_SHARED_INPUT_RETENTION_DAYS`      | 2                       | Raw uploads retention period    |
| `DOC_SHARED_PROCESSED_RETENTION_DAYS`  | 14                      | Processed data retention period |
| `DOC_SHARED_EXPORT_RETENTION_DAYS`     | 30                      | Exports storage                 |
| `DOC_SHARED_QUARANTINE_RETENTION_DAYS` | 60                      | Quarantine                      |
| `DOC_SHARED_TMP_RETENTION_DAYS`        | 1                       | Temporary files                 |
| `DOC_SHARED_MAX_SIZE_GB`               | 20                      | Soft limit for alert logging    |

### 3.1 Manual / dry-run

```bash
./scripts/maintenance/docling-shared-cleanup.sh          # dry-run (default)
DOC_SHARED_INPUT_RETENTION_DAYS=1 ./scripts/maintenance/docling-shared-cleanup.sh
```

### 3.2 Apply and cron

```bash
sudo -E ./scripts/maintenance/docling-shared-cleanup.sh --apply \
  >> logs/docling-shared-cleanup.log 2>&1
```

Recommended cron (daily at 02:10):

````cron
10 2 * * * cd /home/konstantin/Documents/augment-projects/erni-ki && \
  sudo -E ./scripts/maintenance/docling-shared-cleanup.sh --apply >> logs/docling-shared-cleanup.log 2>&1

>**Important:** use `sudo -E` (with NOPASSWD in sudoers) or run cron under the user
> who owns `data/docling`. Otherwise the task will fail with Permission denied again.

To generate a ready sudoers file:

```bash
./scripts/maintenance/render-docling-cleanup-sudoers.sh | sudo tee /etc/sudoers.d/docling-cleanup
````

By default, necessary `env_keep` rules are added, so cron/systemd can pass
`DOC_SHARED_*` variables without manual editing of `/etc/sudoers`.

### 3.3 Systemd unit

The repository already has unit files and installation script:

- `ops/systemd/docling-cleanup.service`
- `ops/systemd/docling-cleanup.timer`
- `ops/systemd/docling-cleanup.env.example`
- `ops/sudoers/docling-cleanup.sudoers`
- `scripts/maintenance/install-docling-cleanup-unit.sh`

**Activation steps**

1. Copy `ops/sudoers/docling-cleanup.sudoers` to
   `/etc/sudoers.d/docling-cleanup`, substituting the actual user and path to
   repository (NOPASSWD).
2. Execute `./scripts/maintenance/install-docling-cleanup-unit.sh` — unit files
   will be placed in `~/.config/systemd/user`, creates
   `~/.config/docling-cleanup.env`, timer `docling-cleanup.timer` will enable
   automatically.
3. Edit `~/.config/docling-cleanup.env` (example provided) to set owner/group
   and path to shared volume. By default runs at 02:10 CET,
   `RandomizedDelaySec=300`.

> For system-level installation, move unit files to `/etc/systemd/system`, add
> `User=docling-maint` to `.service` and enable timer via
> `systemctl enable --now docling-cleanup.timer`.

Add log monitoring (Fluent Bit → Loki) and alert if output shows
`WARNING: shared volume size ... exceeds`. Script
`scripts/monitoring/docling-cleanup-permission-metric.sh` publishes metric
`erni_docling_cleanup_permission_denied`; include it in cron/systemd and
Alertmanager to trigger on repeated `Permission denied`.

## 4. Incident Procedures

1. **Suspicious file detected** — move it to `quarantine/` and document in
   ticket (add date/author in filename), execute `chmod 640`. 2. **Volume full**
   — run script with reduced retention parameters or delete manually after
   coordination with data owner. 3. **Restore request** — data older than
   Retention is not guaranteed; use Backrest/Backups if you need to restore
   deleted file.

## 5. Documentation

- Main reference: `docs/architecture/service-inventory.md` (section "Docling
  shared volume policy").
- Archon document `ERNI-KI Minimal Project Description` — contains summary and
  risks.
- Cleanup script: `scripts/maintenance/docling-shared-cleanup.sh`.

```

```

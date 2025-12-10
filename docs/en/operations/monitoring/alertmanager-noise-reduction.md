---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Alertmanager Noise Reduction & Redis Autoscaling

## Goals

- Reduce number of spammy `HTTPErrors`/`HighHTTPResponseTime` alerts from
  blackbox.
- Document Redis autoscaling procedure for chronic fragmentation and
  Alertmanager queue overflow.

## Blackbox rate limiting

1.**Prometheus rules**— example in `ops/prometheus/blackbox-noise.rules.yml`.
Group `blackbox-noise.rules` adds aggregating alerts (`BlackboxHTTPErrorBurst`,
`BlackboxSustainedLatency`) and marks them as `noise_group=blackbox`. Copy the
file to Prometheus configuration and add to `rule_files`. 2.**Alertmanager
route**— `ops/alertmanager/blackbox-noise-route.yml` contains a block for
`route.routes`. It increases `group_interval`/`repeat_interval` to 15m/3h. Place
it above the `severity: warning` route. 3.**Deploy**:

- Import files to production configuration (`conf/*`), restart `prometheus` and
  `alertmanager` containers.
- Verify via UI that instead of dozens of `HTTPErrors` you get a single
  aggregated alert.

## Redis auto-scaling

1.**Watchdog**— `scripts/maintenance/redis-fragmentation-watchdog.sh` supports
variables `REDIS_AUTOSCALE_ENABLED`, `REDIS_AUTOSCALE_STEP_MB` (default 256MB)
and `REDIS_AUTOSCALE_MAX_GB` (default 4GB). After `MAX_PURGES` the script bumps
`maxmemory` via `CONFIG SET` and rewrites config. 2.**How to enable**:

- Export variables (e.g., in cron):

  ```bash
  export REDIS_AUTOSCALE_ENABLED=true
  export REDIS_AUTOSCALE_STEP_MB=512
  export REDIS_AUTOSCALE_MAX_GB=4
  ```

- Run watchdog (cron/systemd) and verify that
  `logs/redis-fragmentation-watchdog.log` contains
  `Autoscaling Redis maxmemory...` lines.

  3.**Monitoring**— track metrics `mem_fragmentation_ratio` and `maxmemory`
  (values in MB are output inside watchdog). Additionally recommend adding a
  Grafana panel (Redis dashboard) to track bumps.

## Procedure for spike events

1.**Alertmanager queue**: `tail -f .config-backup/logs/alertmanager-queue.log` —
if >500 for 10 minutes, verify that blackbox alerts haven't spammed (see route).
Set temporary silence if necessary. 2.**Redis autoscale**: check watchdog log;
if no bumps occurred, you can manually execute
`docker compose exec redis redis-cli config set maxmemory <value>`. 3.**Documentation**:
reference this runbook when analyzing incidents, recording how many times
autoscale was triggered.

## Enabling autoscale watchdog

1. Create environ file (example: `ops/systemd/redis-watchdog.env.example`) and
   connect it in cron/systemd unit for `redis-fragmentation-watchdog.sh`.
2. Update cron/systemd: `EnvironmentFile=~/.config/redis-watchdog.env` or export
   variables before execution.
3. Monitor `logs/redis-fragmentation-watchdog.log` — after triggering
   `Autoscaling Redis maxmemory ...` will appear.
4. Add Grafana panel (Redis dashboard) with `mem_fragmentation_ratio` and
   `maxmemory` and enable alert on sharp increase.

## Grafana / Alertmanager monitoring

- In Grafana import Redis panel and add new graph "Blackbox Noise Rate" (uses
  expression from file `ops/prometheus/blackbox-noise.rules.yml`).
- In Alertmanager UI verify that route `noise_group=blackbox` groups alerts
  every 15 minutes.
- Document all triggers in this runbook (date, source, actions taken).

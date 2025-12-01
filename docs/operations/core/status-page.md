---
language: ru
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# ERNI-KI status page (Uptime Kuma)

A friendly status page shows whether ERNI-KI services are up, degraded, or under
maintenance. It is powered by Uptime Kuma and kept on the same internal network
as other observability tools.

## Where to find it

- Default local URL: `http://localhost:3001` (bound to localhost only).
- Production URL: configure via your reverse proxy (e.g., `/status` or a
  dedicated subdomain). Document the chosen URL here: `<STATUS_PAGE_URL>`.
- If SSO is required, reuse the existing reverse-proxy auth configuration.

## What the statuses mean

-**Operational:**all monitored checks are healthy. -**Degraded:**at least one
check is failing or slow; basic functions may still
work. -**Maintenance:**planned work is in progress; expect
interruptions. -**Unknown:**the status page cannot reach its checks—verify
network or container health.

## How to use it

1. Open the status page before raising an incident ticket.
2. If something is red or degraded, share the status link in your support
   request.
3. For scheduled maintenance, check the news posts in `News`.

## Operations notes

- The service runs via Docker Compose as `uptime-kuma` with data stored in
  `./data/uptime-kuma`.
- Adjust the exposed port or base path through the reverse proxy; avoid exposing
  the container directly to the internet.
- Back up the `data/uptime-kuma` folder with other monitoring data.
- If the container is down, restart with `docker compose up -d uptime-kuma` and
  verify healthchecks.

## Who to contact

- Platform on-call engineer for outages.
- Security or compliance for access and policy questions.
- Documentation maintainers for updates to this page.

## Автоматизация через socket API (CLI, без UI)

Если UI недоступен, мониторы можно создавать через socket.io API.

Быстрый пример (внутри контейнера `uptime-kuma`):

```bash
cat >/tmp/kuma_seed.js <<'NODE'
const { io } = require('/app/node_modules/socket.io-client');
const monitors = [
  { name: 'Loki ready', type: 'http', url: 'http://loki:3100/ready' },
  { name: 'Prometheus', type: 'http', url: 'http://prometheus:9090/-/ready' },
  { name: 'Grafana', type: 'http', url: 'http://grafana:3000/api/health' },
  { name: 'Alertmanager', type: 'http', url: 'http://alertmanager:9093/-/healthy' },
  { name: 'LiteLLM', type: 'http', url: 'http://litellm:4000/health/liveliness' },
  { name: 'OpenWebUI', type: 'http', url: 'http://openwebui:8080/health' },
  { name: 'Redis TCP', type: 'tcp', hostname: 'redis', port: 6379 },
  { name: 'Node Exporter', type: 'http', url: 'http://node-exporter:9100/metrics' },
  { name: 'Nginx', type: 'http', url: 'http://nginx:80/' },
];
const defaults = { interval: 60, retryInterval: 60, resendInterval: 0, maxretries: 0,
  accepted_statuscodes: ['200-299'], notificationIDList: {}, ignoreTls: false,
  expiryNotification: false, maxredirects: 10, dns_resolve_type: 'A', dns_resolve_server: '1.1.1.1',
  mqttCheckType: 'keyword', oauth_auth_method: 'client_secret_basic', kafkaProducerBrokers: [],
  kafkaProducerSaslOptions: { mechanism: 'None' }, cacheBust: false, gamedigGivenPortOnly: true,
  remote_browser: null, rabbitmqNodes: [], conditions: [] };
const socket = io('http://localhost:3001', { transports: ['websocket'], timeout: 5000 });
socket.on('connect_error', (e) => { console.error(e.message); process.exit(1); });
socket.on('connect', () => {
  socket.emit('login', { username: 'admin', password: 'ECRvQ3#2', token: null }, (res) => {
    if (!res.ok) { console.error('login failed', res); process.exit(1); }
    let i = 0;
    const addNext = () => {
      if (i >= monitors.length) { console.log('done'); socket.disconnect(); return; }
      const m = { ...defaults, ...monitors[i] };
      if (m.type === 'tcp') { delete m.url; }
      socket.emit('add', m, (r) => { console.log(m.name, r); i++; setTimeout(addNext, 200); });
    };
    addNext();
  });
});
NODE
docker exec erni-ki-uptime-kuma node /tmp/kuma_seed.js
```

Список мониторов (после логина):

```bash
cat >/tmp/kuma_list.js <<'NODE'
const { io } = require('/app/node_modules/socket.io-client');
const socket = io('http://localhost:3001', { transports: ['websocket'], timeout: 5000 });
socket.on('connect_error', (e) => { console.error(e.message); process.exit(1); });
socket.on('connect', () => {
  socket.emit('login', { username: 'admin', password: 'ECRvQ3#2', token: null }, (res) => {
    if (!res.ok) { console.error('login failed', res); process.exit(1); }
    socket.emit('getMonitorList', () => {});
  });
});
socket.on('monitorList', (data) => {
  console.log(JSON.stringify(Object.values(data).map(m => ({
    id: m.id, name: m.name, type: m.type, url: m.url, host: m.hostname, port: m.port, ignoreTls: m.ignoreTls
  })), null, 2));
  process.exit(0);
});
NODE
docker exec erni-ki-uptime-kuma node /tmp/kuma_list.js
```

Удаление/повторное добавление

```bash
// удалить
socket.emit('deleteMonitor', monitorID, cb)
// добавить (см. пример выше)
```

Важно

- Loki работает с TLS (см. `conf/loki/loki-config.yaml`), поэтому для health
  можно использовать `https://loki:3100/ready` с `ignoreTls: true` или выдать
  валидный сертификат и перейти на полноценный HTTPS-клиент.
- Redis TCP монитор: `type: 'tcp'`, `hostname`, `port`; поле `url` не задавать.

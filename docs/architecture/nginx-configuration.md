---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-24'
---

# Nginx Configuration Guide - ERNI-KI

> **Version:** 9.0 | **Date:** 2025-09-11 | **Status:** Production Ready

## Overview

Nginx in ERNI-KI serves as a reverse proxy with SSL/TLS support, WebSocket, rate
limiting, and caching. After v9.0 optimization, the configuration has become
modular and maintainable.

## Configuration Architecture

### File Structure

```bash
conf/nginx/
 nginx.conf # Main configuration
 Map directives # Conditional logic
 Upstream blocks # Backend servers
 Rate limiting zones # DDoS protection
 Proxy cache settings # Caching
 conf.d/default.conf # Server blocks
 Server :80 # HTTP → HTTPS redirect
 Server :443 # HTTPS with full functionality
 Server :8080 # Cloudflare tunnel
 includes/ # Reusable modules
 openwebui-common.conf # OpenWebUI proxy settings
 searxng-api-common.conf # SearXNG API configuration
 searxng-web-common.conf # SearXNG web interface
 websocket-common.conf # WebSocket proxy
```

## Key Components

### 1. Map Directives (nginx.conf)

```nginx
# Cloudflare tunnel detection
map $server_port $is_cloudflare_tunnel {
 default 0;
 8080 1;
}

# Conditional X-Request-ID header
map $is_cloudflare_tunnel $request_id_header {
 default "";
 1 $final_request_id;
}

# Universal variable for include files
map $is_cloudflare_tunnel $universal_request_id {
 default $final_request_id;
 1 $final_request_id;
}
```

## 2. Upstream Blocks

```nginx
# OpenWebUI backend
upstream openwebui_backend {
 server openwebui:8080 max_fails=3 fail_timeout=30s weight=1;
 keepalive 64;
 keepalive_requests 1000;
 keepalive_timeout 60s;
}

# SearXNG upstream for RAG search
upstream searxngUpstream {
 server searxng:8080 max_fails=3 fail_timeout=30s weight=1;
 keepalive 48;
 keepalive_requests 200;
 keepalive_timeout 60s;
}
```

## 3. Rate Limiting

```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=general:20m rate=50r/s;
limit_req_zone $binary_remote_addr zone=api:20m rate=30r/s;
limit_req_zone $binary_remote_addr zone=searxng_api:10m rate=60r/s;
limit_req_zone $binary_remote_addr zone=websocket:10m rate=20r/s;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=perip:10m;
limit_conn_zone $server_name zone=perserver:10m;
```

## Server Blocks

### Port 80 - HTTP Redirect

```nginx
server {
 listen 80;
 server_name ki.erni-gruppe.ch diz.zone localhost;

 # Force redirect to HTTPS
 return 301 https://$host$request_uri;
}
```

## Port 443 - HTTPS Production

```nginx
server {
 listen 443 ssl;
 http2 on;
 server_name ki.erni-gruppe.ch diz.zone localhost;

 # SSL configuration
 ssl_certificate /etc/nginx/ssl/nginx-fullchain.crt;
 ssl_certificate_key /etc/nginx/ssl/nginx.key;
 ssl_protocols TLSv1.2 TLSv1.3;
 ssl_verify_client off; # Fix for localhost

 # Security headers (optimized for localhost)
 add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' localhost:*; ...";
 add_header Access-Control-Allow-Origin "https://ki.erni-gruppe.ch https://localhost ...";
}
```

## Port 8080 - Cloudflare Tunnel

```nginx
server {
 listen 8080;
 server_name ki.erni-gruppe.ch diz.zone localhost;

 # Optimized for external access
 # No HTTPS redirects
 # Uses $request_id_header for logging
}
```

## Include Files

### openwebui-common.conf

```nginx
# Common settings for OpenWebUI proxy
limit_req zone=general burst=20 nodelay;
limit_conn perip 30;
limit_conn perserver 2000;

# Standard proxy headers
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Request-ID $universal_request_id;

# HTTP version and connections
proxy_http_version 1.1;
proxy_set_header Connection "";

# Timeouts
proxy_connect_timeout 30s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

# Proxy to OpenWebUI
proxy_pass http://openwebui_backend;
```

## searxng-api-common.conf

```nginx
# Rate limiting for SearXNG API
limit_req zone=searxng_api burst=30 nodelay;
limit_req_status 429;

# SearXNG response caching
proxy_cache searxng_cache;
proxy_cache_valid 200 5m;
proxy_cache_key "$scheme$request_method$host$request_uri";

# URL rewriting for API
rewrite ^/api/searxng/(.*)$ /$1 break;

# Proxy to SearXNG upstream
proxy_pass http://searxngUpstream;
proxy_set_header X-Request-ID $universal_request_id;

# Timeouts for search queries
proxy_connect_timeout 5s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;
```

## API Endpoints

### Main Endpoints

| Endpoint              | Status | Description             | Response Time |
| --------------------- | ------ | ----------------------- | ------------- |
| `/health`             |        | System health check     | <100ms        |
| `/api/config`         |        | System configuration    | <200ms        |
| `/api/searxng/search` |        | RAG web search          | <2s           |
| `/api/mcp/`           |        | Model Context Protocol  | <500ms        |
| WebSocket endpoints   |        | Real-time communication | <50ms         |

### Usage Examples

```bash
# System health check
curl http://localhost:8080/health
# Response: {"status":true}

# SearXNG search for RAG
curl "http://localhost:8080/api/searxng/search?q=test&format=json"
# Response: JSON with search results (31 results from 4500)

# System configuration
curl http://localhost:8080/api/config
# Response: JSON with OpenWebUI settings
```

## Administration

### Applying Changes

```bash
# Configuration check
docker exec erni-ki-nginx-1 nginx -t

# Hot-reload without restart
docker exec erni-ki-nginx-1 nginx -s reload

# Copy include files
docker cp conf/nginx/includes/ erni-ki-nginx-1:/etc/nginx/
```

## Monitoring

```bash
# Check logs
docker logs --tail=20 erni-ki-nginx-1

# Container status
docker ps | grep nginx

# Check ports
netstat -tlnp | grep nginx
```

## Troubleshooting

### Common Issues

1. **404 on API endpoints**

- Check include files in container
- Verify upstream blocks are correct

2. **WebSocket connections not working**

- Check websocket-common.conf
- Ensure Upgrade headers are present

3. **SSL errors on localhost**

- Check ssl_verify_client off
- Verify CSP policy is correct

### Diagnostic Commands

```bash
# Check nginx configuration
docker exec erni-ki-nginx-1 nginx -T

# Check upstream status
docker exec erni-ki-nginx-1 curl -s http://openwebui:8080/health

# Check include files
docker exec erni-ki-nginx-1 ls -la /etc/nginx/includes/
```

## Performance Metrics

- **API response time:** <2 seconds
- **WebSocket latency:** <50ms
- **SSL handshake:** <100ms
- **Cache hit ratio:** >80%
- **Rate limiting:** 60 req/s for SearXNG API

## Security

- **SSL/TLS:** TLSv1.2, TLSv1.3
- **HSTS:** max-age=31536000
- **CSP:** Optimized for localhost and production
- **Rate limiting:** DDoS attack protection
- **CORS:** Configured for allowed domains

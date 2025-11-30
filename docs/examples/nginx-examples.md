---
language: en
translation_status: complete
doc_version: '2025.11'
last_updated: '2025-11-30'
---

# ERNI-KI Nginx Reverse Proxy Configuration Examples

Complete Nginx reverse proxy configurations for ERNI-KI deployment scenarios.
These examples cover SSL/TLS termination, load balancing, performance
optimization, and security hardening.

## Table of Contents

1. [Basic Reverse Proxy](#basic-reverse-proxy)
2. [Production with SSL/TLS](#production-with-ssltls)
3. [Load Balancing Multiple Instances](#load-balancing-multiple-instances)
4. [Performance Optimization](#performance-optimization)
5. [Security Hardening](#security-hardening)
6. [Custom Header Injection](#custom-header-injection)
7. [Rate Limiting](#rate-limiting)
8. [Caching Strategy](#caching-strategy)

---

## Basic Reverse Proxy

This is the minimal configuration for proxying requests to ERNI-KI services.

```nginx
upstream erni_ki_openwebui {
    server openwebui:8080;
}

upstream erni_ki_ollama {
    server ollama:11434;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://erni_ki_openwebui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ollama {
        proxy_pass http://erni_ki_ollama;
        proxy_set_header Host $host;
    }
}
```

---

## Production with SSL/TLS

Production-grade configuration with SSL/TLS termination, security headers, and
HSTS.

```nginx
upstream erni_ki_openwebui {
    server openwebui:8080 max_fails=3 fail_timeout=30s;
}

upstream erni_ki_ollama {
    server ollama:11434 max_fails=3 fail_timeout=30s;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com www.example.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL Configuration
    ssl_certificate /etc/nginx/certs/tls.crt;
    ssl_certificate_key /etc/nginx/certs/tls.key;

    # SSL/TLS Hardening
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

    # Proxy to OpenWebUI
    location / {
        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        # Connection settings
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;

        # Error handling
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
        proxy_next_upstream_tries 2;
        proxy_next_upstream_timeout 10s;
    }

    # Websocket support for chat
    location /api/ws {
        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    # Ollama API
    location /api/ollama {
        proxy_pass http://erni_ki_ollama;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;

        # Long-running requests
        proxy_connect_timeout 120s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

---

## Load Balancing Multiple Instances

Configuration for distributing traffic across multiple OpenWebUI instances.

```nginx
upstream erni_ki_pool {
    # Least connections load balancing strategy
    least_conn;

    server openwebui1:8080 max_fails=3 fail_timeout=30s weight=1;
    server openwebui2:8080 max_fails=3 fail_timeout=30s weight=1;
    server openwebui3:8080 max_fails=3 fail_timeout=30s weight=1;

    # Keepalive connections to backend
    keepalive 32;
}

upstream erni_ki_ollama_pool {
    # Round-robin for Ollama
    round_robin;

    server ollama1:11434 max_fails=2 fail_timeout=30s;
    server ollama2:11434 max_fails=2 fail_timeout=30s;

    keepalive 16;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration (see Production example above)

    # Health check endpoint
    location /health {
        access_log off;
        proxy_pass http://erni_ki_pool;
    }

    # Main application
    location / {
        proxy_pass http://erni_ki_pool;
        proxy_http_version 1.1;

        # Connection pooling
        proxy_set_header Connection "";

        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Session persistence (optional)
        proxy_cookie_path / "/";
        proxy_cookie_flags ~ secure httponly samesite=lax;

        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Ollama load balanced
    location /api/ollama {
        proxy_pass http://erni_ki_ollama_pool;
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Longer timeouts for model operations
        proxy_connect_timeout 60s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
```

---

## Performance Optimization

Configuration optimized for high throughput and low latency.

```nginx
# Performance tuning
worker_processes auto;
worker_connections 8192;
worker_rlimit_nofile 65535;

# Buffer optimization
client_body_buffer_size 128k;
client_max_body_size 1G;
client_header_buffer_size 1k;
large_client_header_buffers 4 16k;

# Gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1000;
gzip_proxied any;
gzip_types text/plain text/css text/xml text/javascript
           application/x-javascript application/xml+rss
           application/json application/javascript;
gzip_comp_level 6;
gzip_disable "msie6";

upstream erni_ki_openwebui {
    # IP hash for session persistence
    ip_hash;

    server openwebui1:8080 max_fails=3 fail_timeout=30s;
    server openwebui2:8080 max_fails=3 fail_timeout=30s;
    server openwebui3:8080 max_fails=3 fail_timeout=30s;

    # Keepalive
    keepalive 64;
}

# Connection optimization
upstream erni_ki_ollama {
    server ollama:11434;
    keepalive 32;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration

    # Logging optimization
    access_log /var/log/nginx/access.log main buffer=32k flush=5s;
    error_log /var/log/nginx/error.log warn;

    # Main location
    location / {
        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        # Connection optimization
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Timeouts (shorter for better performance)
        proxy_connect_timeout 10s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;

        # Large buffer for response
        proxy_buffering on;
        proxy_buffer_size 32k;
        proxy_buffers 16 32k;
        proxy_busy_buffers_size 64k;
    }

    # Streaming responses (chunked)
    location /api/chat/stream {
        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        # Disable buffering for streaming
        proxy_buffering off;
        proxy_request_buffering off;

        # Connection settings
        proxy_set_header Connection "";
        proxy_set_header Host $host;

        # Long timeouts for streaming
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    # Ollama with optimization
    location /api/ollama {
        proxy_pass http://erni_ki_ollama;
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Large buffer for model downloads
        proxy_buffer_size 1m;
        proxy_buffers 16 1m;

        # Long timeouts for model operations
        proxy_connect_timeout 60s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }
}
```

---

## Security Hardening

Additional security measures and attack prevention.

```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general_limit:10m rate=100r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

upstream erni_ki_openwebui {
    server openwebui:8080;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # Hide version
    server_tokens off;

    # Prevent MIME type sniffing
    types_hash_max_size 2048;
    types_hash_bucket_size 64;

    # Main application
    location / {
        # Rate limiting
        limit_req zone=general_limit burst=20 nodelay;
        limit_conn conn_limit 10;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        # Security headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Remove sensitive headers from backend
        proxy_pass_request_headers on;
        proxy_hide_header X-Powered-By;
        proxy_hide_header Server;

        # Validate redirect
        proxy_redirect off;
    }

    # Stricter rate limiting for API endpoints
    location /api/ {
        limit_req zone=api_limit burst=5 nodelay;
        limit_conn conn_limit 5;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Deny direct access to sensitive paths
    location ~ ^/(admin|config|debug|phpinfo) {
        deny all;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block common exploit attempts
    location ~ ~*\.(php|phtml|php3|php4|php5|php6|php7|phps|pht|phar|inc|hphp|ctp|shtml)$ {
        deny all;
    }
}
```

---

## Custom Header Injection

Injecting custom headers for authentication, tracing, and request
identification.

```nginx
upstream erni_ki_openwebui {
    server openwebui:8080;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration

    location / {
        # Generate request ID for tracing
        map $request_id $request_uuid {
            ~^(?P<first>\w{8})(?P<second>\w{4})(?P<third>\w{4})(?P<fourth>\w{4})(?P<fifth>\w{12})$
                "${first}-${second}-${third}-${fourth}-${fifth}";
            default $request_id;
        }

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;

        # Custom headers
        proxy_set_header X-Request-ID $request_uuid;
        proxy_set_header X-Request-Time $request_time;
        proxy_set_header X-Client-IP $remote_addr;
        proxy_set_header X-Forwarded-By "nginx/$nginx_version";

        # User authentication headers (if using external auth)
        # proxy_set_header X-Auth-User $remote_user;
        # proxy_set_header X-Auth-Groups $auth_groups;

        # Custom application headers
        proxy_set_header X-Application "ERNI-KI";
        proxy_set_header X-Deployment-Environment "production";
    }
}
```

---

## Rate Limiting

Detailed rate limiting configuration to prevent abuse and DDoS.

```nginx
# Rate limiting zones with different strategies
limit_req_zone $binary_remote_addr zone=global_limit:10m rate=100r/s;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=20r/s;
limit_req_zone $binary_remote_addr zone=chat_limit:10m rate=5r/m;
limit_req_zone $http_x_api_key zone=api_key_limit:10m rate=1000r/m;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_conn_zone $server_name zone=server:10m;

upstream erni_ki_openwebui {
    server openwebui:8080;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration

    # Global rate limiting
    location / {
        limit_req zone=global_limit burst=50 nodelay;
        limit_conn addr 10;
        limit_conn server 1000;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # API rate limiting
    location /api/ {
        limit_req zone=api_limit burst=10 nodelay;
        limit_conn addr 5;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Chat API (stricter limiting)
    location /api/chat {
        limit_req zone=chat_limit burst=2 nodelay;
        limit_conn addr 1;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Return status code for rate limit exceeded
        limit_req_status 429;
    }

    # API key based rate limiting (for authenticated requests)
    location /api/v1/ {
        limit_req zone=api_key_limit burst=100 nodelay;
        limit_conn addr 20;

        proxy_pass http://erni_ki_openwebui;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-API-Key $http_x_api_key;
    }
}
```

---

## Caching Strategy

Nginx caching configuration for improved performance.

```nginx
# Cache paths and zones
proxy_cache_path /var/cache/nginx/static levels=1:2 keys_zone=static_cache:10m max_size=1g inactive=60d use_temp_path=off;
proxy_cache_path /var/cache/nginx/dynamic levels=1:2 keys_zone=dynamic_cache:10m max_size=500m inactive=1h use_temp_path=off;
proxy_cache_path /var/cache/nginx/api levels=1:2 keys_zone=api_cache:10m max_size=100m inactive=10m use_temp_path=off;

upstream erni_ki_openwebui {
    server openwebui:8080;
}

server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL configuration

    # Static assets caching (CSS, JS, images)
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf)$ {
        proxy_pass http://erni_ki_openwebui;

        proxy_cache static_cache;
        proxy_cache_valid 200 30d;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;

        proxy_set_header Host $host;

        add_header Cache-Control "public, max-age=2592000, immutable";
        add_header X-Cache-Status $upstream_cache_status;
    }

    # Dynamic content caching (HTML, API responses)
    location / {
        proxy_pass http://erni_ki_openwebui;

        proxy_cache dynamic_cache;
        proxy_cache_valid 200 1h;
        proxy_cache_valid 404 5m;
        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
        proxy_cache_bypass $http_pragma $http_authorization;
        proxy_no_cache $http_pragma $http_authorization;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        add_header Cache-Control "public, max-age=3600";
        add_header X-Cache-Status $upstream_cache_status;
    }

    # API caching (conservative)
    location /api/ {
        proxy_pass http://erni_ki_openwebui;

        proxy_cache api_cache;
        proxy_cache_valid 200 10m;
        proxy_cache_valid 304 10m;
        proxy_cache_key "$scheme$request_method$host$request_uri";
        proxy_cache_bypass $http_cache_control;
        proxy_no_cache $http_pragma;

        proxy_set_header Host $host;

        add_header X-Cache-Status $upstream_cache_status;
    }

    # Don't cache POST/PUT/DELETE requests
    location ~ ^/api/.*$ {
        limit_except GET {
            proxy_no_cache 1;
            proxy_cache_bypass 1;
        }
    }

    # Cache clearing endpoint
    location ~ /cache/purge(/.*)?$ {
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        deny all;

        proxy_cache_purge static_cache $scheme$proxy_host$request_uri;
        proxy_cache_purge dynamic_cache $scheme$proxy_host$request_uri;
        proxy_cache_purge api_cache $scheme$request_method$proxy_host$request_uri;
    }
}
```

---

## Complete Production Configuration Template

```nginx
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 8192;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main buffer=32k flush=5s;

    # Performance optimization
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 1G;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1000;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/x-javascript application/json application/xml+rss;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=100r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=20r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;

    # Upstream configuration
    upstream erni_ki_openwebui {
        least_conn;
        server openwebui:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    upstream erni_ki_ollama {
        server ollama:11434 max_fails=2 fail_timeout=30s;
        keepalive 16;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }

    # Main HTTPS server
    server {
        listen 443 ssl http2 default_server;
        server_name example.com www.example.com;

        ssl_certificate /etc/nginx/certs/tls.crt;
        ssl_certificate_key /etc/nginx/certs/tls.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Root location
        location / {
            limit_req zone=general burst=50 nodelay;
            limit_conn addr 10;

            proxy_pass http://erni_ki_openwebui;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # API with stricter rate limiting
        location /api/ {
            limit_req zone=api burst=10 nodelay;

            proxy_pass http://erni_ki_openwebui;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        # Ollama
        location /ollama/ {
            proxy_pass http://erni_ki_ollama/;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host $host;

            proxy_connect_timeout 60s;
            proxy_send_timeout 300s;
            proxy_read_timeout 300s;
        }
    }
}
```

---

## Testing and Verification

Test your Nginx configuration before deploying:

```bash
# Syntax check
nginx -t

# Reload configuration
nginx -s reload

# Check running processes
ps aux | grep nginx

# Verify listening ports
netstat -tlnp | grep nginx

# Test SSL certificate
openssl s_client -connect example.com:443

# Monitor Nginx logs in real-time
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## Performance Tuning Checklist

- Enable `http2` for multiplexing
- Configure upstream health checks
- Optimize buffer sizes for your workload
- Enable gzip compression
- Use connection pooling (keepalive)
- Implement caching strategy
- Configure rate limiting appropriately
- Use SSL session caching
- Monitor upstream response times
- Test failover and recovery behavior

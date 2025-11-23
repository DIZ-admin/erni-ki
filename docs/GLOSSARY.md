---
language: ru
translation_status: complete
doc_version: '2025.11'
---

# Glossary

This glossary defines key terms and concepts used throughout the ERNI-KI
documentation.

## AI & ML Terms

### Context7

A context engineering framework integrated with LiteLLM that enhances AI
responses by providing better context management and advanced reasoning
capabilities. Used for improving the quality and relevance of LLM outputs.

### Docling

An AI-powered document processing service that provides:

- Multi-language OCR (EN, DE, FR, IT)
- Text extraction from PDF, DOCX, PPTX
- Structural analysis of documents
- Table and image recognition

Port: 5001

### EdgeTTS

Microsoft Edge Text-to-Speech service providing high-quality speech synthesis
with:

- Multiple language support
- Various voice options
- Streaming audio output
- Integration with Open WebUI

Port: 5050

### LiteLLM

A unified API gateway for Large Language Models that:

- Provides consistent API across multiple LLM providers (OpenAI, Anthropic,
  Google, Azure)
- Handles load balancing between models
- Manages usage monitoring and cost tracking
- Implements caching and rate limiting
- Supports Context Engineering via Context7

Port: 4000

### MCP (Model Context Protocol)

A protocol for extending AI capabilities through tools and integrations. The MCP
Server provides:

- Time tool
- PostgreSQL database access
- Filesystem operations
- Memory management
- Custom tool integration

Port: 8000

### Ollama

A local LLM server with:

- GPU acceleration support (NVIDIA CUDA)
- Automatic GPU memory management
- OpenAI-compatible API
- Support for multiple models
- Streaming responses

Port: 11434

### RAG (Retrieval-Augmented Generation)

A technique that enhances AI responses by retrieving relevant information from
external sources before generating answers. ERNI-KI implements RAG through:

- SearXNG for web search
- Document processing via Docling and Tika
- Vector storage in PostgreSQL with pgvector
- Custom RAG exporter for SLA monitoring

Port for RAG Exporter: 9808

## Infrastructure Terms

### Backrest

A backup solution built on Restic providing:

- Automated incremental backups
- AES-256 encryption
- Deduplication and compression
- Web interface for management
- REST API for automation
- Retention policy: 7 daily + 4 weekly backups

Port: 9898

### Blackbox Exporter

A Prometheus exporter for probing endpoints over HTTP, HTTPS, DNS, TCP, and
ICMP. Used for:

- External service availability monitoring
- Health check validation
- Network connectivity testing

Port: 9115

### Cloudflared

Cloudflare Tunnel client that:

- Creates secure tunnels without open ports
- Provides automatic SSL certificate management
- Offers DDoS protection at Cloudflare level
- Enables geographic traffic distribution
- Currently manages 5 active domains

### pgvector

A PostgreSQL extension for vector similarity search, enabling:

- Efficient storage of embedding vectors
- Fast similarity searches for RAG
- Integration with AI/ML pipelines
- Currently storing 968 vector chunks (28MB)

### SearXNG

A privacy-respecting metasearch engine that:

- Aggregates results from multiple search engines (Google, Bing, DuckDuckGo,
  Brave, Startpage)
- Provides private search without tracking
- Offers JSON API for RAG integration
- Caches results in Redis
- Has rate limiting to prevent blocking

Port: 8080 (internal) API Endpoint: `/api/searxng/search` (via nginx proxy)

### Watchtower

An automated Docker image updater that:

- Monitors for new image versions
- Performs graceful service restarts
- Provides HTTP API for control
- Supports selective updates
- Sends update notifications

Port: 8091

## Monitoring Terms

### Alertmanager

Handles alerts from Prometheus:

- Groups and routes notifications
- Manages silences and inhibitions
- Integrates with Slack and PagerDuty
- Supports multi-channel delivery
- Queue monitoring via custom watchdog

Ports: 9093 (web UI), 9094 (cluster)

### Fluent Bit

Lightweight log processor and forwarder that:

- Collects logs from Docker containers
- Filters and transforms log data
- Sends logs to Loki
- Provides buffering for reliability
- Uses 15GB disk buffer for network outages

Ports: 24224 (input), 2020 (metrics)

### Grafana

Visualization and analytics platform featuring:

- 18 production dashboards
- Integration with Prometheus and Loki
- Custom alerting rules
- User and team management
- Dashboard provisioning

Port: 3000

### Loki

Log aggregation system that:

- Stores logs with labels (like Prometheus for logs)
- Integrates with Fluent Bit for log collection
- Provides LogQL query language
- Uses object storage (MinIO/S3) for chunks
- Implements 30-day retention policy
- Requires `X-Scope-OrgID: erni-ki` header

Port: 3100

### Prometheus

Metrics collection and alerting system:

- Scrapes metrics from 32 targets
- Stores time-series data (30-day retention)
- Executes 27 active alert rules
- Provides PromQL query language
- Supports service discovery

Port: 9091

## Exporters

### cAdvisor

Container Advisor for analyzing resource usage and performance of running
containers.

Port: 8081

### NVIDIA GPU Exporter

Exposes NVIDIA GPU metrics:

- GPU utilization percentage
- Memory usage
- Temperature
- Power consumption

Port: 9445

### Node Exporter

System-level metrics exporter:

- CPU, memory, disk, network stats
- Load averages
- Filesystem metrics
- Hardware monitoring

Port: 9101

### PostgreSQL Exporter

Database metrics exporter:

- Connection counts
- Query performance
- Cache hit ratios
- Lock statistics
- Auto-discovery of databases
- Uses IPv4→IPv6 proxy (socat) on port 9188

Port: 9187 (internal), 9188 (via proxy)

### RAG Exporter

Custom exporter for RAG performance:

- Response latency histogram
- Source count tracking
- SLA compliance monitoring

Port: 9808

### Redis Exporter

Cache performance metrics:

- Memory usage
- Client connections
- Hit/miss ratios
- Command statistics

Port: 9121

## Security Terms

### JWT (JSON Web Token)

Authentication tokens used by the Auth service for:

- Secure user sessions
- API authentication
- Integration with nginx auth_request
- Rate limiting for authentication

Auth Service Port: 9092

### Zero Trust

Security model where:

- No implicit trust based on network location
- All connections are authenticated and encrypted
- Implemented via Cloudflare Tunnels
- No exposed ports on public internet
- Defense in depth approach

## Network Terms

### Nginx

Reverse proxy and web server providing:

- SSL/TLS termination
- Rate limiting (100 req/min general, 10 req/min for SearXNG)
- WebSocket proxying
- Static file serving
- WAF (Web Application Firewall) functionality
- Modular configuration with includes

Ports: 80 (HTTP), 443 (HTTPS), 8080 (internal/Cloudflare tunnel)

### Socat Proxy

TCP proxy used for IPv4→IPv6 translation:

- Enables IPv4 Prometheus to connect to IPv6-only PostgreSQL Exporter
- Shared network namespace with exporter (\u003c1ms latency)
- Transparent proxying without application changes

Port: 9188 (IPv4 listener) → 9187 (IPv6 target)

## Storage Terms

### Redis

In-memory data structure store used for:

- Search query caching (SearXNG)
- User sessions (OpenWebUI)
- WebSocket connections
- Pub/Sub messaging
- Active defragmentation enabled
- 2GB memory limit with allkeys-lru eviction

Port: 6379

### PostgreSQL

Primary database (version 17) with:

- Shared database for OpenWebUI and LiteLLM
- pgvector extension for vector storage
- Optimized configuration (256MB shared buffers, 200 max connections)
- Aggressive autovacuum (4 workers, 15s naptime)
- 99.76% cache hit ratio
- Automated VACUUM every Sunday at 03:00

Port: 5432

## Operations Terms

### Cron Evidence

System for tracking automated job execution:

- Records job status (success/failure)
- Publishes metrics via node_exporter textfile collector
- Provides SLA monitoring via Prometheus alerts
- Metrics: `erni_cron_job_success`, `erni_cron_job_age_seconds`

### Health Check

Automated service health verification:

- Docker native healthchecks for all containers
- HTTP endpoint checks (\u003cservice\u003e/health, \u003cservice\u003e/metrics)
- TCP connectivity checks
- Process-based checks
- Prometheus scrape success monitoring

### Runbook

Operational procedures documenting:

- Service restart procedures
- Troubleshooting steps
- Incident response
- Backup and restore procedures
- Alert response cheat sheets

### SLA (Service Level Agreement)

Performance targets for services:

- OpenWebUI response time: \u003c5s
- SearXNG search time: \u003c3s
- RAG latency monitoring
- Database cache hit ratio: \u003e99%
- Container availability: 100%

### SLO (Service Level Objective)

Specific measurable targets:

- Tracked via SLO dashboards in Grafana
- Error budget calculations (0.5% target)
- Burn-rate monitoring
- Platform SRE Overview dashboard

## Acronyms

- **AI**: Artificial Intelligence
- **API**: Application Programming Interface
- **CUDA**: Compute Unified Device Architecture (NVIDIA's parallel computing
  platform)
- **GPU**: Graphics Processing Unit
- **HTTPS**: Hypertext Transfer Protocol Secure
- **JWT**: JSON Web Token
- **LLM**: Large Language Model
- **OCR**: Optical Character Recognition
- **RAG**: Retrieval-Augmented Generation
- **SLA**: Service Level Agreement
- **SLO**: Service Level Objective
- **SRE**: Site Reliability Engineering
- **SSL/TLS**: Secure Sockets Layer / Transport Layer Security
- **TTS**: Text-to-Speech
- **UI**: User Interface
- **VRAM**: Video Random Access Memory
- **WAF**: Web Application Firewall

## Version Information

This glossary reflects the state of ERNI-KI as of version 12.1 (November 2025).
For the most up-to-date information, refer to the main documentation at
`docs/overview.md`.

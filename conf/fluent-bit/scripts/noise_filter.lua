-- ============================================================================
-- Fluent Bit Lua Script - Noise Filter for ERNI-KI
-- Goal: Consolidate 12+ grep filters into single efficient Lua filter
-- ============================================================================
-- Version: 1.0.0
-- Created: 2025-12-16
-- Purpose: Filter noise logs in single pass instead of 12 regex passes
-- Performance: Expected 20-30% CPU reduction for Fluent Bit
-- ============================================================================

-- Pre-compiled pattern list for efficiency
-- Return codes: -1 = drop record, 1 = keep record, 2 = modify record

function filter_noise(tag, timestamp, record)
    local log = record["log"]
    local container_name = record["container_name"] or ""

    -- Fast path: if no log field, keep the record
    if log == nil then
        return 1, timestamp, record
    end

    -- ========================================================================
    -- PRIORITY 1: Cloudflared "context canceled" errors (85% of all warnings)
    -- These are normal behavior when users interrupt HTTP requests
    -- ========================================================================

    -- Pattern: context canceled.*cloudflared
    if string.find(log, "context canceled") and string.find(container_name, "cloudflared") then
        return -1, timestamp, record
    end

    -- Pattern: Incoming request ended abruptly.*context canceled
    if string.find(log, "Incoming request ended abruptly") and string.find(log, "context canceled") then
        return -1, timestamp, record
    end

    -- Pattern: Request failed.*context canceled
    if string.find(log, "Request failed") and string.find(log, "context canceled") then
        return -1, timestamp, record
    end

    -- Pattern: stream.*canceled by remote with error code 0
    if string.find(log, "stream") and string.find(log, "canceled by remote with error code 0") then
        return -1, timestamp, record
    end

    -- ========================================================================
    -- PRIORITY 2: MCP errors from OpenWebUI (non-critical)
    -- ========================================================================

    -- Pattern: Could not fetch tool server spec from.*mcp.*openapi.json
    if string.find(log, "Could not fetch tool server spec") and string.find(log, "mcp") then
        return -1, timestamp, record
    end

    -- Pattern: ContentTypeError.*mcp.*openapi.json
    if string.find(log, "ContentTypeError") and string.find(log, "mcp") then
        return -1, timestamp, record
    end

    -- ========================================================================
    -- PRIORITY 3: Informational noise
    -- ========================================================================

    -- Pattern: GET.*200.*nginx (nginx access logs for successful requests)
    -- Note: More specific check to avoid filtering error logs
    if string.find(log, "GET") and string.find(log, "200") and string.find(container_name, "nginx") then
        -- Only filter if it's a typical access log line (has HTTP method and status)
        if string.find(log, "HTTP/") then
            return -1, timestamp, record
        end
    end

    -- Pattern: level=debug (case insensitive)
    local log_lower = string.lower(log)
    if string.find(log_lower, "level=debug") or string.find(log_lower, '"level":"debug"') then
        return -1, timestamp, record
    end

    -- Pattern: GET.*/health.*200 (health check requests)
    if string.find(log, "/health") and string.find(log, "200") then
        return -1, timestamp, record
    end

    -- Also filter /healthz and /ready endpoints
    if string.find(log, "/healthz") or string.find(log, "/ready") then
        if string.find(log, "200") then
            return -1, timestamp, record
        end
    end

    -- ========================================================================
    -- PRIORITY 3: Exporter-specific noise
    -- ========================================================================

    -- Pattern: couldn't get dbus connection.*systemd (node-exporter, 99.5% of ERROR)
    if string.find(log, "couldn't get dbus connection") and string.find(log, "systemd") then
        return -1, timestamp, record
    end

    -- Pattern: connection reset by peer.*node-exporter
    if string.find(log, "connection reset by peer") and string.find(container_name, "node%-exporter") then
        return -1, timestamp, record
    end

    -- Pattern: Cannot read smaps files for any PID from CONTAINER (cAdvisor)
    if string.find(log, "Cannot read smaps files for any PID from CONTAINER") then
        return -1, timestamp, record
    end

    -- Pattern: failed to parse response body.*html (nginx-exporter)
    if string.find(log, "failed to parse response body") and string.find(log, "html") then
        return -1, timestamp, record
    end

    -- ========================================================================
    -- PRIORITY 3: Additional common noise patterns
    -- ========================================================================

    -- Prometheus scrape timeouts (normal for slow endpoints)
    if string.find(log, "context deadline exceeded") and string.find(container_name, "prometheus") then
        return -1, timestamp, record
    end

    -- Loki compaction logs (normal operation)
    if string.find(log, "compaction finished") and string.find(container_name, "loki") then
        return -1, timestamp, record
    end

    -- Redis PING responses
    if log == "PONG" or log == "+PONG" then
        return -1, timestamp, record
    end

    -- ========================================================================
    -- DEFAULT: Keep the record
    -- ========================================================================
    return 1, timestamp, record
end

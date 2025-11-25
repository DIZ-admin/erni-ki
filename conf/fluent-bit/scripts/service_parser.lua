-- ============================================================================
-- Fluent Bit Lua Script - Service Name Parser for ERNI-KI
-- Goal: Extract clean service name from container_name
-- ============================================================================
-- Version: 1.0.0
-- Created: 2025-09-01
-- Purpose: Parse service names for better log categorization
-- ============================================================================

function parse_service_name(tag, timestamp, record)
    -- Get raw container name
    local service_raw = record["service_raw"]

    if service_raw == nil then
        record["service"] = "unknown"
        return 1, timestamp, record
    end

    -- Strip prefix "erni-ki-" and suffix "-1", "-2", etc.
    local service_name = string.gsub(service_raw, "^erni%-ki%-", "")
    service_name = string.gsub(service_name, "%-[0-9]+$", "")

    -- Special-case mapping
    local service_mapping = {
        ["db"] = "postgres",
        ["mcposerver"] = "mcp",
        ["fluent-bit"] = "logging",
        ["nginx-exporter"] = "nginx-metrics",
        ["redis-exporter"] = "redis-metrics",
        ["postgres-exporter"] = "postgres-metrics",
        ["ollama-exporter"] = "ollama-metrics",
        ["nvidia-exporter"] = "gpu-metrics",
        ["node-exporter"] = "system-metrics",
        ["blackbox-exporter"] = "network-metrics",
        ["webhook-receiver"] = "webhooks"
    }

    -- Apply mapping when available
    if service_mapping[service_name] then
        service_name = service_mapping[service_name]
    end

    -- Set final service name
    record["service"] = service_name

    -- Add service category for grouping
    local service_categories = {
        ["nginx"] = "web",
        ["openwebui"] = "web",
        ["ollama"] = "ai",
        ["litellm"] = "ai",
        ["postgres"] = "database",
        ["redis"] = "database",
        ["searxng"] = "search",
        ["prometheus"] = "monitoring",
        ["grafana"] = "monitoring",
        ["loki"] = "monitoring",
        ["alertmanager"] = "monitoring",
        ["logging"] = "infrastructure",
        ["cloudflared"] = "infrastructure",
        ["watchtower"] = "infrastructure",
        ["backrest"] = "backup",
        ["auth"] = "security",
        ["mcp"] = "integration",
        ["tika"] = "processing",
        ["edgetts"] = "processing"
    }

    -- Add category
    record["service_category"] = service_categories[service_name] or "other"

    -- Add metrics flag for monitoring
    if string.find(service_name, "metrics") then
        record["service_category"] = "metrics"
        record["is_metrics"] = true
    else
        record["is_metrics"] = false
    end

    return 1, timestamp, record
end

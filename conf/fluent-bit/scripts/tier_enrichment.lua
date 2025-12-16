-- ============================================================================
-- Fluent Bit Lua Script - Tier Enrichment for ERNI-KI
-- Goal: Add tier labels for tier-based processing (throttling, routing)
-- ============================================================================
-- Version: 1.0.0
-- Created: 2025-12-16
-- Purpose: Classify services into tiers for differential log processing
-- ============================================================================

-- Tier definitions matching Docker Compose 4-tier logging strategy:
-- TIER 1 (critical): Maximum reliability, NO throttling
-- TIER 2 (important): Standard reliability, NO throttling
-- TIER 3 (auxiliary): Auxiliary services, light throttling
-- TIER 4 (monitoring): Monitoring stack, aggressive throttling

local critical_services = {
    ["openwebui"] = true,
    ["ollama"] = true,
    ["postgres"] = true,
    ["nginx"] = true,
    ["db"] = true  -- alias for postgres
}

local important_services = {
    ["searxng"] = true,
    ["redis"] = true,
    ["backrest"] = true,
    ["auth"] = true,
    ["cloudflared"] = true,
    ["litellm"] = true
}

local monitoring_services = {
    ["prometheus"] = true,
    ["grafana"] = true,
    ["loki"] = true,
    ["alertmanager"] = true,
    ["fluent-bit"] = true,
    ["logging"] = true,
    ["uptime-kuma"] = true
}

-- Metrics exporters are also monitoring tier
local metrics_patterns = {
    "exporter",
    "metrics",
    "cadvisor"
}

function enrich_tier(tag, timestamp, record)
    local service = record["service"]
    local container_name = record["container_name"] or ""

    -- Default tier
    local tier = "auxiliary"

    if service then
        -- Check critical tier
        if critical_services[service] then
            tier = "critical"
        -- Check important tier
        elseif important_services[service] then
            tier = "important"
        -- Check monitoring tier
        elseif monitoring_services[service] then
            tier = "monitoring"
        else
            -- Check for metrics patterns
            for _, pattern in ipairs(metrics_patterns) do
                if string.find(service, pattern) then
                    tier = "monitoring"
                    break
                end
            end
        end
    else
        -- Fallback: check container_name for tier detection
        local name_lower = string.lower(container_name)

        for svc, _ in pairs(critical_services) do
            if string.find(name_lower, svc) then
                tier = "critical"
                break
            end
        end

        if tier == "auxiliary" then
            for svc, _ in pairs(important_services) do
                if string.find(name_lower, svc) then
                    tier = "important"
                    break
                end
            end
        end

        if tier == "auxiliary" then
            for svc, _ in pairs(monitoring_services) do
                if string.find(name_lower, svc) then
                    tier = "monitoring"
                    break
                end
            end

            -- Check metrics patterns in container name
            for _, pattern in ipairs(metrics_patterns) do
                if string.find(name_lower, pattern) then
                    tier = "monitoring"
                    break
                end
            end
        end
    end

    -- Set tier field
    record["tier"] = tier

    -- Set should_throttle flag for downstream processing
    -- Critical and important services should NOT be throttled
    if tier == "critical" or tier == "important" then
        record["should_throttle"] = "false"
    else
        record["should_throttle"] = "true"
    end

    return 1, timestamp, record
end

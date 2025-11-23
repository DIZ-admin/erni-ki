#!/bin/bash

# SearXNG Engine Monitoring Script for ERNI-KI
# Monitors engine errors and automatically disables problematic ones

set -euo pipefail

# === CONFIGURATION ===
LOG_FILE="/home/konstantin/Documents/augment-projects/erni-ki/logs/searxng-engine-monitor.log"
ERROR_THRESHOLD=5  # Error count threshold to disable an engine
TIME_WINDOW=300    # Time window in seconds (5 minutes)
SEARXNG_CONTAINER="erni-ki-searxng-1"

# === FUNCTIONS ===
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_engine_errors() {
    local engine="$1"
    local error_count

    # Count errors over the last TIME_WINDOW seconds
    error_count=$(docker logs --since="${TIME_WINDOW}s" "$SEARXNG_CONTAINER" 2>/dev/null | \
                  grep -c "ERROR:searx.engines.${engine}:" || echo "0")

    echo "$error_count"
}

disable_engine() {
    local engine="$1"
    log_message "WARNING: Disabling problematic engine: $engine"

    # Backup configuration
    cp conf/searxng/settings.yml "conf/searxng/settings.yml.backup.$(date +%Y%m%d_%H%M%S)"

    # Disable engine in configuration
    sed -i "/name: $engine/,/disabled:/ s/disabled: false/disabled: true/" conf/searxng/settings.yml

    # Restart SearXNG to apply changes
    docker-compose restart searxng

    log_message "INFO: Engine $engine disabled and SearXNG restarted"
}

# === MAIN LOGIC ===
main() {
    log_message "INFO: Starting SearXNG engine monitoring"

    # Engines to monitor
    engines=("bing" "google" "duckduckgo" "startpage" "brave")

    for engine in "${engines[@]}"; do
        error_count=$(check_engine_errors "$engine")

        if [[ $error_count -gt $ERROR_THRESHOLD ]]; then
            log_message "ALERT: Engine $engine has $error_count errors in the last $TIME_WINDOW seconds"

            # Check if engine is already disabled
            if grep -A2 "name: $engine" conf/searxng/settings.yml | grep -q "disabled: false"; then
                disable_engine "$engine"
            else
                log_message "INFO: Engine $engine is already disabled"
            fi
        else
            log_message "INFO: Engine $engine: $error_count errors (normal)"
        fi
    done

    log_message "INFO: Monitoring finished"
}

# === ЗАПУСК ===
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

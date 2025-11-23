#!/bin/bash
# ERNI-KI log volume analysis

echo "=== ERNI-KI Log Volume Analysis ==="
echo "Date: $(date)"
echo

# Docker container log sizes
echo "1. Docker container log sizes:"
docker system df

echo
echo "2. Top 10 containers by log volume (last hour):"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki); do
    lines=$(docker logs --since 1h "$container" 2>&1 | wc -l)
    echo "$container: $lines lines"
done | sort -k2 -nr | head -10

echo
echo "3. Error analysis (last hour):"
for container in $(docker ps --format "{{.Names}}" | grep erni-ki | head -5); do
    errors=$(docker logs --since 1h "$container" 2>&1 | grep -i -E "(error|critical|fatal)" | wc -l)
    if [[ $errors -gt 0 ]]; then
        echo "$container: $errors errors"
    fi
done

#!/bin/bash

# ===================================================================
# ERNI-KI Post-WebSocket Fix Monitor
# Monitoring after WebSocket issue fix
# Author: Alteon Schulz, Tech Lead
# Created: 2025-09-11
# ===================================================================

echo "🔍 === ERNI-KI Post-WebSocket Fix Monitor ==="
echo "📅 Date: $(date)"
echo "⏰ Analysis time: $(date '+%H:%M:%S')"
echo ""

# Colored output helper
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo "✅ $message" ;;
        "WARNING") echo "⚠️  $message" ;;
        "ERROR") echo "❌ $message" ;;
        "INFO") echo "ℹ️  $message" ;;
    esac
}

# 1. WebSocket errors (critical indicator)
echo "🌐 === WEBSOCKET ANALYSIS ==="
websocket_errors_30m=$(docker-compose logs openwebui --since 30m 2>/dev/null | grep -c "socket.io.*400" || echo "0")
websocket_errors_1h=$(docker-compose logs openwebui --since 1h 2>/dev/null | grep -c "socket.io.*400" || echo "0")

if [ "$websocket_errors_30m" -eq 0 ]; then
    print_status "SUCCESS" "WebSocket errors (30m): $websocket_errors_30m"
elif [ "$websocket_errors_30m" -lt 50 ]; then
    print_status "WARNING" "WebSocket errors (30m): $websocket_errors_30m (improving)"
else
    print_status "ERROR" "WebSocket errors (30m): $websocket_errors_30m (needs attention)"
fi

echo "   📊 WebSocket errors (1h): $websocket_errors_1h"
echo ""

# 2. SearXNG errors (high priority)
echo "🔍 === SEARXNG ANALYSIS ==="
searxng_errors_1h=$(docker-compose logs searxng --since 1h 2>/dev/null | grep -c -E "(ERROR|WARN)" || echo "0")
searxng_errors_2h=$(docker-compose logs searxng --since 2h 2>/dev/null | grep -c -E "(ERROR|WARN)" || echo "0")

if [ "$searxng_errors_1h" -lt 100 ]; then
    print_status "SUCCESS" "SearXNG errors (1h): $searxng_errors_1h"
elif [ "$searxng_errors_1h" -lt 300 ]; then
    print_status "WARNING" "SearXNG errors (1h): $searxng_errors_1h (moderate)"
else
    print_status "ERROR" "SearXNG errors (1h): $searxng_errors_1h (high)"
fi

echo "   📊 SearXNG errors (2h): $searxng_errors_2h"
echo ""

# 3. PostgreSQL FATAL errors
echo "🗄️ === POSTGRESQL ANALYSIS ==="
postgres_fatal_1h=$(docker-compose logs db --since 1h 2>/dev/null | grep -c "FATAL" || echo "0")
postgres_errors_1h=$(docker-compose logs db --since 1h 2>/dev/null | grep -c -E "(ERROR|WARN)" || echo "0")

if [ "$postgres_fatal_1h" -eq 0 ]; then
    print_status "SUCCESS" "PostgreSQL FATAL errors (1h): $postgres_fatal_1h"
else
    print_status "ERROR" "PostgreSQL FATAL errors (1h): $postgres_fatal_1h"
fi

echo "   📊 PostgreSQL general errors (1h): $postgres_errors_1h"
echo ""

# 4. RAG performance
echo "🚀 === RAG PERFORMANCE ==="
echo "   🧪 Testing SearXNG API..."

# Performance test with timeout
start_time=$(date +%s.%N)
rag_result=$(timeout 10s curl -s "http://localhost:8080/searxng/search?q=test&format=json" 2>/dev/null | jq '.number_of_results' 2>/dev/null)
end_time=$(date +%s.%N)

if [ $? -eq 0 ] && [ ! -z "$rag_result" ]; then
    response_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
    if (( $(echo "$response_time < 2.0" | bc -l 2>/dev/null || echo 0) )); then
        print_status "SUCCESS" "RAG response: ${response_time}s, results: $rag_result"
    elif (( $(echo "$response_time < 5.0" | bc -l 2>/dev/null || echo 0) )); then
        print_status "WARNING" "RAG response: ${response_time}s, results: $rag_result (slow)"
    else
        print_status "ERROR" "RAG response: ${response_time}s, results: $rag_result (very slow)"
    fi
else
    print_status "ERROR" "RAG test failed (timeout or API error)"
fi
echo ""

# 5. Service status
echo "🏥 === SERVICE STATUS ==="
total_services=$(docker-compose ps 2>/dev/null | grep -c "erni-ki-" || echo "0")
healthy_services=$(docker-compose ps --format "table {{.Name}}\t{{.Health}}" 2>/dev/null | grep -c "healthy" || echo "0")
unhealthy_services=$(docker-compose ps --format "table {{.Name}}\t{{.Health}}" 2>/dev/null | grep -c "unhealthy" || echo "0")

if [ "$healthy_services" -ge 26 ]; then
    print_status "SUCCESS" "Healthy services: $healthy_services/$total_services"
elif [ "$healthy_services" -ge 20 ]; then
    print_status "WARNING" "Healthy services: $healthy_services/$total_services"
else
    print_status "ERROR" "Healthy services: $healthy_services/$total_services"
fi

if [ "$unhealthy_services" -gt 0 ]; then
    print_status "ERROR" "Unhealthy services: $unhealthy_services"
fi
echo ""

# 6. Overall system score
echo "📊 === OVERALL SYSTEM SCORE ==="
total_score=0

# Score calculation (max 100)
[ "$websocket_errors_30m" -eq 0 ] && total_score=$((total_score + 25))
[ "$websocket_errors_30m" -lt 50 ] && [ "$websocket_errors_30m" -gt 0 ] && total_score=$((total_score + 15))

[ "$searxng_errors_1h" -lt 100 ] && total_score=$((total_score + 20))
[ "$searxng_errors_1h" -lt 300 ] && [ "$searxng_errors_1h" -ge 100 ] && total_score=$((total_score + 10))

[ "$postgres_fatal_1h" -eq 0 ] && total_score=$((total_score + 15))

[ ! -z "$rag_result" ] && total_score=$((total_score + 20))

[ "$healthy_services" -ge 26 ] && total_score=$((total_score + 20))
[ "$healthy_services" -ge 20 ] && [ "$healthy_services" -lt 26 ] && total_score=$((total_score + 10))

# Final score
if [ "$total_score" -ge 80 ]; then
    print_status "SUCCESS" "Overall score: $total_score/100 (Excellent)"
elif [ "$total_score" -ge 60 ]; then
    print_status "WARNING" "Overall score: $total_score/100 (Good)"
else
    print_status "ERROR" "Overall score: $total_score/100 (Needs attention)"
fi
echo ""

# 7. Recommendations
echo "💡 === RECOMMENDATIONS ==="
if [ "$websocket_errors_30m" -gt 0 ]; then
    echo "   🔧 Consider disabling WebSocket in nginx temporarily"
fi

if [ "$searxng_errors_1h" -gt 200 ]; then
    echo "   🔧 Analyze and optimize SearXNG configuration"
fi

if [ "$postgres_fatal_1h" -gt 0 ]; then
    echo "   🔧 Clean up old PostgreSQL pg15 data"
fi

if [ "$healthy_services" -lt 25 ]; then
    echo "   🔧 Check status of unhealthy services"
fi

if [ "$total_score" -ge 80 ]; then
    echo "   ✅ System is stable, continue monitoring"
fi
echo ""

# 8. Save results
echo "💾 === SAVING RESULTS ==="
report_file=".config-backup/monitoring/post-websocket-report-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p .config-backup/monitoring

{
    echo "ERNI-KI Post-WebSocket Monitor Report"
    echo "Date: $(date)"
    echo "WebSocket errors (30m): $websocket_errors_30m"
    echo "SearXNG errors (1h): $searxng_errors_1h"
    echo "PostgreSQL FATAL (1h): $postgres_fatal_1h"
    echo "RAG result: $rag_result"
    echo "Healthy services: $healthy_services/$total_services"
    echo "Overall score: $total_score/100"
} > "$report_file"

print_status "INFO" "Report saved: $report_file"
echo ""

echo "🎯 === ANALYSIS COMPLETE ==="
echo "📈 Next run recommended in 1 hour"
echo "🔄 To automate, add to crontab:"
echo "   0 * * * * cd /path/to/erni-ki && ./scripts/post-websocket-monitor.sh"
echo ""

exit 0

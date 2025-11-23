#!/bin/bash
# Security monitoring for LiteLLM

LOG_FILE="/var/log/litellm-security.log"
ALERT_EMAIL="admin@example.com"

# Check suspicious requests
check_suspicious_requests() {
    echo "$(date): Check suspicious requests" >> $LOG_FILE

    # Log analysis nginx
    tail -1000 /var/log/nginx/access.log | grep -E "(sql|script|exec|union|select)" | while read line; do
        echo "ALERT: Suspicious request: $line" >> $LOG_FILE
        # Sending notification (if mail is configured)
        # echo "$line" | mail -s "Security Alert: Suspicious Request" $ALERT_EMAIL
    done
}

# Check failed authentications
check_auth_failures() {
    echo "$(date): Check failed authentications" >> $LOG_FILE

    # Log analysis LiteLLM
    docker-compose logs litellm | grep -i "unauthorized\|forbidden\|invalid.*key" | tail -50 | while read line; do
        echo "ALERT: Failed authentication: $line" >> $LOG_FILE
    done
}

# Check anomalous activity
check_anomalies() {
    echo "$(date): Check anomalous activity" >> $LOG_FILE

    # Flag IPs with unusually high request volume
    tail -1000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10 | while read count ip; do
        if [ "$count" -gt 100 ]; then
            echo "ALERT: High activity from IP $ip: $count requests" >> $LOG_FILE
        fi
    done
}

# Main function
main() {
    check_suspicious_requests
    check_auth_failures
    check_anomalies

    # Log rotation
    if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        touch "$LOG_FILE"
    fi
}

main

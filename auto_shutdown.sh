#!/bin/bash

# ==========================================
# Server Auto-Shutdown Script
# ==========================================
# This script pings a target device (e.g., a smart plug). 
# If the device becomes unreachable for a continuous duration
# (default 5 minutes), it safely shuts down the server.

CONFIG_FILE="/etc/server-auto-shutdown.conf"

# Check if configuration exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file $CONFIG_FILE not found."
    echo "Please run 'sudo ./install.sh' to configure and install the service."
    exit 1
fi

# Load Configuration
source "$CONFIG_FILE"

# Logging function for daily human-readable logs in user's home directory
log_event() {
    local message="$1"
    local log_dir="/home/$USERNAME/shutdown_logs"
    local log_file="$log_dir/shutdown_$(date +%Y-%m-%d).log"
    
    # Create directory if it doesn't exist and fix permissions
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir"
        chown "$USERNAME:$USERNAME" "$log_dir" 2>/dev/null || true
    fi
    
    local timestamp=$(date +"%H:%M:%S")
    echo "[$timestamp] $message" >> "$log_file"
    chown "$USERNAME:$USERNAME" "$log_file" 2>/dev/null || true
    
    # Also print to stdout for systemd journal
    echo "[$timestamp] $message"
}

send_telegram_notification() {
    local message="$1"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="${message}" \
            -d parse_mode="HTML" > /dev/null || true
    fi
}

cleanup_old_logs() {
    local log_dir="/home/$USERNAME/shutdown_logs"
    local retention=${LOG_RETENTION_DAYS:-30}
    if [ -d "$log_dir" ] && [ "$retention" -gt 0 ]; then
        find "$log_dir" -name "*.log" -type f -mtime +$retention -delete 2>/dev/null || true
    fi
}

fail_duration=0

log_event "Starting auto-shutdown monitor for $TARGET_IP (User: $USERNAME, Offline Timeout: ${FAIL_TIMEOUT}s, Shutdown Delay: ${SHUTDOWN_DELAY}m)..."

while true; do
    # Reload config dynamically to support Web UI changes
    source "$CONFIG_FILE"

    # Ping the target IP (1 count, 2-second timeout)
    if ping -c 1 -W 2 "$TARGET_IP" &> /dev/null; then
        # Ping successful - reset failure counter
        if [ "$fail_duration" -gt 0 ]; then
            log_event "Connection restored. Resetting failure counter."
            send_telegram_notification "✅ <b>Connection Restored</b>%0AThe smart plug ($TARGET_IP) is back online."
            fail_duration=0
            notified_offline=0
        fi
    else
        # Ping failed - increment failure counter
        fail_duration=$((fail_duration + PING_INTERVAL))
        log_event "No response from $TARGET_IP. Offline for $fail_duration/$FAIL_TIMEOUT seconds."
        
        if [ "$fail_duration" -gt 0 ] && [ "${notified_offline:-0}" -eq 0 ]; then
             send_telegram_notification "⚠️ <b>Device Offline</b>%0AThe smart plug ($TARGET_IP) is unreachable. Countdown started."
             notified_offline=1
        fi
        
        # Check if we exceeded the timeout
        if [ "$fail_duration" -ge "$FAIL_TIMEOUT" ]; then
            log_event "Target offline for >= timeout threshold. Initiating server shutdown in $SHUTDOWN_DELAY minutes..."
            send_telegram_notification "🚨 <b>SHUTDOWN INITIATED</b>%0ATarget offline for ${FAIL_TIMEOUT}s. Server shutting down in ${SHUTDOWN_DELAY} minutes."
            
            # Write final state indicating shutdown has been triggered
            echo "{\"fail_duration\": $fail_duration, \"timestamp\": \"$(date +%s)\", \"shutdown_triggered_at\": \"$(date +%s)\"}" > /tmp/auto_shutdown.state
            
            # Execute shutdown (requires root/sudo privileges)
            # You can test this script safely by changing 'shutdown -h' to 'echo'
            shutdown -h +$SHUTDOWN_DELAY "Auto-shutdown triggered due to smart plug timeout."
            
            exit 0
        fi
    fi
    
    # Run log cleanup once a day
    current_date=$(date +%Y-%m-%d)
    if [ "$current_date" != "$last_cleanup_date" ]; then
        cleanup_old_logs
        last_cleanup_date="$current_date"
    fi
    
    # Write current state to a temp file for the web interface
    echo "{\"fail_duration\": $fail_duration, \"timestamp\": \"$(date +%s)\"}" > /tmp/auto_shutdown.state
    chmod 644 /tmp/auto_shutdown.state 2>/dev/null || true
    
    sleep "$PING_INTERVAL"
done

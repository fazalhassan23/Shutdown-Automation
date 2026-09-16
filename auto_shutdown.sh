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
    # If there is no config, check if we are running interactively
    if [ -t 0 ]; then
        echo "=========================================="
        echo " Server Auto-Shutdown Initial Setup"
        echo "=========================================="
        
        if [ "$EUID" -ne 0 ]; then
            echo "Please run this script with sudo for initial setup."
            exit 1
        fi

        read -p "Enter your username (used for log file location): " USERNAME
        read -p "Enter the smart plug IP address (e.g. 192.168.1.100): " TARGET_IP
        read -p "Enter the ping interval in seconds (e.g. 30): " PING_INTERVAL
        read -p "How long should the smart plug be offline (in seconds) before triggering shutdown? (e.g. 300 for 5 mins): " FAIL_TIMEOUT
        read -p "Once triggered, how many minutes should the OS wait before turning off? (e.g. 0 for immediate): " SHUTDOWN_DELAY
        read -p "Telegram Bot Token (Optional, press Enter to skip): " TELEGRAM_BOT_TOKEN
        read -p "Telegram Chat ID (Optional, press Enter to skip): " TELEGRAM_CHAT_ID
        read -p "Log Retention Days (e.g. 30): " LOG_RETENTION_DAYS
        
        echo "USERNAME=\"$USERNAME\"" > "$CONFIG_FILE"
        echo "TARGET_IP=\"$TARGET_IP\"" >> "$CONFIG_FILE"
        echo "PING_INTERVAL=\"$PING_INTERVAL\"" >> "$CONFIG_FILE"
        echo "FAIL_TIMEOUT=\"$FAIL_TIMEOUT\"" >> "$CONFIG_FILE"
        echo "SHUTDOWN_DELAY=\"$SHUTDOWN_DELAY\"" >> "$CONFIG_FILE"
        echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$CONFIG_FILE"
        echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$CONFIG_FILE"
        echo "LOG_RETENTION_DAYS=\"${LOG_RETENTION_DAYS:-30}\"" >> "$CONFIG_FILE"
        
        echo ""
        echo "Configuration saved successfully to $CONFIG_FILE"
        echo "You can now start the systemd service!"
        exit 0
    else
        echo "Error: $CONFIG_FILE not found."
        echo "Please run the script interactively with sudo first to configure it."
        exit 1
    fi
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

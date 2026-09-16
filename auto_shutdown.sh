#!/bin/bash

# ==========================================
# Server Auto-Shutdown Script
# ==========================================
# This script pings a target device (e.g., a smart plug). 
# If the device becomes unreachable for a continuous duration
# (default 5 minutes), it safely shuts down the server.

# Configuration
TARGET_IP="192.168.1.100" # Replace with your smart plug's IP address
PING_INTERVAL=30          # Time between ping checks (in seconds)
FAIL_TIMEOUT=300          # Timeout limit before shutdown (in seconds) - 300s = 5 minutes

fail_duration=0

echo "Starting auto-shutdown monitor for $TARGET_IP..."

while true; do
    # Ping the target IP (1 count, 2-second timeout)
    if ping -c 1 -W 2 "$TARGET_IP" &> /dev/null; then
        # Ping successful - reset failure counter
        if [ "$fail_duration" -gt 0 ]; then
            echo "$(date): Connection restored. Resetting failure counter."
            fail_duration=0
        fi
    else
        # Ping failed - increment failure counter
        fail_duration=$((fail_duration + PING_INTERVAL))
        echo "$(date): No response from $TARGET_IP. Offline for $fail_duration/$FAIL_TIMEOUT seconds."
        
        # Check if we exceeded the timeout
        if [ "$fail_duration" -ge "$FAIL_TIMEOUT" ]; then
            echo "$(date): Target offline for >= 5 minutes. Initiating server shutdown..."
            
            # Execute shutdown (requires root/sudo privileges)
            # You can test this script safely by changing 'shutdown -h now' to 'echo "SHUTDOWN TRIGGERED"'
            shutdown -h now
            
            exit 0
        fi
    fi
    
    sleep "$PING_INTERVAL"
done

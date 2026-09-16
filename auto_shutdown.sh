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

        read -p "Enter your username: " USERNAME
        read -p "Enter the smart plug IP address (e.g. 192.168.1.100): " TARGET_IP
        read -p "Enter the ping interval in seconds (e.g. 30): " PING_INTERVAL
        read -p "Enter the failure timeout in seconds (e.g. 300 for 5 mins): " FAIL_TIMEOUT
        
        echo "USERNAME=\"$USERNAME\"" > "$CONFIG_FILE"
        echo "TARGET_IP=\"$TARGET_IP\"" >> "$CONFIG_FILE"
        echo "PING_INTERVAL=\"$PING_INTERVAL\"" >> "$CONFIG_FILE"
        echo "FAIL_TIMEOUT=\"$FAIL_TIMEOUT\"" >> "$CONFIG_FILE"
        
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

fail_duration=0

echo "Starting auto-shutdown monitor for $TARGET_IP (User: $USERNAME)..."

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

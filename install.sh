#!/bin/bash

echo "=========================================="
echo " Server Auto-Shutdown Installer"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo "Please run this installer with sudo."
    exit 1
fi

CONFIG_FILE="/etc/server-auto-shutdown.conf"
INSTALL_DIR="/opt/server-auto-shutdown"

# Prompt for Configuration
read -p "Enter your username (used for log file location): " USERNAME
read -p "Enter the smart plug IP address (e.g. 192.168.1.100): " TARGET_IP
read -p "Enter the ping interval in seconds (e.g. 30): " PING_INTERVAL
read -p "How long should the smart plug be offline (in seconds) before triggering shutdown? (e.g. 300 for 5 mins): " FAIL_TIMEOUT
read -p "Once triggered, how many minutes should the OS wait before turning off? (e.g. 0 for immediate): " SHUTDOWN_DELAY
read -p "Web Interface Port (e.g. 8080): " WEB_PORT
read -p "Telegram Bot Token (Optional, press Enter to skip): " TELEGRAM_BOT_TOKEN
read -p "Telegram Chat ID (Optional, press Enter to skip): " TELEGRAM_CHAT_ID
read -p "Log Retention Days (e.g. 30): " LOG_RETENTION_DAYS

# Write configuration
echo "Writing configuration to $CONFIG_FILE..."
echo "USERNAME=\"$USERNAME\"" > "$CONFIG_FILE"
echo "TARGET_IP=\"$TARGET_IP\"" >> "$CONFIG_FILE"
echo "PING_INTERVAL=\"$PING_INTERVAL\"" >> "$CONFIG_FILE"
echo "FAIL_TIMEOUT=\"$FAIL_TIMEOUT\"" >> "$CONFIG_FILE"
echo "SHUTDOWN_DELAY=\"$SHUTDOWN_DELAY\"" >> "$CONFIG_FILE"
echo "WEB_PORT=\"${WEB_PORT:-8080}\"" >> "$CONFIG_FILE"
echo "TELEGRAM_BOT_TOKEN=\"$TELEGRAM_BOT_TOKEN\"" >> "$CONFIG_FILE"
echo "TELEGRAM_CHAT_ID=\"$TELEGRAM_CHAT_ID\"" >> "$CONFIG_FILE"
echo "LOG_RETENTION_DAYS=\"${LOG_RETENTION_DAYS:-30}\"" >> "$CONFIG_FILE"

# Install files
echo "Installing files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp auto_shutdown.sh "$INSTALL_DIR/"
cp web_ui.py "$INSTALL_DIR/"
cp index.html "$INSTALL_DIR/"

chmod +x "$INSTALL_DIR/auto_shutdown.sh"
chmod +x "$INSTALL_DIR/web_ui.py"

# Setup Systemd Services
echo "Setting up systemd services..."
cp auto_shutdown.service /etc/systemd/system/
cp auto_shutdown_web.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable auto_shutdown.service
systemctl enable auto_shutdown_web.service

systemctl restart auto_shutdown.service
systemctl restart auto_shutdown_web.service

echo ""
echo "Installation complete!"
echo "Web interface is running at http://<server-ip>:${WEB_PORT:-8080}"

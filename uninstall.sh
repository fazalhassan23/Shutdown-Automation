#!/bin/bash

echo "=========================================="
echo " Server Auto-Shutdown Uninstaller"
echo "=========================================="

if [ "$EUID" -ne 0 ]; then
    echo "Please run this uninstaller with sudo."
    exit 1
fi

INSTALL_DIR="/opt/server-auto-shutdown"
CONFIG_FILE="/etc/server-auto-shutdown.conf"

echo "Stopping services..."
systemctl stop auto_shutdown.service 2>/dev/null || true
systemctl stop auto_shutdown_web.service 2>/dev/null || true

echo "Disabling services..."
systemctl disable auto_shutdown.service 2>/dev/null || true
systemctl disable auto_shutdown_web.service 2>/dev/null || true

echo "Removing systemd service files..."
rm -f /etc/systemd/system/auto_shutdown.service
rm -f /etc/systemd/system/auto_shutdown_web.service

echo "Reloading systemd..."
systemctl daemon-reload

echo "Removing installation directory..."
rm -rf "$INSTALL_DIR"

read -p "Do you want to remove the configuration file ($CONFIG_FILE)? (y/N): " REMOVE_CONFIG
if [[ "$REMOVE_CONFIG" =~ ^[Yy]$ ]]; then
    rm -f "$CONFIG_FILE"
    echo "Configuration removed."
fi

echo ""
echo "Uninstallation complete!"

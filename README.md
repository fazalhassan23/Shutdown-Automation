# Ubuntu Server Auto-Shutdown Monitor

This project contains a simple bash script that monitors a smart plug (or any IP address on your network). If the device stops responding to ping requests for a continuous period of 5 minutes, it assumes the power has been cut (or you've intentionally triggered the shutdown) and gracefully shuts down the Ubuntu server.

## Installation Instructions

Follow these steps to deploy this script on your headless Ubuntu server.

### 1. Copy the Script to Your Server
Move the script to a standard location like `/opt/`. You can use SCP or just create the file on your server.

```bash
sudo mkdir -p /opt/server-auto-shutdown
sudo cp auto_shutdown.sh /opt/server-auto-shutdown/
```

### 2. Configure the Target IP
Edit the script to point to your actual smart plug IP address.

```bash
sudo nano /opt/server-auto-shutdown/auto_shutdown.sh
```
Change the `TARGET_IP="192.168.1.100"` line to your smart plug's IP address. You can also adjust `FAIL_TIMEOUT` if you want a different delay.

### 3. Make the Script Executable
Give the script permission to run:
```bash
sudo chmod +x /opt/server-auto-shutdown/auto_shutdown.sh
```

### 4. Setup the Background Service (systemd)
To ensure the script runs automatically in the background even if your server reboots, install the provided systemd service.

Copy the service file to systemd:
```bash
sudo cp auto_shutdown.service /etc/systemd/system/
```

Reload the systemd daemon so it recognizes the new file:
```bash
sudo systemctl daemon-reload
```

Enable the service to start automatically on boot:
```bash
sudo systemctl enable auto_shutdown.service
```

Start the service now:
```bash
sudo systemctl start auto_shutdown.service
```

### 5. Check the Status / View Logs
You can verify the script is running and monitor its ping output by checking the service logs:

```bash
sudo systemctl status auto_shutdown.service
```
Or view the live streaming log output:
```bash
sudo journalctl -u auto_shutdown.service -f
```

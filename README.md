# Server Auto-Shutdown Monitor

> A lightweight, zero-dependency bash script to monitor local network devices (like a smart plug) and automatically trigger a graceful server shutdown if the device goes offline for a configured duration.

**Current Version**: `v1.0.0` | **License**: MIT | **Platform**: Ubuntu / Linux

---

## Table of Contents

1. [Overview & Philosophy](#1-overview--philosophy)
2. [Features](#2-features)
3. [Installation Instructions](#3-installation-instructions)
4. [Configuration](#4-configuration)
5. [Monitoring & Logs](#5-monitoring--logs)
6. [Changelog](#6-changelog)

---

## 1. Overview & Philosophy

Running a headless server often requires protection against unexpected power cuts, especially when a UPS is not available or cannot communicate directly with the server. By monitoring a simple network device (like a smart WiFi plug) that is connected to the same electrical circuit, this script can infer when the mains power has been cut. If the smart plug stops responding to pings, the script safely shuts down the server before the backup battery dies.

## 2. Features

- **Continuous Ping Monitoring:** Infinite background loop checking the target IP.
- **Graceful Timeout Logic:** Doesn't panic on a single missed ping. Waits for a continuous sequence of failures (default: 5 minutes).
- **Auto-Recovery:** If the device comes back online before the timeout, the failure counter resets automatically.
- **Background Daemon (systemd):** Runs completely hands-off via a native systemd service. Starts on boot and restarts on crash.
- **Built-in Logging:** All status checks and triggers are logged natively to the system journal.

---

## 3. Installation Instructions

Follow these steps to deploy this script on your headless Ubuntu server.

### Step 1: Copy the Script
Move the script to a standard location like `/opt/`. You can use SCP or just create the file on your server.

```bash
sudo mkdir -p /opt/server-auto-shutdown
sudo cp auto_shutdown.sh /opt/server-auto-shutdown/
sudo chmod +x /opt/server-auto-shutdown/auto_shutdown.sh
```

### Step 2: Setup the Background Service
To ensure the script runs automatically in the background even if your server reboots, install the provided `systemd` service.

```bash
sudo cp auto_shutdown.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable auto_shutdown.service
sudo systemctl start auto_shutdown.service
```

---

## 4. Configuration

The script now features an interactive setup. You **must** run it manually one time before starting the background service. This will generate a configuration file at `/etc/server-auto-shutdown.conf`.

Run the interactive setup:
```bash
sudo /opt/server-auto-shutdown/auto_shutdown.sh
```

You will be prompted to enter:
- **Username:** Your name/identifier (used for the log file location).
- **Smart Plug IP Address:** E.g., `192.168.1.100`.
- **Ping Interval:** Time between checks in seconds (e.g., `30`).
- **Failure Timeout:** Time in seconds the plug must be offline before triggering a shutdown (e.g., `300` for 5 minutes).
- **Shutdown Delay:** Once triggered, how many minutes the OS should wait before turning off (e.g., `0` for immediate).

If you ever need to change these settings, you can either delete `/etc/server-auto-shutdown.conf` and run the script again, or edit the file directly using `nano`.

---

## 5. Monitoring & Logs

You can verify the script is running and monitor its ping output by checking the service logs:

**Check Status:**
```bash
sudo systemctl status auto_shutdown.service
```

**View Live Logs:**
```bash
sudo journalctl -u auto_shutdown.service -f
```
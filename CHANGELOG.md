# Changelog

> All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-09-16

### Added
- **Telegram Notifications:** Get instantly alerted on Telegram when the smart plug goes offline and when a shutdown is triggered.
- **Manual Actions:** Trigger or cancel a shutdown directly from the web dashboard.
- **Test Ping:** Verify your target IP configuration directly from the dashboard.
- **Uptime History:** Visual 7-day chart showing offline events and shutdowns.
- **Log Retention Policy:** Auto-cleans logs older than 30 days (configurable) to save disk space.

## [1.0.0] - 2026-09-16

### Added
- **Beta Web Interface:** Added a lightweight, built-in Python web server (`web_ui.py`) and an HTML dashboard (`index.html`) running on port 8080 to view live server status, config, and daily logs. Includes dynamic configuration editing.
- **Daily Human-Readable Logging:** Script now automatically creates daily log files (e.g. `shutdown_YYYY-MM-DD.log`) inside `/home/$USERNAME/shutdown_logs/` for easy tracking.
- **Shutdown Delay Config:** Added an extra setup prompt to specify how long the OS should wait after triggering the shutdown (e.g. `shutdown -h +5`).
- **Interactive Setup:** The script now prompts the user for their username, smart plug IP, ping interval, and timeout limit on its first run, saving settings to `/etc/server-auto-shutdown.conf`.
- **Core Monitoring:** Initial release of the `auto_shutdown.sh` monitor script.
- **Configurable Settings:** Variables for target IP, ping interval, and timeout limit.
- **Daemon Integration:** Integrated `systemd` service file (`auto_shutdown.service`) for running as a headless daemon.
- **Auto-Recovery:** Logic to reset the failure counter if the target device reconnects within the timeout window.
- **Documentation:** Comprehensive `README.md` with full installation and usage instructions.

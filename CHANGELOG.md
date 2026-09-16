# Changelog

> All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-16

### Added
- **Interactive Setup:** The script now prompts the user for their username, smart plug IP, ping interval, and timeout limit on its first run, saving settings to `/etc/server-auto-shutdown.conf`.
- **Core Monitoring:** Initial release of the `auto_shutdown.sh` monitor script.
- **Configurable Settings:** Variables for target IP, ping interval, and timeout limit.
- **Daemon Integration:** Integrated `systemd` service file (`auto_shutdown.service`) for running as a headless daemon.
- **Auto-Recovery:** Logic to reset the failure counter if the target device reconnects within the timeout window.
- **Documentation:** Comprehensive `README.md` with full installation and usage instructions.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-16
### Added
- Initial release of the `auto_shutdown.sh` monitor script.
- Configurable target IP, ping interval, and timeout limit.
- Continuous background monitoring loop.
- Integrated `systemd` service file (`auto_shutdown.service`) for running as a headless daemon.
- Comprehensive `README.md` with full installation and usage instructions.
- Auto-recovery logic to reset the failure counter if the target device reconnects within the timeout window.

# Realme OTA Finder

Universal OTA firmware finder and downloader for **Realme**, **OPPO**, and **OnePlus** devices.

Uses [realme-ota](https://github.com/R0rt1z2/realme-ota) by R0rt1z2 as the backend.

## Features

- Search OTA updates by device model, region, and version
- Supports 20 regions (China, India, Europe, Russia, etc.)
- Download link extraction with direct firmware URLs
- Pre-configured device list (`devices.txt`) with popular Realme models
- Automatic CSV logging of found OTA links
- Interactive menu with region/version change without restart

## Quick Install

```bash
bash <(curl -sL https://raw.githubusercontent.com/mansur54321/realme_ota/main/install_ota_tool.sh)
```

After installation, restart your terminal and run:

```bash
ota
```

## Supported Platforms

| Platform | Package Manager |
|----------|----------------|
| Debian/Ubuntu | apt |
| Arch Linux | pacman |
| Fedora | dnf |
| Termux (Android) | pkg |
| Windows (Git Bash) | python.org |

## Usage

1. Select model prefix (`CPH` / `RMX` / Custom) or pick from the device list
2. Enter manifest code + OTA version (e.g. `44F` = Europe, Second update)
3. Get OTA info: firmware version, Android version, security patch, download URL

### OTA Version Codes

| Code | Version |
|------|---------|
| A | Launch version |
| C | First update |
| F | Second update |
| H | Third update |

### Region Examples

| Code | Region |
|------|--------|
| 97 | China |
| 1B | India |
| 44 | Europe |
| 37 | Russia |
| 51 | Turkey |
| 82 | Hong Kong |

## Files

- `ota_downloader.sh` — Main OTA finder script
- `install_ota_tool.sh` — One-click installer
- `devices.txt` — Pre-configured Realme device list

## Credits

- [R0rt1z2/realme-ota](https://github.com/R0rt1z2/realme-ota) — Python library for OTA API
- Stano36 & SeRViP — Original OTA finder concept

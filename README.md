# Bing Wallpaper for Linux

This is a simple script that downloads the Bing Wallpaper of the day and sets it as your desktop wallpaper on Linux. It also creates a cron job to update the wallpaper every hour.

- [Bing Wallpaper for Linux](#bing-wallpaper-for-linux)
  - [Supported Desktop Environments](#supported-desktop-environments)
  - [Installation](#installation)
  - [Uninstallation](#uninstallation)
  - [Disclaimer](#disclaimer)


## Supported Desktop Environments

- [![GNOME](https://img.shields.io/badge/GNOME-4B4C5D?style=flat&logo=gnome)](https://www.gnome.org/)

## Installation

To install, run the following command:

```bash
curl -s https://raw.githubusercontent.com/crixodia/bing-wall-for-linux/main/install.sh > bwfl_install.sh && \
sudo chmod +x bwfl_install.sh && \
sudo ./bwfl_install.sh
```

## Uninstallation

To uninstall, run the following command:

```bash
sudo ./bwfl_install.sh --uninstall
```

## Disclaimer

This script is provided as-is, without any warranty or support. Use it at your own risk. This script is not affiliated with Microsoft or Bing in any way.

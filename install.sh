#!/bin/bash
# Bing Wallpaper Installer for Linux (KDE, Xfce, Gnome)
# Author: @crixodia @l-g-t
set -e

REQUIRED_CMDS_COMMON="curl wget crontab"
REQUIRED_CMDS_KDE="plasma-apply-wallpaperimage"
REQUIRED_CMDS_XFCE="xfconf-query"
REQUIRED_CMDS_GNOME="gsettings"

# Detect package manager
detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        PKG_INSTALL="sudo apt-get install -y"
        PKG_UPDATE="sudo apt-get update"
        PKG_CHECK="dpkg -s"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf makecache"
        PKG_CHECK="rpm -q"
    elif command -v yum >/dev/null 2>&1; then
        PKG_INSTALL="sudo yum install -y"
        PKG_UPDATE="sudo yum makecache"
        PKG_CHECK="rpm -q"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_INSTALL="sudo pacman -S --needed --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
        PKG_CHECK="pacman -Qi"
    else
        echo "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

# Install a package if the corresponding command is missing
install_if_missing() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing missing package: $pkg"
        $PKG_INSTALL $pkg
    fi
}

# Desktop environment detection
detect_desktop_env() {
    local env
    env=$(echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" | tr '[:upper:]' '[:lower:]')
    if [[ "$env" == *kde* ]]; then
        echo "kde"
    elif [[ "$env" == *xfce* ]]; then
        echo "xfce"
    elif [[ "$env" == *gnome* ]]; then
        echo "gnome"
    else
        # Fallback: try to detect running processes
        if pgrep -x plasmashell >/dev/null; then
            echo "kde"
        elif pgrep -x xfce4-session >/dev/null; then
            echo "xfce"
        elif pgrep -x gnome-shell >/dev/null; then
            echo "gnome"
        else
            echo "unsupported"
        fi
    fi
}

# Ensure sudo
if ! sudo -v >/dev/null 2>&1; then
    echo "Error: This script needs sudo privileges."
    exit 1
fi

detect_pkg_mgr
$PKG_UPDATE

# Install common dependencies
for cmd in $REQUIRED_CMDS_COMMON; do
    install_if_missing "$cmd" "$cmd"
done

# Detect DE and install additional dependencies
DESKTOP_ENV=$(detect_desktop_env)
case "$DESKTOP_ENV" in
    kde)
        install_if_missing "plasma-apply-wallpaperimage" "plasma-workspace"
        ;;
    xfce)
        install_if_missing "xfconf-query" "xfconf"
        ;;
    gnome)
        install_if_missing "gsettings" "libglib2.0-bin"
        ;;
    *)
        echo "Unsupported or undetected desktop environment."
        exit 1
        ;;
esac

SCRIPT_PATH=/usr/local/bin/bing-wallpaper.sh

uninstall() {
    sudo rm -f "$SCRIPT_PATH"
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab - || true
    echo "Uninstalled bing-wallpaper and removed cron jobs."
    exit 0
}

if [[ "$1" == "uninstall" ]]; then
    uninstall
fi

# Write the wallpaper script
cat <<"EOF" | sudo tee $SCRIPT_PATH >/dev/null
#!/bin/bash
BING_WALL_URL="https://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt=en-US"
RESOLUTION="_1920x1080"
EXTENSION=".jpg"

get_pic_url() {
    local url
    url=$(curl -s "$BING_WALL_URL" | grep -oPm1 "(?<=<url>)[^<]+")
    echo "https://www.bing.com${url}${RESOLUTION}${EXTENSION}"
}

set_wallpaper() {
    local pic_url pic_path
    pic_url=$(get_pic_url)
    pic_path="/tmp/bing_wallpaper.jpg"
    if wget -q -O "$pic_path" "$pic_url"; then
        DESKTOP_ENV=$(echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}" | tr '[:upper:]' '[:lower:]')
        # Fallback detection as well
        if [[ -z "$DESKTOP_ENV" ]]; then
            if pgrep -x plasmashell >/dev/null; then
                DESKTOP_ENV="kde"
            elif pgrep -x xfce4-session >/dev/null; then
                DESKTOP_ENV="xfce"
            elif pgrep -x gnome-shell >/dev/null; then
                DESKTOP_ENV="gnome"
            fi
        fi

        if [[ "$DESKTOP_ENV" == *kde* ]]; then
            plasma-apply-wallpaperimage "$pic_path"
            exit 0
        elif [[ "$DESKTOP_ENV" == *xfce* ]]; then
            # Multi-monitor support (basic)
            for m in $(xfconf-query -c xfce4-desktop -l | grep last-image); do
                xfconf-query -c xfce4-desktop -p "$m" -s "$pic_path"
            done
            exit 0
        elif [[ "$DESKTOP_ENV" == *gnome* ]]; then
            gsettings set org.gnome.desktop.background picture-uri "file://$pic_path"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$pic_path" 2>/dev/null || true
            exit 0
        else
            echo "Unsupported desktop environment: $DESKTOP_ENV"
            exit 1
        fi
    else
        echo "Failed to download Bing wallpaper."
        exit 1
    fi
}

set_wallpaper
EOF

sudo chmod +x $SCRIPT_PATH

# Remove old cron jobs for this script
crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab - || true

# Add new cron jobs
(crontab -l 2>/dev/null; echo "0 * * * * $SCRIPT_PATH"; echo "@reboot $SCRIPT_PATH") | grep -v '^$' | sort | uniq | crontab -

# Run once
$SCRIPT_PATH

if [ $? -eq 0 ]; then
    echo "Bing wallpaper installed and set successfully!"
else
    echo "Error: something went wrong with setting wallpaper."
    exit 1
fi

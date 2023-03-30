#!/bin/bash
# Author: @crixodia
# Description: Bing Wallpaper for Gnome

if ! [ -x "$(command -v crontab)" ]; then
    echo 'Error: cron is not installed.' >&2
    exit 1
fi

# if the argument is "uninstall", remove the cron job and exit
if [ "$1" = "uninstall" ]; then
    echo "Removing cron job"
    crontab -l | grep -v '/usr/local/bin/bing-wallpaper.sh' | head -1 | crontab -
    sudo rm /usr/local/bin/bing-wallpaper.sh
    exit 0
fi

# Create the script file
cat >bing-wallpaper.sh <<EOF
#!/bin/bash

BING_WALL_URL="http://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt=en-US"
RESOLUTION="_1920x1080"
EXTENSION=".jpg"

PIC_URL=\$(curl -s \$BING_WALL_URL | grep -oPm1 "(?<=<url>)[^<]+")
PIC_URL="http://www.bing.com\${PIC_URL}\${RESOLUTION}\${EXTENSION}"

if wget -q --spider \$PIC_URL; then
    echo "Downloading \$PIC_URL"
    wget -q -O /tmp/bing_wallpaper.jpg \$PIC_URL
    gsettings set org.gnome.desktop.background picture-uri file:///tmp/bing_wallpaper.jpg
    gsettings set org.gnome.desktop.background picture-uri-dark file:///tmp/bing_wallpaper.jpg
    exit 0
else
    echo "Error: \$PIC_URL does not exist."
    exit 1
fi

EOF

# Move the script to /usr/local/bin
sudo mv bing-wallpaper.sh /usr/local/bin/bing-wallpaper.sh

# Make the script executable
sudo chmod +x /usr/local/bin/bing-wallpaper.sh

# Create a cron job to run the script every hour
jobstring="0 * * * * /usr/local/bin/bing-wallpaper.sh"

# Check if the job already exists
if crontab -l | grep -q "$jobstring"; then
    echo "Cron job already exists"
else
    echo "Creating cron job"
    (
        crontab -l 2>/dev/null
        echo "$jobstring"
    ) | crontab -
fi

# Run the script once to set the wallpaper and check for errors
/usr/local/bin/bing-wallpaper.sh

# Done
if [ $? -eq 0 ]; then
    echo "Done"
else
    echo "Error: something went wrong"
fi

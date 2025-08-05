#!/bin/bash
set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive

home_dir='/home/pi'

# Set up journald to use persistent storage
echo "Storage=persistent" >> /etc/systemd/journald.conf

# Package install
apt-get -y install \
    git \
    unclutter \
    x11-xserver-utils \
    screen \
    xdotool \
    htop \
    ntpstat \
    chromium-browser

mkdir -p $home_dir/.ssh
mv /tmp/packer/kiosk/pi-authorized_keys $home_dir/.ssh/authorized_keys
chown 1000:1000 $home_dir/.ssh/authorized_keys
chmod 600 $home_dir/.ssh/authorized_keys

cd $home_dir
mv /tmp/packer/kiosk/show-procs $home_dir/show-procs
chmod +x $home_dir/show-procs
echo 'export DISPLAY=:0' >> $home_dir/.bashrc

# Clone the kiosk repository into the image to allow fetching config at boot
git clone --branch "${KIOSK_BRANCH:-main}" https://github.com/roboticsoutreach/kiosk.git sb-kiosk

chown 1000:1000 -R $home_dir/sb-kiosk

# Allow git to be used in the repository as root
cat > /root/.gitconfig << EOF
[safe]
	directory = /home/pi/sb-kiosk
EOF

# Update the config at boot
mv /tmp/packer/kiosk/kiosk-update.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/kiosk-update.service
systemctl enable kiosk-update.service

# remove "Welcome to Raspberry Pi"
rm /etc/xdg/autostart/piwiz.desktop

# Disable screen blanking
mkdir -p /etc/X11/xorg.conf.d/
mv /tmp/packer/kiosk/10-blanking.conf /etc/X11/xorg.conf.d/10-blanking.conf
chmod 644 /etc/X11/xorg.conf.d/10-blanking.conf

# Remove undervoltage warnings
apt-get -y remove lxplug-ptbatt
cat >> /boot/config.txt << EOF
# Disable under-voltage warning
avoid_warnings=1
EOF

# Enable underscan compensation
cat >> /boot/config.txt << EOF
# Enable underscan compensation
disable_overscan=1
EOF

# disable password ssh login
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config

# set timezone
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

# setup default kiosk config, the url must differ from any set urls to trigger a refresh
cat > /home/pi/sb-kiosk.conf << EOF
kiosk_args="--kiosk --enable-kiosk-mode --enabled"
kiosk_url="file:///dev/null"
EOF

# setup systemd service to run the kiosk
mv /tmp/packer/kiosk/kiosk-browser.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/kiosk-browser.service
systemctl enable kiosk-browser.service

# add venue compbox to /etc/hosts
cat $home_dir/sb-kiosk/global_config.json| python3 -c '
import json,sys
data=json.load(sys.stdin)
print(data["compbox_ip"], data["venue_compbox"], " # srcomp-auto")
' >> /etc/hosts

# set default hostname
original_hostname=$(cat /etc/hostname)
echo kiosk > /etc/hostname
sed -i "s/$original_hostname\$/kiosk/i" /etc/hosts

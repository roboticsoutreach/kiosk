#!/bin/bash
set -eux -o pipefail

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exec sudo "$0" "$@"
fi

if [ ! -d /home/pi/sb-kiosk ]; then
    echo "sb-kiosk not found, exiting"
    exit 1
fi

cd /home/pi/sb-kiosk

for i in $(seq 1 45); do
    # try to git fetch
    git fetch && break
    sleep 1
done

# try to git pull
git pull || true

# get config for this device
our_mac=$(cat /sys/class/net/eth0/address)
./device-scripts/generate-device-config.py --device "$our_mac" --output /tmp/raw_config.env
# Sets new_hostname, new_kiosk_url, autossh_port, autossh_host, compbox_ip, compbox_host
source /tmp/raw_config.env

# update hostname & refresh dhcp hostname
old_hostname=$(cat /etc/hostname)
if [ "$old_hostname" != "$new_hostname" ]; then
    echo "$new_hostname" > /etc/hostname
    hostnamectl set-hostname $new_hostname
    sed -i "s/$old_hostname\$/$new_hostname/i" /etc/hosts
    systemctl restart dhcpcd
fi

# TODO set ntp server to venue/public compbox

# update venue compbox in /etc/hosts
prev_compbox=$(awk "/$compbox_host/{print \$1}" /etc/hosts)
if [ "$prev_compbox" != "$compbox_ip" ]; then
    sed -i "s/^.*# srcomp-auto/$compbox_ip $compbox_host  # srcomp-auto/" /etc/hosts
fi

# generate html page with mac address and local ip address
cat > /home/pi/mac.html << EOF
<!DOCTYPE html>
<html lang="en">
<meta charset="utf-8">
<title>$our_mac</title>
<style>
    h1 {
        font-size: 2em;  /* fallback value */
        font-size: 6vw;
    }
</style>
<body>
    <h1>$our_mac</h1>
    <h1>$(hostname)</h1>
    <h1>$(hostname -I)</h1>
</body>
EOF

# check if kiosk_url has changed
source /home/pi/sb-kiosk.conf
if [ "$kiosk_url" == "$new_kiosk_url" ]; then
    echo "kiosk_url unchanged"
else
    # calculate kiosk_args
    uname -m | grep -q armv7  # check if pi is newer than pi 2
    newer_pi=$?
    base_kiosk_args="--incognito --kiosk --enable-kiosk-mode --enabled"
    base_kiosk_opts="--no-sandbox --disable-smooth-scrolling --disable-java --disable-restore-session-state --disable-sync --disable-translate"
    low_power_kiosk_args="--disable-low-res-tiling --enable-low-end-device-mode --disable-composited-antialiasing --disk-cache-size=1 --media-cache-size=1"

    if $newer_pi; then
        new_kiosk_args="$base_kiosk_args $base_kiosk_opts"
    else
        new_kiosk_args="$base_kiosk_args $base_kiosk_opts $low_power_kiosk_args"
    fi

    if echo "$new_kiosk_url" | grep -q "youtube"; then
        # livestream options
        new_kiosk_args="--kiosk --no-user-gesture-required --start-fullscreen --autoplay-policy=no-user-gesture-required"
    fi

    # update kiosk url and args (write to /home/pi/sb-kiosk.conf)
    cat > /home/pi/sb-kiosk.conf << EOF
kiosk_args="$new_kiosk_args"
kiosk_url="$new_kiosk_url"
EOF
    # restart kiosk service
    if systemctl is-active --quiet kiosk-browser; then
        # avoid the deadlock if this service is waiting for kiosk-update to finish
        systemctl restart kiosk-browser
    fi
fi

source /etc/autossh.conf
# check if autossh_port or autossh_host has changed
if [ "$autossh_port" == "$remote_ssh_port" ] && [ "$autossh_host" == "$tunnel_host" ]; then
    echo "autossh config unchanged"
else
    # if autossh_port is 0 disable autossh
    if [ "$autossh_port" == "0" ]; then
        echo "autossh disabled"
        systemctl disable autossh
        systemctl stop autossh
    else
        # if autossh_host is not in known_hosts, get its host key
        if ! grep -q "$autossh_host" /home/autossh/.ssh/known_hosts; then
            ssh-keyscan "$autossh_host" >> /home/autossh/.ssh/known_hosts
        fi
        # If /boot/autossh.key exists, move it to /home/autossh/.ssh/autossh.key
        if [ -f /boot/autossh.key ]; then
            mkdir -p /home/autossh/.ssh
            mv /boot/autossh.key /home/autossh/.ssh/autossh.key
            chown autossh:autossh /home/autossh/.ssh/autossh.key
            chmod 600 /home/autossh/.ssh/autossh.key
        fi
        echo "autossh enabled"
        # update autossh config
        cat > /etc/autossh.conf << EOF
remote_ssh_port=$autossh_port
tunnel_host=$autossh_host
EOF

        # restart autossh service
        systemctl enable autossh
        systemctl restart autossh
    fi
fi

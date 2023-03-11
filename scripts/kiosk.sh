#!/bin/bash
set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive

puppet_dir='/etc/puppet'
home_dir='/home/pi'


# Package install
apt-get -y install \
    puppet \
    git \
    unclutter \
    python3-yaml \
    x11-xserver-utils \
    screen \
    xdotool \
    htop \
    ntpstat \
    chromium-browser

cd $home_dir
git clone --recursive https://github.com/PeterJCLaw/srcomp-kiosk

chown 1000:1000 -R $home_dir/srcomp-kiosk
rm -rf /etc/puppet
ln -s $home_dir/srcomp-kiosk/ $puppet_dir

# Allow git to be used in the repository as root
cat > /root/.gitconfig << EOF
[safe]
	directory = /home/pi/srcomp-kiosk
EOF

# Run puppet config at boot
mv /tmp/packer/kiosk/kiosk-puppet.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/kiosk-puppet.service
systemctl enable kiosk-puppet.service

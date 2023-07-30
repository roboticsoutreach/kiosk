#!/bin/bash
set -eux -o pipefail

# create autossh user
useradd -m -s /usr/sbin/nologin autossh

# create ssh key for autossh
mkdir -p /home/autossh/.ssh
chmod 700 /home/autossh/.ssh

# Create ssh key for tunnel user
/usr/bin/ssh-keygen -t ed25519 -f /home/autossh/.ssh/id_ed25519 -N ''

# TODO populate known_hosts with compbox host key

# install and config autossh
apt-get -y install autossh

mv /tmp/packer/kiosk/autossh.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/autossh.service

# make an initial config
cat > /etc/autossh.conf << EOF
remote_ssh_port=""
tunnel_host=""
EOF

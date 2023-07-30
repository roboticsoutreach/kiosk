#!/bin/bash
set -eux -o pipefail

# At runtime, autossh will need to run ssh-keyscan to get the remote host's
# public key and be given an ssh private key at /home/autossh/.ssh/autossh.key

# create autossh user
useradd -m -s /usr/sbin/nologin autossh

# create ssh key for autossh
mkdir -p /home/autossh/.ssh
chmod 700 /home/autossh/.ssh

# install and config autossh
apt-get -y install autossh

mv /tmp/packer/kiosk/autossh.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/autossh.service

# make an initial config
cat > /etc/autossh.conf << EOF
remote_ssh_port=""
tunnel_host=""
EOF

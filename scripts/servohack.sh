#!/bin/bash
set -eu -o pipefail

# copy servohack script onto pi
mv /tmp/packer/servohack/servohack.py /usr/bin/
chmod 655 /usr/bin/servohack.py

# servohack service
mv /tmp/packer/servohack/servohack.service /usr/lib/systemd/system/
chmod 644 /usr/lib/systemd/system/servohack.service
systemctl enable servohack.service

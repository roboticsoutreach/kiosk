#!/bin/bash
set -eu -o pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -y update

# Package install
apt-get -y install \
    nano \
    vim \
    htop \
    git \
    python3-pip

# Add line to config.txt
echo 'VIDEO_CAMERA = "1"' >> /boot/config.txt

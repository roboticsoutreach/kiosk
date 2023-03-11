#!/bin/bash
set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get -y update

# Package install
apt-get -y install \
    nano \
    vim \
    htop \
    git

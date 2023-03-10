#!/bin/bash
set -eu -o pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get -y clean

pip3 cache purge

#!/bin/bash
set -eux -o pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get -y clean

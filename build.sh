#!/bin/bash

GIT_VERSION="$(git describe --tags --always)"

rm -f kiosk-*.img.xz
rm -f kiosk-*.img

docker run --rm --privileged \
    -v /dev:/dev \
    -v ${PWD}/packer:/build \
    mkaczanowski/packer-builder-arm:latest \
    build \
    -var "GIT_VERSION=${GIT_VERSION}" \
    pi.json

if [ $? -ne 0 ]; then
    echo "Packer build failed"
    rm -f packer/kiosk-*.img
    exit 1
fi

mv packer/kiosk-*.img.xz ./

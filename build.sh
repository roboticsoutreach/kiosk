#!/bin/bash
if [ $1 == "fast" ]; then
    SKIP_COMPRESSION="true"
else
    SKIP_COMPRESSION="false"
fi

GIT_VERSION="$(git describe --tags --always)"

rm -f kiosk-*.img.xz
rm -f kiosk-*.img

docker run --rm --privileged \
    -v /dev:/dev \
    -v ${PWD}/packer:/build \
    mkaczanowski/packer-builder-arm:latest \
    build \
    -var "GIT_VERSION=${GIT_VERSION}" \
    -var "SKIP_COMPRESSION=${SKIP_COMPRESSION}" \
    pi.json

if [ $? -ne 0 ]; then
    echo "Packer build failed"
    rm -f packer/kiosk-*.img
    exit 1
fi

mv packer/kiosk-*.img* ./

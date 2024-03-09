#!/bin/bash
if [ $1 == "fast" ]; then
    SKIP_COMPRESSION="true"
else
    SKIP_COMPRESSION="false"
fi

GIT_VERSION="$(git describe --tags --always)"
# default KIOSK_BRANCH to to current branch
KIOSK_BRANCH="${KIOSK_BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

rm -f kiosk-*.img.xz
rm -f kiosk-*.img

docker run --rm --privileged \
    -v /dev:/dev \
    -v ${PWD}/packer:/build \
    mkaczanowski/packer-builder-arm:latest \
    build \
    -var "GIT_VERSION=${GIT_VERSION}" \
    -var "SKIP_COMPRESSION=${SKIP_COMPRESSION}" \
    -var "KIOSK_BRANCH=${KIOSK_BRANCH:-main}" \
    pi.json

if [ $? -ne 0 ]; then
    echo "Packer build failed"
    rm -f packer/kiosk-*.img
    exit 1
fi

mv packer/kiosk-*.img* ./

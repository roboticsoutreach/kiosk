#!/bin/bash

SROBO_NAME="Student Robotics OS"
SROBO_VERSION="$(git describe --tags)"

docker run --rm --privileged \
    -v /dev:/dev \
    -v ${PWD}:/build \
    mkaczanowski/packer-builder-arm:latest \
    build \
    -var "SROBO_NAME=${SROBO_NAME}" \
    -var "SROBO_VERSION=${SROBO_VERSION}" \
    pi.json

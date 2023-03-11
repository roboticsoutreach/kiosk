#!/bin/bash
set -eu -o pipefail

user="pi"
password="$(openssl passwd -crypt -salt robot robot)"

userdel -r pi

# Create robot user
useradd \
    --create-home \
    -s /bin/bash \
    -u 1000 \
    -G sudo,video,dialout \
    -p "$password" \
    $user

mv /etc/sudoers.d/010_pi-nopasswd /etc/sudoers.d/011_$user-nopasswd
sed -i "s/pi/$user/g" /etc/sudoers.d/011_$user-nopasswd

echo "$user:$password" > /boot/userconf

# Enable ssh
touch /boot/ssh

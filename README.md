# sb-kiosk

Packer scripts to build a kiosk image that can be used with srcomp

## Requirements

- Docker
- This repository cloned

## Usage

Simply run the `./build.sh` script. Packer will download all needed files and save the output image to `output.img.xz`.

To use autossh, you will need to set up the ssh key to be used by generating a keypair and adding the public key to the autossh user on the server that the tunnel will connect to. The private key should be named `autossh.key` and placed in `/boot/autossh.key` on the image. The `/boot` directory is a FAT32 partition on the image, so it can be mounted on most computers to add the key.

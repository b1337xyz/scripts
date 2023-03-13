#!/usr/bin/env bash

set -xeu

[ "$(id -u)" -ne 0 ] && { echo 'Permission denied!!!'; exit 1; }
command -v parted || { printf 'Install parted!\n'; exit 1; }

end() {
    qemu-nbd -d /dev/nbd0 || echo "qemu-nbd failed"
    umount mnt || echo "umount failed"
    sleep 1
    rmmod nbd || echo "rmmod failed"
}
trap end EXIT INT HUP TERM 

modprobe nbd max_part=16
qemu-nbd -c /dev/nbd0 arch.img
partprobe /dev/nbd0
[ -d mnt ] || mkdir -v mnt
mount /dev/nbd0p1 mnt
echo "Press ENTER to unmount"
read -r

#!/bin/sh

set -e

ISO=$(echo ./*.iso)
IMG=arch.img
SIZE=10G
[ -f "$ISO" ] || exit 1
[ -f "$IMG" ] && rm -i "$IMG";
[ -f "$IMG" ] || qemu-img create -f qcow2 "$IMG" "$SIZE"

qemu-system-x86_64 -cdrom "$ISO" -boot order=d      \
    -drive file=$IMG,format=qcow2,if=virtio -m 3G   \
    -device intel-hda -enable-kvm -cpu host -smp cores=2

#!/bin/sh

set -e

ISO=$1
IMG=debian.img
[ -f "$ISO" ] || exit 1
[ -f "$IMG" ] && rm -i "$IMG";
[ -f "$IMG" ] || qemu-img create -f qcow2 "$IMG" 15G

qemu-system-x86_64 -cdrom "$ISO" -boot order=d      \
    -drive file=$IMG,format=qcow2,if=virtio -m 3G   \
    -device intel-hda -device hda-duplex            \
    -enable-kvm -machine q35 -device intel-iommu    \
    -cpu host -smp cores=2,threads=1

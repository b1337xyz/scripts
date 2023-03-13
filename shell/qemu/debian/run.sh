#!/bin/sh
# -nic user,hostfwd=tcp::8722-:8000

IMG=debian.img

qemu-system-x86_64 -drive file=$IMG,format=qcow2,if=virtio -m 4G \
    -device intel-hda -device hda-duplex \
    -enable-kvm -machine q35 -device intel-iommu \
    -cpu host -smp cores=2,threads=1

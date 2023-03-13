#!/bin/sh

IMG=arch.img

# -device usb-host,bus=ehci.0,vendorid=0x054c,productid=0x0268 \
#    -device qemu-xhci,id=xhci \
#    -device usb-host,hostdevice=/dev/bus/usb/001/007 \

qemu-system-x86_64 -drive file=$IMG,format=qcow2,if=virtio -m 3G \
    -device intel-hda -device hda-duplex \
    -enable-kvm -cpu host -smp cores=2

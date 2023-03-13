#!/usr/bin/env bash

set -xe

timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
[ -e /dev/vda1 ] || fdisk /dev/vda
mkfs.btrfs -f /dev/vda1 && mount /dev/vda1 /mnt

pacstrap -K /mnt base linux linux-firmware dhcpcd doas
genfstab -U /mnt >> /mnt/etc/fstab

cat << EOF > /mnt/etc/modprobe.d/local.conf
blacklist uvcvideo
blacklist pcspkr
blacklist btusb
blacklist bluetooth
EOF

arch-chroot /mnt /bin/bash -c '
useradd -m -U -s /bin/bash user
echo "permit nopass user" >> /etc/doas.conf
systemctl enable dhcpcd 
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
echo "archvm" >> /etc/hostname
passwd
pacman -Syu grub intel-ucode vim qemu-guest-agent bash-completion --noconfirm
systemctl enable qemu-guest-agent.service
grub-install --target=i386-pc /dev/vda
grub-mkconfig -o /boot/grub/grub.cfg'

umount /mnt
poweroff

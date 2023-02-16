#!/usr/bin/env bash
# https://wiki.archlinux.org/title/Udisks#udevadm_monitor
set -e
umask 0077 # rwx-----

MP=/mnt/"$USER"
[ -w "$MP" ] || { printf "Can't write to '%s': Permission denied\n" "$MP";  exit 1; }

lock=/tmp/.automount.lock
[ -f "$lock" ] && exit 0
:>"$lock"
trap 'rm "$lock" 2>/dev/null' EXIT INT HUP

get_devname() {
    udevadm info -p /sys/"$1" | awk -v FS== '/DEVNAME/{print $2}'
}

stdbuf -oL -- udevadm monitor --udev -s block | while read -r -- _ _ event devpath _
do
    if [ "$event" = add ]; then
        devname=$(get_devname "$devpath")
        [[ "$devname" =~ [0-9]$ ]] || continue
        grep -q "^$devname" /proc/mounts && continue
        read -r label uuid < <(lsblk -o LABEL,UUID "$devname" | tail -1)
        label=${label:-$uuid}
        [ -z "$label" ] && continue
        mp="${MP}/$label"
        [ -d "$mp" ] || mkdir -vp "$mp"
        sudo mount "$devname" "$mp" -o noatime
        ln -vsf "$mp" ~/mnt
        notify-send -i drive-harddisk "$label mounted" "$mp" 2>/dev/null || true
        # udisksctl mount --no-user-interaction -b "$devname" -o noatime
        sleep 1
    fi
done

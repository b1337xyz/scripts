#!/usr/bin/env bash
# https://wiki.archlinux.org/title/Udisks#udevadm_monitor
set -e
umask 0077 # rwx-----

MP=/mnt/"$USER"
[ -w "$MP" ] || { printf "Can't write to '%s': Permission denied\n" "$MP";  exit 1; }

lock=/tmp/.automount.lock
[ -f "$lock" ] && exit 0
:>"$lock"
trap 'rm "$lock" 2>/dev/null' EXIT

get_devname() {
    udevadm info -p /sys/"$1" | awk -v FS== '/DEVNAME/{print $2}'
}

get_label() {
    lsblk -o LABEL,UUID "$1" | tail -1
}

stdbuf -oL -- udevadm monitor --udev -s block | while read -r -- _ _ event devpath _; do
    if [ "$event" = add ]; then
        devname=$(get_devname "$devpath")
        [[ "$devname" =~ [0-9]$ ]] || continue
        grep -q "^$devname" /proc/mounts && continue

        read -r label uuid < <(get_label "$devname")
        label=${label:-$uuid}
        [ -z "$label" ] && continue
        [[ "$label" =~ ^ARCH ]] && continue 

        mp="${MP}/$label"
        [ -d "$mp" ] || mkdir -vp "$mp"
        sudo mount "$devname" "$mp" -o noatime

        notify-send -i drive-harddisk "$label mounted" "$mp" 2>/dev/null || true
        # udisksctl mount --no-user-interaction -b "$devname" -o noatime
    fi
done

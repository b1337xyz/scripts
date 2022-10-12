#!/usr/bin/env bash
# https://wiki.archlinux.org/title/Udisks#udevadm_monitor

lock=/tmp/automount.lock
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
        label=$(lsblk -o LABEL "$devname" | tail -1)
        [ -z "$label" ] && continue
        mp=/mnt/anon/"$label"
        [ -d "$mp" ] || mkdir -v "$mp"
        sudo mount "$devname" "$mp" -o noatime,user
        notify-send -i drive-harddisk "$label mounted" "$mp"
        # udisksctl mount --no-user-interaction -b "$devname" -o noatime
    fi
done

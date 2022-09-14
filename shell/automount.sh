#!/usr/bin/env bash
# https://wiki.archlinux.org/title/Udisks#udevadm_monitor

get_devname() {
    udevadm info -p /sys/"$1" | awk -v FS== '/DEVNAME/{print $2}'
}

stdbuf -oL -- udevadm monitor --udev -s block | while read -r -- _ _ event devpath _; do
    if [ "$event" = add ]; then
        devname=$(get_devname "$devpath")
        [[ "$devname" =~ [0-9]$ ]] || continue
        # udisksctl mount --no-user-interaction -b "$devname" -o noatime
        LABEL=$(lsblk -o LABEL "$devname" | tail -1)
        [ -z "$LABEL" ] && continue
        notify-send -i drive-harddisk "$LABEL plugged"
        mp=/mnt/anon/"$LABEL"
        [ -d "$mp" ] || mkdir -v "$mp"
        if ! grep -q "^$devname" /proc/mounts;then
            printf 'mount %s %s\n' "$devname" "$mp"
            sudo mount "$devname" "$mp" -o noatime,user
            notify-send -i drive-harddisk "$devname mounted at $mp"
        fi
    fi
done #&> ~/.automount.log

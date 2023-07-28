#!/bin/sh

Mount() {
    [ -d "$2" ] || mkdir -vp "$2"
    rclone mount --daemon   \
        --allow-other       \
        --read-only         \
        --no-checksum       \
        --no-modtime        \
        "$@"
}

Mount a1337xyz: ~/mnt/gdrive0
Mount blind:    ~/mnt/gdrive1
Mount wick:     ~/mnt/gdrive2

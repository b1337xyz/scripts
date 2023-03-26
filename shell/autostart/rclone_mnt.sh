#!/bin/sh

main() {
    [ -d "$2" ] || mkdir -vp "$2"
    rclone mount --daemon   \
        --allow-other       \
        --read-only         \
        --no-checksum       \
        --no-modtime        \
        "$@"
}

main gdrive:storage ~/mnt/storage
main a1337xyz: ~/mnt/gdrive0
main blind:    ~/mnt/gdrive1
main wick:     ~/mnt/gdrive2

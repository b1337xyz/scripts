#!/bin/sh
set -e

grep -oP '(?<=: )/.*(?= fuse\.rclone)' /proc/mounts | while read -r i
do
    fusermount -u "$i"
    echo "$i unmounted"
done

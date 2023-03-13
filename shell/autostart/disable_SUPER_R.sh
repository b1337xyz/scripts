#!/usr/bin/env bash

set -eo pipefail

stdbuf -oL -- udevadm monitor --udev -s input | while read -r -- _ _ event devpath _
do
    if [ "$event" = "add" ] && [[ "$devpath" =~ input[0-9]+$ ]]; then
        if udevadm info -p /sys/"$devpath" | grep -qi keyboard; then
            xmodmap -e "keycode 134 =" # disable SUPER_R
        fi
    fi
done

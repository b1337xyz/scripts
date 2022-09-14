#!/usr/bin/env bash

set -eo pipefail

find ~/.local/src/scripts -mindepth 2 -type f | while read -r old
do
    new=${old/local\/src\//}
    [ -e "$new" ] || continue
    if ! diff --color=always "$old" "$new";then
        printf "\nupdate '%s' (y/n)? " "${old##*/}"
        read ask </dev/tty
        [ "${ask,,}" = "y" ] && cp -v "$new" "$old"
        echo -e "\r-------------------------------"
    fi
done

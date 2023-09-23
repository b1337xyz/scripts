#!/usr/bin/env bash

dunstrc=~/.config/dunst/dunstrc

cp -v "$dunstrc" "${dunstrc}.bkp"
find /usr/share/icons/Haiku -iregex '.*\.\(jpg\|png\|svg\)' -printf '%h\n' |
    sort -u | tr \\n ':' | sed 's/.$//g; s/\//\\\\\//g' |
    xargs -rI{} sed -i 's/icon_path = .*/icon_path = {}/' "$dunstrc"

. reload.sh

read -r -p 'Undo? (y/n) ' ask
if [ "$ask" = "y" ];then
    cp -v "${dunstrc}.bkp" "$dunstrc"
    . reload.sh
fi

echo

#!/usr/bin/env bash

dunstrc=~/.config/dunst/dunstrc
homeicons=/home/anon/.local/share/icons
sysicons=/usr/share/icons

[ -f "$dunstrc" ] || exit 1

theme=$(find "$homeicons" "$sysicons" -mindepth 1 -maxdepth 1 -type d | sort -u | fzf)
[ -d "$theme" ] || { printf '"%s" not found\n' "$icons"; exit 1; }

size=$(find "$theme" -path '*[0-9]*' -type d -printf '%f\n' | sort -u | fzf)
[ -z "$size" ] && exit 2

string="$(find "$theme" -path "*/${size}/*" -type f -printf '%h\n' | sort -u | while read -r i;do
    printf ':%s' "${i//\//\\/}" ;done | cut -c2-)"
[ -z "$string" ] && exit 1

cp -v "$dunstrc" "${dunstrc%/*}/dunstrc.bkp" || exit 1
sed -i 's/icon_path\s=\s.*/icon_path = '"$string"'/' "$dunstrc"
grep 'icon_path' "$dunstrc"

./reload.sh

read -r -p 'Undo? (y/n) ' ask
if [ "$ask" = "y" ];then
    cp -v "${dunstrc%/*}/dunstrc.bkp" "$dunstrc"

    ./reload.sh
fi
